# frozen_string_literal: true

require "simplecov"
SimpleCov.start

require 'dotenv/load'

require "debug"
$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "go_snowflake_ruby"

require "minitest/autorun"
