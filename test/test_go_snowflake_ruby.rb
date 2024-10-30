# frozen_string_literal: true

require "test_helper"

class TestGoSnowflakeRuby < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::GoSnowflakeRuby::VERSION
  end

  def test_connection_check
    db = GoSnowflakeRuby::Database.connect(ENV["CONNECTION_STRING"])
    assert db.connected?
    db.disconnect
    refute db.connected?
  end

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

  def test_execute
    db = GoSnowflakeRuby::Database.connect(ENV["CONNECTION_STRING"])
    e = db.execute("INSERT INTO TEST_TABLE (NAME, AGE, CREATED_AT, UPDATED_AT) VALUES ('Bob', 30, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)")
    assert_equal e.rows_affected, 1
    rows = []
    db.select("SELECT * FROM TEST_TABLE") do |row|
      rows << row
    end
    assert_equal rows.length, 2
    db.execute("DELETE FROM TEST_TABLE WHERE NAME = 'Bob'")
    assert_equal e.rows_affected, 1
    rows = []
    db.select("SELECT * FROM TEST_TABLE") do |row|
      rows << row
    end
    assert_equal rows.length, 1
    db.disconnect
  end

  def test_async_execute
    db = GoSnowflakeRuby::Database.connect(ENV["CONNECTION_STRING"])
    e = db.async_execute("SELECT COUNT(*) FROM TABLE(GENERATOR(TIMELIMIT => 1))")
    assert_match /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/, e.query_id
    db.disconnect
  end

end
