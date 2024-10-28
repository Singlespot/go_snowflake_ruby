module GoSnowflake
  class Executor < BaseExecutor
    attr_reader :last_id, :rows_affected

    def initialize(query, *args)
      @query = query
      @args = args
      @signal_handler = SignalHandler.new
    end

    def execute
      ensure_connected
      execute_query
      self
    end

    private

    def setup_signal_handlers
      @signal_handler.on_signal(:INT) do
        puts "Received interrupt signal"
        perform_cancel
      end

      @signal_handler.on_signal(:TERM) do
        puts "Received termination signal"
        perform_cancel
      end
    end

    def cleanup_signal_handlers
      @signal_handler.remove_handler(:INT)
      @signal_handler.remove_handler(:TERM)
    end

    def perform_cancel
      GoSnowflake.CancelExecution
    end

    def execute_query
      args_pointers, args_array, arg_types_array = ArgumentBuilder.build(@args)
      last_id = FFI::MemoryPointer.new(:int)
      rows_nb = FFI::MemoryPointer.new(:int)

      setup_signal_handlers

      begin
        error = GoSnowflake.Execute(@query, last_id, rows_nb, args_array, arg_types_array, @args.length)
        handle_error(error, "Execute failed")

        @last_id = last_id.read_int
        @rows_affected = rows_nb.read_int

        [@last_id, @rows_affected]
      ensure
        cleanup_signal_handlers
        cleanup_resources([args_pointers, args_array, arg_types_array, last_id, rows_nb])
      end
    end
  end
end
