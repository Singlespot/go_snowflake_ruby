module GoSnowflake
  extend FFI::Library

  ffi_lib File.expand_path('../../../ext/go_snowflake/go_snowflake.so', __FILE__)

  # Define the ArgType enum
  enum :arg_type, [:string, :int]

  # Bind the Go functions
  attach_function :InitConnection, [:string], :string
  attach_function :Ping, [], :string
  attach_function :CloseConnection, [], :void
  attach_function :Fetch, [
    :string, # query
    :pointer, # out_columns
    :pointer, # out_values
    :pointer, # out_column_types
    :pointer, # out_rows
    :pointer, # out_cols
    :pointer, # args
    :pointer, # arg_types
    :int      # args size
  ], :string
  attach_function :Execute, [
    :pointer, # query
    :pointer, # lastId
    :pointer, # rowsNb
    :pointer, # args
    :pointer, # argTypes
    :int      # args size
  ], :string
  attach_function :free, [:pointer], :void

  class Error < StandardError; end

  class Executor
    def initialize(query, *args)
      @query = query
      @args = args
    end

    def execute
      args_pointers, args_array, arg_types_array = ArgumentBuilder.build(@args)

      last_id = FFI::MemoryPointer.new(:int)
      rows_nb = FFI::MemoryPointer.new(:int)

      begin
        error = GoSnowflake.Execute(@query, last_id, rows_nb, args_array, arg_types_array, @args.length)
        if !error.nil?
          err = "Execute Error: #{error}"
          raise err
        end
        @last_id = last_id.read_int
        @rows_nb = rows_nb.read_int
      ensure
        args_pointers.each(&:free)
        args_array.free
        arg_types_array.free
        last_id.free
        rows_nb.free
      end
    end
  end

  class Fetcher
    def initialize(query, *args)
      @query = query
      @args = args
    end

    def run
      # Allocate memory for query results
      out_columns = FFI::MemoryPointer.new(:pointer)
      out_values = FFI::MemoryPointer.new(:pointer)
      out_column_types = FFI::MemoryPointer.new(:pointer)
      out_rows = FFI::MemoryPointer.new(:int)
      out_cols = FFI::MemoryPointer.new(:int)

      args_pointers, args_array, arg_types_array = ArgumentBuilder.build(@args)
      begin
        # Execute query
        error = GoSnowflake::Fetch(@query, out_columns, out_values, out_column_types, out_rows, out_cols, args_array, arg_types_array, @args.length)
        if !error.nil?
          err = "Query Error: #{error}"
          raise err
        end

        # Read results
        @num_rows = out_rows.read_int
        @num_cols = out_cols.read_int

        # Read column names
        columns_ptr = out_columns.read_pointer
        @columns = columns_ptr.read_array_of_pointer(@num_cols).map(&:read_string)

        # Read column types
        column_types_ptr = out_column_types.read_pointer
        @column_types = column_types_ptr.read_array_of_pointer(@num_cols).map(&:read_string)

        # Read row data
        rows_ptr = out_values.read_pointer
        @rows = []
        @num_rows.times do |i|
          row_ptr = rows_ptr.get_pointer(i * FFI::Pointer.size)
          row = row_ptr.read_array_of_pointer(@num_cols).map(&:read_string)
          @rows << row
        end
      ensure
        args_pointers.each(&:free)
        args_array.free
        arg_types_array.free
        out_columns.free
        out_column_types.free
        out_values.free
      end
    end
  end
end
