module GoSnowflake
  extend FFI::Library

  # Load the shared library with better error handling
  begin
    ffi_lib File.expand_path('../../../ext/go_snowflake/go_snowflake.so', __FILE__)
  rescue LoadError => e
    raise LoadError, "Failed to load Go Snowflake library: #{e.message}"
  end

  # Constants
  QUERY_ID_LENGTH = 40
  DEFAULT_BUFFER_SIZE = 1024

  typedef :pointer, :string_array
  typedef :pointer, :int_array

  # Bind the Go functions
  attach_function :InitConnection, [:string], :string
  attach_function :Ping, [], :string
  attach_function :CloseConnection, [], :void
  attach_function :Fetch, [
    :string, # query
    :pointer, # out_columns
    :pointer, # out_column_types
    :pointer, # out_cols
    :pointer, # args
    :pointer, # arg_types
    :int      # args size
  ], :string
  attach_function :FetchNextRow, [
    :pointer, # out_columns
    :pointer, # out_values
    :int      # row number
  ], :string
  attach_function :CloseCursor, [], :void
  attach_function :Execute, [
    :pointer, # query
    :pointer, # lastId
    :pointer, # rowsNb
    :pointer, # args
    :pointer, # argTypes
    :int      # args size
  ], :string
  attach_function :AsyncExecute, [
    :pointer, # query
    :pointer, # queryId
    :pointer, # args
    :pointer, # argTypes
    :int      # args size
  ], :string
  attach_function :free, [:pointer], :void

  class Error < StandardError; end
  class ConnectionError < Error; end
  class QueryError < Error; end


  # Base class for common functionality
  class BaseExecutor
    protected

    def handle_error(error, context)
      return if error.nil?
      raise QueryError, "#{context}: #{error}"
    end

    def ensure_connected
      raise ConnectionError, "Not connected to database" unless connected?
    end

    def connected?
      error = GoSnowflake.Ping
      error.nil?
    end

    def cleanup_resources(resources)
      Array(resources).each do |resource|
        case resource
        when Array
          resource.each { |r| r&.free }
        when FFI::Pointer, FFI::MemoryPointer
          resource&.free
        end
      end
    end
  end


  class Executor < BaseExecutor
    attr_reader :last_id, :rows_affected

    def initialize(query, *args)
      @query = query
      @args = args
    end

    def execute
      ensure_connected
      execute_query
      self
    end

    private

    def execute_query
      args_pointers, args_array, arg_types_array = ArgumentBuilder.build(@args)
      last_id = FFI::MemoryPointer.new(:int)
      rows_nb = FFI::MemoryPointer.new(:int)

      begin
        error = GoSnowflake.Execute(@query, last_id, rows_nb, args_array, arg_types_array, @args.length)
        handle_error(error, "Execute failed")

        @last_id = last_id.read_int
        @rows_affected = rows_nb.read_int

        [@last_id, @rows_affected]
      ensure
        cleanup_resources([args_pointers, args_array, arg_types_array, last_id, rows_nb])
      end
    end
  end

  class Fetcher < BaseExecutor
    attr_reader :columns, :column_types, :num_cols

    def initialize(query, *args)
      @query = query
      @args = args
    end

    def select(&block)
      ensure_connected
      raise ArgumentError, "Block is required" unless block_given?

      fetch_results(&block)
      self
    end

    private

    def fetch_results
      initialize_buffers
      fetch_metadata
      fetch_rows { |row| yield row }
    ensure
      cleanup_resources
      GoSnowflake.CloseCursor
    end

    def initialize_buffers
      @out_columns = FFI::MemoryPointer.new(:pointer)
      @out_column_types = FFI::MemoryPointer.new(:pointer)
      @out_cols = FFI::MemoryPointer.new(:int)
      @out_values = FFI::MemoryPointer.new(:pointer)
      @is_over_ptr = FFI::MemoryPointer.new(:uchar)
      @args_pointers, @args_array, @arg_types_array = ArgumentBuilder.build(@args)
    end

    def fetch_metadata
      error = GoSnowflake.Fetch(
        @query, @out_columns, @out_column_types, @out_cols,
        @args_array, @arg_types_array, @args.length
      )
      handle_error(error, "Fetch failed")

      @num_cols = @out_cols.read_int
      load_columns_and_types
    end

    def load_columns_and_types
      columns_ptr = @out_columns.read_pointer
      @columns = columns_ptr.read_array_of_pointer(@num_cols).map(&:read_string)

      column_types_ptr = @out_column_types.read_pointer
      @column_types = column_types_ptr.read_array_of_pointer(@num_cols).map(&:read_string)
    end

    def fetch_rows
      @is_over_ptr.put_uchar(0, 1)

      loop do
        error = GoSnowflake.FetchNextRow(@is_over_ptr, @out_values, @num_cols)
        handle_error(error, "FetchNextRow failed")

        break if @is_over_ptr.read_uchar == 1

        row_ptr = @out_values.read_pointer
        row = row_ptr.read_array_of_pointer(@num_cols).map(&:read_string)
        yield row
      end
    end

    def cleanup_resources
      resources = [
        @args_pointers,
        @args_array,
        @arg_types_array,
        @out_columns,
        @out_column_types,
        @out_values,
        @is_over_ptr
      ]
      super(resources)
    end
  end

  class AsyncExecutor < BaseExecutor
    attr_reader :query_id

    def initialize(query, *args)
      @query = query
      @args = args
    end

    def execute
      ensure_connected
      execute_async_query
      self
    end

    private

    def execute_async_query
      args_pointers, args_array, arg_types_array = ArgumentBuilder.build(@args)
      query_id = FFI::MemoryPointer.new(:char, QUERY_ID_LENGTH)

      begin
        error = GoSnowflake.AsyncExecute(@query, query_id, args_array, arg_types_array, @args.length)
        handle_error(error, "AsyncExecute failed")

        @query_id = query_id.read_string
      ensure
        cleanup_resources([args_pointers, args_array, arg_types_array, query_id])
      end
    end
  end
end
