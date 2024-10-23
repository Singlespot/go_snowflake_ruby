# frozen_string_literal: true
require 'ffi'
require_relative "go_snowflake_ruby/version"
require_relative "go_snowflake/go_snowflake"
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

    def select(query, *args)
      fetcher = GoSnowflake::Fetcher.new(query, *args)
      fetcher.select do |row|
        yield row
      end
    end

    def execute(query, *args)
      executor = GoSnowflake::Executor.new(query, *args)
      executor.execute
      executor
    end

    private
    def set_error(error)
      @error = error
    end
  end
end
