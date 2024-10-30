module GoSnowflake
  class SignalHandler
    def initialize
      @handlers = {}
      @active = true
    end

    def on_signal(signal_name, description: nil, &block)
      signal = signal_name.to_s.upcase

      @handlers[signal] = {
        block: block,
        description: description,
        created_at: Time.now
      }

      Signal.trap(signal) do
        if @active && @handlers[signal]
          begin
            @handlers[signal][:block].call
          rescue => e
            puts "Error in signal handler for #{signal}: #{e.message}"
            puts e.backtrace
          end
        end
      end
    end

    # Temporarily disable all handlers
    def disable
      @active = false
    end

    # Re-enable all handlers
    def enable
      @active = true
    end

    def remove_handler(signal_name)
      signal = signal_name.to_s.upcase
      @handlers.delete(signal)
      Signal.trap(signal, "DEFAULT")
    end
  end
end
