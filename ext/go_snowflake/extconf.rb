require 'mkmf'
require 'fileutils'

# Ensure we have Go installed
unless find_executable('go')
  abort 'Go is not installed. Please install Go and make sure it is in your PATH.'
end

Dir.chdir(__dir__)

# Build the Go shared library
mod_name = "go_snowflake"
go_input = 'go_snowflake.go arguments_binding.go'
go_output = 'go_snowflake.so'

FileUtils.rm_f('go.mod')
FileUtils.rm_f('go.sum')

unless system("go mod init #{mod_name}")
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
create_makefile("#{go_output}")

File.open('Makefile', 'a') do |f|
  f.puts <<-EOF

clean:
\t@rm -f *.o *.so *.bundle *.mod *.sum
\t@rm -f Makefile
  EOF
end
