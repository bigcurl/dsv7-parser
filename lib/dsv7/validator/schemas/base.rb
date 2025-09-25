# frozen_string_literal: true

# Base class for per‑list schemas.
#
# A concrete schema class defines a `SCHEMAS` Hash mapping element names to an
# Array of attribute specs. Each attribute spec is a tuple:
#   [type, required, opts=nil]
# where `type` corresponds to a `check_<type>` method mixed in from the
# type‑check modules, `required` is a boolean, and `opts` can be used by a
# specific checker.
#
# Cross‑field/element rules may be implemented by overriding
# `validate_cross_rules(name, attrs, line_number)`.
#
# Documentation tips when adding/adjusting schemas:
# - Copy the attribute count and types from the spec and real‑world examples.
# - Clearly mark intentionally deferred or ambiguous elements in commit msgs.
# - Add both positive and negative tests for each element and datatype.

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
