module GoSnowflake
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
end
