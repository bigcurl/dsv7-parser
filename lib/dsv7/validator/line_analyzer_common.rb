# frozen_string_literal: true

require_relative '../lex'
require_relative 'cardinality'

module Dsv7
  class Validator
    # Handles line-by-line structural checks for WKDL-specific logic
    module LineAnalyzerWk
      def track_wk_element(trimmed)
        return unless @result.list_type == 'Wettkampfdefinitionsliste'

        pair = Dsv7::Lex.element(trimmed)
        return unless pair

        name, = pair
        return if name == 'FORMAT'
        return if name == 'DATEIENDE'

        @wk_elements[name] += 1
      end

      def validate_wk_list_elements
        WkCardinality.new(@result, @wk_elements).validate!
      end

      def validate_wk_line(trimmed, line_number)
        return unless @result.list_type == 'Wettkampfdefinitionsliste'

        pair = Dsv7::Lex.element(trimmed)
        return unless pair

        name, attrs = pair
        return if %w[FORMAT DATEIENDE].include?(name)

        @wk_schema.validate_element(name, attrs, line_number)
      end
    end

    # Handles line-by-line structural checks for VML-specific logic
    module LineAnalyzerVml
      def track_vml_element(trimmed)
        return unless @result.list_type == 'Vereinsmeldeliste'

        pair = Dsv7::Lex.element(trimmed)
        return unless pair

        name, = pair
        return if name == 'FORMAT'
        return if name == 'DATEIENDE'

        @vml_elements[name] += 1
      end

      def validate_vml_list_elements
        VmlCardinality.new(@result, @vml_elements).validate!
      end

      def validate_vml_line(trimmed, line_number)
        return unless @result.list_type == 'Vereinsmeldeliste'

        pair = Dsv7::Lex.element(trimmed)
        return unless pair

        name, attrs = pair
        return if %w[FORMAT DATEIENDE].include?(name)

        @vml_schema.validate_element(name, attrs, line_number)
      end
    end
  end
end
