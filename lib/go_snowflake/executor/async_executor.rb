module GoSnowflake
  class AsyncExecutor < BaseExecutor
    attr_reader :query_id

    def initialize(query, *args)
      super(query, *args)
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
