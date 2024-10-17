module ArgumentBuilder
  def self.build(args)
    args_pointers = args.map do |arg|
      if arg.is_a?(Integer)
        FFI::MemoryPointer.from_string(arg.to_s)
      else
        FFI::MemoryPointer.from_string(arg)
      end
    end
    args_array = FFI::MemoryPointer.new(:pointer, args.length)
    args_pointers.each_with_index { |ptr, i| args_array[i].put_pointer(0, ptr) }

    arg_types_array = FFI::MemoryPointer.new(:int, args.length)
    args.each_with_index do |arg, i|
      if arg.is_a?(Integer)
        arg_types_array.put_int32(i * 4, GoSnowflake.enum_type(:arg_type)[:int])
      else
        arg_types_array.put_int32(i * 4, GoSnowflake.enum_type(:arg_type)[:string])
      end
    end
    [args_pointers, args_array, arg_types_array]
  end
end
