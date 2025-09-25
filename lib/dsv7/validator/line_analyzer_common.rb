# frozen_string_literal: true

# List‑specific analyzer mixins
#
# These modules encapsulate per‑list tracking and validation methods used by
# LineAnalyzer. Each provides three responsibilities for its list type:
# - track_*_element: counts element occurrences for cardinality checks
# - validate_*_list_elements: validates the observed counts at finish
# - validate_*_line: validates a single element’s attributes via the schema

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

    # Handles line-by-line checks for Wettkampfergebnisliste
    module LineAnalyzerErg
      def track_erg_element(trimmed)
        return unless @result.list_type == 'Wettkampfergebnisliste'

        pair = Dsv7::Lex.element(trimmed)
        return unless pair

        name, = pair
        return if name == 'FORMAT'
        return if name == 'DATEIENDE'

        @erg_elements[name] += 1
      end

      def validate_erg_list_elements
        return if @erg_elements.empty?

        ErgCardinality.new(@result, @erg_elements).validate!
      end

      def validate_erg_line(trimmed, line_number)
        return unless @result.list_type == 'Wettkampfergebnisliste'

        pair = Dsv7::Lex.element(trimmed)
        return unless pair

        name, attrs = pair
        return if %w[FORMAT DATEIENDE].include?(name)

        @erg_schema.validate_element(name, attrs, line_number)
      end
    end

    # Handles line-by-line checks for Vereinsergebnisliste
    module LineAnalyzerVrl
      def track_vrl_element(trimmed)
        return unless @result.list_type == 'Vereinsergebnisliste'

        pair = Dsv7::Lex.element(trimmed)
        return unless pair

        name, = pair
        return if name == 'FORMAT'
        return if name == 'DATEIENDE'

        @vrl_elements[name] += 1
      end

      def validate_vrl_list_elements
        return if @vrl_elements.empty?

        VrlCardinality.new(@result, @vrl_elements).validate!
      end

      def validate_vrl_line(trimmed, line_number)
        return unless @result.list_type == 'Vereinsergebnisliste'

        pair = Dsv7::Lex.element(trimmed)
        return unless pair

        name, attrs = pair
        return if %w[FORMAT DATEIENDE].include?(name)

        @vrl_schema.validate_element(name, attrs, line_number)
      end
    end
  end
end
