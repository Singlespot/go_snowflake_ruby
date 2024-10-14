require 'mkmf'

# Ensure we have Go installed
unless find_executable('go')
  abort 'Go is not installed. Please install Go and make sure it is in your PATH.'
end

# Build the Go shared library
go_input = 'go_snowflake/go_snowflake.go'
go_output = 'go_snowflake/go_snowflake.so'

unless system("go mod init #{go_input}")
  abort 'Failed to init Go mod.'
end

unless system("go mod tidy")
  abort 'Failed to tidy Go mod.'
end

# Build command to compile the Go code as a shared library
go_build_cmd = "go build -o #{go_output} -buildmode=c-shared #{go_input}"

# Run the build command
unless system(go_build_cmd)
  abort 'Failed to build Go shared library.'
end

# Create the Makefile to link the shared library
create_makefile("go_snowflake/go_snowflake/#{go_output}")

File.open('Makefile', 'a') do |f|
  f.puts <<-EOF

clean:
\t@rm -f *.o *.so *.bundle *.mod *.sum
\t@rm -f Makefile
  EOF
end
