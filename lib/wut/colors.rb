# lib/wut/colors.rb
module Wut
  class Colors
    COLORS = {
      red:    31,
      green:  32,
      yellow: 33,
      blue:   34,
      purple: 35,
      cyan:   36,
      white:  0
    }.freeze

    RESET_CODE = "\e[0m".freeze

    class << self
      attr_accessor :enabled

      def color(num, string)
        return string unless enabled
        "#{code(num)}#{string}#{RESET_CODE}"
      end

      def code(num)
        "\e[#{num}m"
      end

      COLORS.each do |color, code|
        define_method(color) do |str|
          color(code, str)
        end
      end
    end
  end
end
