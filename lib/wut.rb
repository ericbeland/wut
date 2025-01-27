# lib/wut.rb

require 'set'

require_relative "wut/colors"
require_relative "wut/wut_binding_enhancements"


RSPEC_SKIP_LIST = [
  :@__inspect_output,
  :@__memoized,
  :@assertion_delegator,
  :@assertion_instance,
  :@assertions,
  :@connection_subscriber,
  :@example,
  :@fixture_cache,
  :@fixture_cache_key,
  :@fixture_connection_pools,
  :@fixture_connections,
  :@integration_session,
  :@legacy_saved_pool_configs,
  :@loaded_fixtures,
  :@matcher_definitions,
  :@saved_pool_configs
].freeze

RAILS_SKIP_LIST = [
  :@association_cache,
  :@_routes,
  :@app,
  :@arel_table,
  :@assertion_instance,
  :@association_cache,
  :@attributes,
  :@connection,
  :@destroyed,
  :@destroyed_by_association,
  :@encrypted_attributes,
  :@find_by_statement_cache,
  :@generated_relation_method,
  :@integration_session,
  :@marked_for_destruction,
  :@mutations_before_last_save,
  :@mutations_from_database,
  :@new_record,
  :@predicate_builder,
  :@previously_new_record,
  :@primary_key,
  :@readonly,
  :@relation_delegate_cache,
  :@response,
  :@response_klass,
  :@routes,
  :@transaction_manager,
  :@strict_loading,
  :@strict_loading_mode,
  :@@configurations
].freeze

# prompt is a console item
RUBY_SKIP_LIST = [:@prompt]

MINITEST_SKIP_LIST = [:@NAME, :@failures, :@time].freeze

DEFAULT_SKIP_LIST = (RUBY_SKIP_LIST + RAILS_SKIP_LIST + RSPEC_SKIP_LIST + MINITEST_SKIP_LIST)


# Wut is a debugging utility module that enhances bindings, formats debugging information,
# and provides convenient access to various scoped variables.
module Wut
  # A set of variable names to ignore during variable inspection
  # @return [Set]
  @ignore_list = DEFAULT_SKIP_LIST

  class << self
    # @!attribute [rw] ignore_list
    #   @return [Set] The list of variables to ignore during inspection.
    attr_accessor :ignore_list

    # Sets up Wut by enabling colors, enhancing Binding, and defining the `w` shortcut.
    # @return [void]
    def setup
      Wut::Colors.enabled = true
      Binding.prepend(WutBindingEnhancements)
      Kernel.module_eval do
        alias_method :w, :binding
      end
    end

    def ignored?(meth)
      meth.to_s =~ /^(@_|_)/ || @ignore_list.include?(meth)
    end

    # Converts a Binding object to a structured hash of debugging information.
    # @param b [Binding] The binding to inspect.
    # @param include_lets [Boolean] Whether to include let variables.
    # @param include_instances [Boolean] Whether to include instance variables.
    # @param include_classes [Boolean] Whether to include class variables.
    # @param include_globals [Boolean] Whether to include global variables.
    # @return [Hash] A structured hash containing variable and contextual information.
    def convert_binding_to_binding_info(
      b,
      include_locals: false,
      include_lets: false,
      include_instances: false,
      include_classes: false,
      include_globals: false
    )
      file = b.eval("__FILE__") rescue nil
      line = b.eval("__LINE__") rescue nil
      location = [file, line].compact.join(":")

      receiver = b.receiver

      locals = {}
      # Local variables
      if include_locals
        locals = b.local_variables.map do |var|
          [var, safe_local_variable_get(b, var)]
        end.to_h.reject { |k, _| ignored?(k) }
      end

      # Instance variables
      instances = {}
      if include_instances && safe_to_inspect?(receiver)
        receiver.instance_variables.each do |var|
          next if self.ignored?(var)
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
              lets[key.to_sym] = val unless ignored?(key.to_sym)
            end
          end
        end
      end

      # Class variables
      classes = {}
      if include_classes
        target = receiver.is_a?(Class) || receiver.is_a?(Module) ? receiver : receiver.class
        if target.respond_to?(:class_variables)
          target.class_variables.each do |var|
            next if ignored?(var)
            classes[var] = target.class_variable_get(var) rescue "[Error accessing #{var}]"
          end
        end
      end

      # Globals
      globals = {}
      if include_globals
        (Kernel.global_variables - [:$~, :$_, :$&, :$`, :$']).each do |var|
          next if ignored?(var)
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
          class_vars: classes
        },
        exception: "NoException",
        capture_event: "manual_debug"
      }
    end

    # Formats a binding_info hash into a human-readable string.
    # @param info [Hash] The binding_info hash to format.
    # @return [String] A formatted string for display.
    def format_binding_info(info)
      out = []
      out << Wut::Colors.green("From:") + " #{info[:source]}"

      unless info[:variables][:locals].empty?
        out << Wut::Colors.green("\nLocals:")
        out << describe_hash(info[:variables][:locals])
      end

      unless info[:variables][:instances].empty?
        out << Wut::Colors.green("\nInstances:")
        out << describe_hash(info[:variables][:instances])
      end

      unless info[:variables][:class_vars].empty?
        out << Wut::Colors.green("\nClass Vars:")
        out << describe_hash(info[:variables][:class_vars])
      end

      unless info[:variables][:lets].empty?
        out << Wut::Colors.green("\nLet Variables:")
        out << describe_hash(info[:variables][:lets])
      end

      unless info[:variables][:globals].empty?
        out << Wut::Colors.green("\nGlobals:")
        out << describe_hash(info[:variables][:globals])
      end

      out.join("\n")
    end

    private

    # Formats a hash into a descriptive string.
    # @param hash [Hash] The hash to format.
    # @return [String] A string representation of the hash.
    def describe_hash(hash)
      hash.map do |k, v|
        "  #{Wut::Colors.purple(k)}: #{format_variable(v)}"
      end.join("\n")
    end

    def format_variable(variable)
      if awesome_print_available? && Colors.enabled
        safe_to_s(variable.ai)
      else
        safe_inspect(variable)
      end
    rescue => e
      var_str = safe_to_s(variable)
      "#{var_str}: [Inspection Error #{e.message}]"
    end

    def safe_to_s(variable)
      str = variable.to_s
      if str.length > 120
        str[0...120] + '...'
      else
        str
      end
    rescue
      "[Unprintable variable]"
    end

    # Safely inspects an object, truncating if necessary.
    # @param obj [Object] The object to inspect.
    # @return [String] A string representation of the object.
    def safe_inspect(obj)
      str = obj.inspect
      str.size > 300 ? (str[0..300] + "... (truncated)") : str
    rescue
      "[un-inspectable]"
    end

    # Determines if an object can be inspected without errors.
    # @param obj [Object] The object to check.
    # @return [Boolean] True if the object can be inspected.
    def safe_to_inspect?(obj)
      obj.class
      true
    rescue NoMethodError
      false
    end

    # Safely retrieves a local variable's value from a binding.
    # @param binding_context [Binding] The binding to query.
    # @param var_name [Symbol] The variable name.
    # @return [Object] The variable's value, or an error message.
    def safe_local_variable_get(binding_context, var_name)
      binding_context.local_variable_get(var_name)
    rescue => e
      "[Error accessing local variable #{var_name}: #{e.message}]"
    end

    # Safely retrieves an instance variable's value from an object.
    # @param obj [Object] The object to query.
    # @param var_name [Symbol] The variable name.
    # @return [Object] The variable's value, or an error message.
    def safe_instance_variable_get(obj, var_name)
      obj.instance_variable_get(var_name)
    rescue => e
      "[Error accessing instance variable #{var_name}: #{e.message}]"
    end

    # Safely retrieves a global variable's value.
    # @param var_name [Symbol] The global variable name.
    # @return [Object] The variable's value, or an error message.
    def safe_global_variable_get(var_name)
      eval("#{var_name}")
    rescue => e
      "[Error accessing global variable #{var_name}: #{e.message}]"
    end

    # Checks if AwesomePrint is available.
    # @return [Boolean] True if AwesomePrint is defined.
    def awesome_print_available?
      return @awesome_print_available unless @awesome_print_available.nil?
      @awesome_print_available = defined?(AwesomePrint)
    end
  end

end

# Automatically set up Wut on require
Wut.setup
