# lib/debug_print.rb

require 'set'

require_relative "debug_print/colors"
require_relative "debug_print/debug_print_binding_enhancements"

module DebugPrint
  @ignore_list = Set.new

  class << self
    attr_accessor :ignore_list

    # Automatically enable colors and set up methods on Binding when the gem is required
    def setup
      DebugPrint::Colors.enabled = true
      Binding.prepend(DebugPrintBindingEnhancements)
      Kernel.module_eval do
        alias_method :d?, :binding
      end
    end

    def convert_binding_to_binding_info(
      b,
      include_lets: false,
      include_ivars: false,
      include_cvars: false,
      include_globals: false
    )
      file = b.eval("__FILE__") rescue nil
      line = b.eval("__LINE__") rescue nil
      location = [file, line].compact.join(":")

      receiver = b.receiver

      # Local variables
      locals = b.local_variables.map do |var|
        [var, safe_local_variable_get(b, var)]
      end.to_h.reject { |k, _| ignore_list.include?(k) }

      # Instance variables
      instances = {}
      if include_ivars && safe_to_inspect?(receiver)
        receiver.instance_variables.each do |var|
          next if ignore_list.include?(var)
          instances[var] = safe_instance_variable_get(receiver, var)
        end
      end

      # Let variables
      lets = {}
      if include_lets && receiver.instance_variable_defined?(:@__memoized)
        outer_memoized = receiver.instance_variable_get(:@__memoized)
        if outer_memoized.respond_to?(:instance_variable_get)
          memoized = outer_memoized.instance_variable_get(:@memoized)
          if memoized.is_a?(Hash)
            memoized.each do |key, val|
              lets[key.to_sym] = val unless ignore_list.include?(key.to_sym)
            end
          end
        end
      end

      # Class variables
      cvars = {}
      if include_cvars
        target = receiver.is_a?(Class) || receiver.is_a?(Module) ? receiver : receiver.class
        if target.respond_to?(:class_variables)
          target.class_variables.each do |var|
            next if ignore_list.include?(var)
            cvars[var] = target.class_variable_get(var) rescue "[Error accessing #{var}]"
          end
        end
      end
      # Globals
      globals = {}
      if include_globals
        (global_variables - [:$~, :$_, :$&, :$`, :$']).each do |var|
          next if ignore_list.include?(var)
          globals[var] = safe_global_variable_get(var)
        end
      end

      {
        source: location,
        object: receiver,
        library: false, # or !!(location =~ /gems/) if needed
        method_and_args: {
          object_name: "",
          args: ""
        },
        test_name: nil,
        variables: {
          locals:    locals,
          instances: instances,
          lets:      lets,
          globals:   globals,
          class_vars: cvars
        },
        exception: "NoException",
        capture_event: "manual_debug"
      }
    end


    # Formats a binding_info hash for output
    def format_binding_info(info)
      out = []
      out << DebugPrint::Colors.green("From:") + " #{info[:source]}"

      unless info[:variables][:locals].empty?
        out << DebugPrint::Colors.green("\nLocals:")
        out << describe_hash(info[:variables][:locals])
      end

      unless info[:variables][:instances].empty?
        out << DebugPrint::Colors.green("\nInstances:")
        out << describe_hash(info[:variables][:instances])
      end

      unless info[:variables][:class_vars].empty?
        out << DebugPrint::Colors.green("\nClass Vars:")
        out << describe_hash(info[:variables][:class_vars])
      end

      unless info[:variables][:lets].empty?
        out << DebugPrint::Colors.green("\nLet Variables:")
        out << describe_hash(info[:variables][:lets])
      end

      unless info[:variables][:globals].empty?
        out << DebugPrint::Colors.green("\nGlobals:")
        out << describe_hash(info[:variables][:globals])
      end

      out.join("\n")
    end

    private

    def describe_hash(hash)
      hash.map do |k, v|
        "  #{DebugPrint::Colors.purple(k)}: #{format_value(v)}"
      end.join("\n")
    end

    def format_value(value)
      if awesome_print_available? && DebugPrint::Colors.enabled
        value.ai
      else
        safe_inspect(value)
      end
    end

    def safe_inspect(obj)
      str = obj.inspect
      str.size > 300 ? (str[0..300] + "... (truncated)") : str
    rescue
      "[un-inspectable]"
    end

    def safe_to_inspect?(obj)
      obj.class
      true
    rescue NoMethodError
      false
    end

    def safe_local_variable_get(binding_context, var_name)
      binding_context.local_variable_get(var_name)
    rescue => e
      "[Error accessing local variable #{var_name}: #{e.message}]"
    end

    def safe_instance_variable_get(obj, var_name)
      obj.instance_variable_get(var_name)
    rescue => e
      "[Error accessing instance variable #{var_name}: #{e.message}]"
    end

    def safe_global_variable_get(var_name)
      eval("#{var_name}")
    rescue => e
      "[Error accessing global variable #{var_name}: #{e.message}]"
    end

    def awesome_print_available?
      return @awesome_print_available unless @awesome_print_available.nil?
      @awesome_print_available = defined?(AwesomePrint)
    end
  end
end

# Automatically set up DebugPrint on require
DebugPrint.setup
