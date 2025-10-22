# frozen_string_literal: true

require "ffi"
require "json"
require_relative "go_snowflake_ruby/version"
require_relative "go_snowflake/go_snowflake"
require_relative "go_snowflake/signal_handler"
require_relative "go_snowflake/executor/base_executor"
require_relative "go_snowflake/executor/executor"
require_relative "go_snowflake/executor/fetcher"
require_relative "go_snowflake/executor/async_executor"
require_relative "go_snowflake/argument_builder"

# Module for Snowflake database interaction via Go bindings
module GoSnowflakeRuby
  # Custom error class for GoSnowflakeRuby specific errors
  class Error < StandardError; end
  class ConnectionError < Error; end

  # Main database connection and interaction class
  class Database
    # @return [String, nil] Last error message if any occurred
    attr_reader :error

    class << self
      # Establishes a new connection to Snowflake database
      # @param connection_string [String] Connection string with database credentials
      # @return [Database] New database connection instance
      # @example
      #   db = Database.connect("user:pass@account/database")
      def connect(connection_string)
        conn = new
        error = GoSnowflake.InitConnection(connection_string)
        if error
          conn.set_error(error)
          raise ConnectionError, "Failed to connect: #{error}"
        end
        conn
      end
    end

    # Closes the current database connection
    # @return [void]
    def disconnect
      GoSnowflake.CloseConnection
    end

    # Checks if the database connection is active
    # @return [Boolean] true if connected, false otherwise
    def connected?
      set_error(GoSnowflake.Ping)
      !@error
    end

    # Executes a SELECT query and yields each result row
    # @param query [String] SQL query to execute
    # @param args [Array] Query parameters
    # @yield [row] Yields each row of the result set
    # @yield [row, fetcher] Yields row and fetcher if block takes two parameters
    # @yieldparam row [Hash] Result row as column-value pairs
    # @yieldparam fetcher [GoSnowflake::Fetcher] Query result fetcher
    # @return [void]
    def select(query, *args, &block)
      fetcher = GoSnowflake::Fetcher.new(query, *args)
      fetcher.select do |row|
        if block.parameters.length == 1
          block.call(row)
        else
          block.call(row, fetcher)
        end
      end
    end

    # Executes a query synchronously
    # @param query [String] SQL query to execute
    # @param args [Array] Query parameters
    # @return [GoSnowflake::Executor] Query executor instance
    def execute(query, *args)
      executor = GoSnowflake::Executor.new(query, *args)
      executor.execute
      executor
    end

    # Executes a query asynchronously
    # @param query [String] SQL query to execute
    # @param args [Array] Query parameters
    # @return [GoSnowflake::AsyncExecutor] Asynchronous query executor instance
    def async_execute(query, *args)
      executor = GoSnowflake::AsyncExecutor.new(query, *args)
      executor.execute
      executor
    end

    # Sets the last error message
    # @param error [String] Error message
    # @return [void]
    def set_error(error)
      @error = error
    end
  end
end
