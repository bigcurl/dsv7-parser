# frozen_string_literal: true

module Dsv7
  class Validator
    class SchemaBase
      def initialize(result)
        @result = result
      end

      def validate_element(name, attrs, line_number)
        schema = self.class::SCHEMAS[name]
        return unless schema

        check_count(name, attrs, schema.length, line_number)
        validate_attribute_types(name, attrs, schema, line_number)
        validate_cross_rules(name, attrs, line_number) if respond_to?(:validate_cross_rules, true)
      end

      private

      def validate_attribute_types(name, attrs, schema, line_number)
        schema.each_with_index do |spec, i|
          type, required, opts = spec
          val = attrs[i]

          if (val.nil? || val.empty?) && required
            add_error("Element #{name}: missing required attribute #{i + 1} (line #{line_number})")
            next
          end
          next if val.nil? || val.empty?

          send("check_#{type}", name, i + 1, val, line_number, opts)
        end
      end

      def add_error(msg)
        @result.add_error(msg)
      end

      def check_count(name, attrs, expected, line_number)
        got = attrs.length
        return if got == expected

        add_error(
          "Element #{name}: expected #{expected} attributes, got #{got} (line #{line_number})"
        )
      end
    end
  end
end
