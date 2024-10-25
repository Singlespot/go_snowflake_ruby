module GoSnowflake
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
end
