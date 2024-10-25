module GoSnowflake
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
      @column_types = column_types_ptr.read_array_of_pointer(@num_cols).map(&:read_string).map { |type| type_json_parse(type) }
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

    private
    def type_json_parse(type)
      JSON.parse(type)
      rescue JSON::ParserError
        type
    end
  end
end
