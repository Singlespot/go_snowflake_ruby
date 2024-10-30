# frozen_string_literal: true

require 'dotenv/load'

require "simplecov"
SimpleCov.start


require "debug"
$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "go_snowflake_ruby"

require "minitest/autorun"

connection_string = ENV["CONNECTION_STRING"]
raise "CONNECTION_STRING is not set" unless connection_string

table_sql = <<~SQL
  create or replace TABLE TEST_TABLE (
  	ID NUMBER(38,0) NOT NULL autoincrement start 1 increment 1 order,
  	NAME VARCHAR(16777216),
  	AGE NUMBER(38,0),
  	CREATED_AT TIMESTAMP_NTZ(9) NOT NULL,
  	UPDATED_AT TIMESTAMP_NTZ(9) NOT NULL,
  	primary key (ID)
  );
SQL

insert_sql = <<~SQL
  INSERT INTO TEST_TABLE (NAME, AGE, CREATED_AT, UPDATED_AT)
  VALUES ('Alice', 20, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
SQL
@connection = GoSnowflakeRuby::Database.connect(connection_string)

@connection.execute(table_sql)
@connection.execute(insert_sql)
@connection.disconnect

class Minitest::Test
  # def setup
  # end

  # def teardown
  # end
end
