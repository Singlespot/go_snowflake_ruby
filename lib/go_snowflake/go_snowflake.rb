require 'ffi'

module GoSnowflake
  extend FFI::Library

  ffi_lib File.expand_path('../../../ext/go_snowflake/go_snowflake.so', __FILE__)

  # Define the ArgType enum
  enum :arg_type, [:string, :int]

  # Bind the Go functions
  attach_function :InitConnection, [:string], :string
  attach_function :Ping, [], :void
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
    :int # args size
  ], :pointer
  attach_function :free, [:pointer], :void

  class Error < StandardError; end

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

      args_pointers = @args.map do |arg|
        if arg.is_a?(Integer)
          FFI::MemoryPointer.from_string(arg.to_s)
        else
          FFI::MemoryPointer.from_string(arg)
        end
      end
      args_array = FFI::MemoryPointer.new(:pointer, @args.length)
      args_pointers.each_with_index { |ptr, i| args_array[i].put_pointer(0, ptr) }

      arg_types_array = FFI::MemoryPointer.new(:int, @args.length)
      @args.each_with_index do |arg, i|
        if arg.is_a?(Integer)
          arg_types_array[i].put_int32(i * 4, GoSnowflake.enum_type(:arg_type)[:int])
        else
          arg_types_array[i].put_int32(i * 4, GoSnowflake.enum_type(:arg_type)[:string])
        end
      end

      # Execute query
      error = GoSnowflake::Fetch(@query, out_columns, out_values, out_column_types, out_rows, out_cols, args_array, arg_types_array, @args.length)
      if !error.null?
        err = "Query Error: #{error.read_string}"
        GoSnowflake.free(error)
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
      # Free memory
      GoSnowflake.free(out_columns.read_pointer)
      GoSnowflake.free(out_column_types.read_pointer)
      GoSnowflake.free(out_values.read_pointer)
    end
  end
end
