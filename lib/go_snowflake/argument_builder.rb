module ArgumentBuilder
  # Define the ArgType enum with frozen hash
  ARG_TYPES = {
    string: 0,
    int: 1
  }.freeze

  def self.build(args)
    arg_pointers = args.map { |arg| FFI::MemoryPointer.from_string(arg.to_s) }
    args_array = FFI::MemoryPointer.new(:pointer, args.length)
    args_array.write_array_of_pointer(arg_pointers)

    arg_types = args.map { |arg| arg.is_a?(Integer) ? ARG_TYPES[:int] : ARG_TYPES[:string] }
    arg_types_array = FFI::MemoryPointer.new(:int, args.length)
    arg_types_array.write_array_of_int(arg_types)

    [arg_pointers, args_array, arg_types_array]
  end
end
