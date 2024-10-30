# frozen_string_literal: true
require 'ffi'
require 'json'
require_relative "go_snowflake_ruby/version"
require_relative "go_snowflake/go_snowflake"
require_relative "go_snowflake/signal_handler"
require_relative "go_snowflake/executor/base_executor"
require_relative "go_snowflake/executor/executor"
require_relative "go_snowflake/executor/fetcher"
require_relative "go_snowflake/executor/async_executor"
require_relative "go_snowflake/argument_builder"


module GoSnowflakeRuby
  class Error < StandardError; end

  class Database
    attr_reader :error
    class << self
      def connect(connection_string)
        conn = new
        error = GoSnowflake.InitConnection(connection_string)
        conn.set_error(error) if error
        conn
      end
    end

    def disconnect
      GoSnowflake.CloseConnection
    end

    def connected?
      set_error(GoSnowflake.Ping)
      !@error
    end

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

    def execute(query, *args)
      executor = GoSnowflake::Executor.new(query, *args)
      executor.execute
      executor
    end

    def async_execute(query, *args)
      executor = GoSnowflake::AsyncExecutor.new(query, *args)
      executor.execute
      executor
    end

    private
    def set_error(error)
      @error = error
    end
  end
end
