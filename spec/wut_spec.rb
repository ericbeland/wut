require "spec_helper"

RSpec.describe Wut do
  before do
    # Initialize ignore list with default variables to skip
    Wut.ignore_list = Set.new(%i[@__memoized @__inspect_output])
    Wut::Colors.enabled = true # Enable colors for testing
  end

  # Helper method to strip ANSI color codes from strings
  def strip_color_codes(str)
    str.gsub(/\e\[\d+(;\d+)*m/, '')
  end

  # Helper to capture output
  def capture_output
    old_stdout = $stdout
    output = StringIO.new
    $stdout = output
    yield
    output.string
  ensure
    $stdout = old_stdout
  end

  describe ".convert_binding_to_binding_info" do
    it "returns a structured binding_info hash with locals" do
      captured_output = capture_output do
        foo = 42
        w.l
      end

      stripped_output = strip_color_codes(captured_output)
      expect(stripped_output).to include("Locals:")
      expect(stripped_output).to include("foo: 42")
    end
  end

  describe ".format_binding_info" do
    it "formats binding_info into a readable string" do
      captured_output = capture_output do
        foo = 100
        w.l
      end

      stripped_output = strip_color_codes(captured_output)
      expect(stripped_output).to include("Locals:")
      expect(stripped_output).to include("foo: 100")
    end
  end

  describe "Binding extensions" do
    describe "#debug_output" do
      it "returns formatted locals for #l" do
        captured_output = capture_output do
          foo = 'bar'
          w.l
        end

        stripped_output = strip_color_codes(captured_output)
        expect(stripped_output).to include("Locals:")
        expect(stripped_output).to include("foo: \"bar\"")
      end

      let(:boo) { 'baz' }
      it "returns formatted lets for #l" do
        captured_output = capture_output do
          boo
          w.l
        end

        stripped_output = strip_color_codes(captured_output)
        expect(stripped_output).to include("Let Variables:")
        expect(stripped_output).to include("boo: \"baz\"")
      end

      it "returns formatted instance variables for #i" do
        @bar = "instance_var"
        captured_output = capture_output do
          w.i
        end

        stripped_output = strip_color_codes(captured_output)
        expect(stripped_output).to include("Instances:")
        expect(stripped_output).to include("@bar: \"instance_var\"")
      end

      it "returns formatted class variables for #c" do
        class DummyClass
          @@baz = "class_var"
          def boo
            w.c
          end
        end

        dummy = DummyClass.new
        captured_output = capture_output do
          dummy.boo
        end

        stripped_output = strip_color_codes(captured_output)
        expect(stripped_output).to include("Class Vars:")
        expect(stripped_output).to include("@@baz: \"class_var\"")
      end

      it "returns formatted globals for #tf?" do
        $global_var = "global_var"
        captured_output = capture_output do
          w.tf?
        end

        stripped_output = strip_color_codes(captured_output)
        expect(stripped_output).to include("Globals:")
        expect(stripped_output).to include("$global_var: \"global_var\"")
      end

      it "applies the ignore list for instance variables" do
        @ignored = "secret_value"
        Wut.ignore_list << :@ignored

        captured_output = capture_output do
          w.i
        end

        stripped_output = strip_color_codes(captured_output)
        expect(stripped_output).not_to include("secret_value")
        expect(stripped_output).not_to include("@ignored: \"secret_value\"")
      end
    end

    describe "#print_debug_output" do
      it "prints debug output to the console for #l" do
        captured_output = capture_output do
          foo = "local_var"
          w.l
        end

        stripped_output = strip_color_codes(captured_output)
        expect(stripped_output).to include("Locals:")
        expect(stripped_output).to include("foo: \"local_var\"")
      end

      it "prints debug output to the console for #tf?" do
        captured_output = capture_output do
          $global_var = "global_var"
          w.tf?
        end

        stripped_output = strip_color_codes(captured_output)
        expect(stripped_output).to include("Globals:")
        expect(stripped_output).to include("$global_var: \"global_var\"")
      end

      it "prints debug output for class variables using #c" do
        class DummyKlass
          @@bar = "buz"
          def bee
            w.c
          end
        end

        captured_output = capture_output do
          dk = DummyKlass.new
          dk.bee
        end

        stripped_output = strip_color_codes(captured_output)
        expect(stripped_output).to include("Class Vars:")
        expect(stripped_output).to include("@@bar: \"buz\"")
      end
    end
  end

  describe "Kernel aliasing" do
    it "aliases binding to w" do
      captured_output = capture_output do
        foo = 42
        w.l
      end

      stripped_output = strip_color_codes(captured_output)
      expect(stripped_output).to include("Locals:")
      expect(stripped_output).to include("foo: 42")
    end

    it "w prints to the console" do
      captured_output = capture_output do
        foo = "local_var"
        w.l
      end

      stripped_output = strip_color_codes(captured_output)
      expect(stripped_output).to include("Locals:")
      expect(stripped_output).to include("foo: \"local_var\"")
    end
  end
end
