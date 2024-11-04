# frozen_string_literal: true

require_relative "test_helper"
require_relative "../lib/go_snowflake_ruby"

class TestGoSnowflakeRubyGem < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::GoSnowflakeRuby::VERSION
  end
end

class TestGoSnowflakeRubyConnection < Minitest::Test
  def test_select
    db = GoSnowflakeRuby::Database.connect(ENV["CONNECTION_STRING"])
    db.select("SELECT * FROM TEST_TABLE") do |row, fetcher|
      assert_includes fetcher.columns, "NAME"
      assert_includes fetcher.columns, "AGE"
      assert_includes row, "Alice"
      assert_includes row, "20"
    end
    db.disconnect
  end
end

class TestGoSnowflakeRubyDatabase < Minitest::Test
  def setup
    @connection = GoSnowflakeRuby::Database.connect(ENV["CONNECTION_STRING"])
    setup_test_table
  end

  def teardown
    @connection.disconnect if @connection&.connected?
  end

  def test_invalid_connection
    assert_raises do
      GoSnowflakeRuby::Database.connect("invalid_connection_string")
    end
  end

  def test_connection_state
    assert @connection.connected?
    @connection.disconnect
    refute @connection.connected?
  end

  def test_invalid_query
    assert_raises do
      @connection.execute("INVALID SQL")
    end
  end

  def test_select
    @connection.select("SELECT * FROM TEST_TABLE") do |row, fetcher|
      assert_includes fetcher.columns, "NAME"
      assert_includes fetcher.columns, "AGE"
      assert_includes row, "Alice"
      assert_includes row, "20"
    end
  end

  def test_execute
    e = @connection.execute("INSERT INTO TEST_TABLE (NAME, AGE, CREATED_AT, UPDATED_AT) VALUES ('Bob', 30, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)")
    assert_equal e.rows_affected, 1
    rows = []
    @connection.select("SELECT * FROM TEST_TABLE") do |row|
      rows << row
    end
    assert_equal rows.length, 2
    @connection.execute("DELETE FROM TEST_TABLE WHERE NAME = 'Bob'")
    assert_equal e.rows_affected, 1
    rows = []
    @connection.select("SELECT * FROM TEST_TABLE") do |row|
      rows << row
    end
    assert_equal rows.length, 1
  end

  def test_async_execute
    e = @connection.async_execute("SELECT COUNT(*) FROM TABLE(GENERATOR(TIMELIMIT => 1))")
    assert_match /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/, e.query_id
  end

  private

  def setup_test_table
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

    @connection.execute(table_sql)
    @connection.execute(insert_sql)
  end
end
