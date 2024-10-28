module GoSnowflake
  extend FFI::Library

  # Load the shared library with better error handling
  begin
    ffi_lib File.expand_path('../../../ext/go_snowflake/go_snowflake.so', __FILE__)
  rescue LoadError => e
    raise LoadError, "Failed to load Go Snowflake library: #{e.message}"
  end

  # Constants
  QUERY_ID_LENGTH = 40
  DEFAULT_BUFFER_SIZE = 1024

  typedef :pointer, :string_array
  typedef :pointer, :int_array

  # Bind the Go functions
  attach_function :InitConnection, [:string], :string
  attach_function :Ping, [], :string
  attach_function :CloseConnection, [], :void
  attach_function :Fetch, [
    :string, # query
    :pointer, # out_columns
    :pointer, # out_column_types
    :pointer, # out_cols
    :pointer, # args
    :pointer, # arg_types
    :int      # args size
  ], :string
  attach_function :FetchNextRow, [
    :pointer, # out_columns
    :pointer, # out_values
    :int      # row number
  ], :string
  attach_function :CloseCursor, [], :void
  attach_function :Execute, [
    :pointer, # query
    :pointer, # lastId
    :pointer, # rowsNb
    :pointer, # args
    :pointer, # argTypes
    :int      # args size
  ], :string
  attach_function :CancelExecution, [], :void
  attach_function :AsyncExecute, [
    :pointer, # query
    :pointer, # queryId
    :pointer, # args
    :pointer, # argTypes
    :int      # args size
  ], :string
  attach_function :free, [:pointer], :void

  class Error < StandardError; end
  class ConnectionError < Error; end
  class QueryError < Error; end
end
