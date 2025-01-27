# lib/wut/wut_binding_enhancements.rb
module WutBindingEnhancements

  # l: locals
  def l
    print_debug_output(:l)
  end

  # i: instance variables
  def i
    print_debug_output(:i)
  end

  # c: class variables
  def c
    print_debug_output(:c)
  end

  # tf: the full set of variables
  def tf
    print_debug_output(:tf)
  end

  # tf?: the full set of variables, with globals
  def tf?
    print_debug_output(:tf?)
  end

  private

  # Print the debug output to the console
  def print_debug_output(level)
    puts debug_output(level)
  end

  def debug_output(level)
    binding_info = Wut.convert_binding_to_binding_info(
      self,
      include_locals:   (level == :l || level == :tf || level == :tf?) ,
      include_lets:   (level == :l || level == :tf || level == :tf?) ,
      include_instances:  (level == :i  || level == :tf || level == :tf?),
      include_classes:  (level == :c || level == :tf || level == :tf?),
      include_globals: (level == :g || level == :tf?)
    )
    Wut.format_binding_info(binding_info)
  end
end
