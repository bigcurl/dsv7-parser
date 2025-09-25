# frozen_string_literal: true

require_relative '../stream'
require_relative 'line_analyzer_common'
require_relative 'schemas/wk_schema'
require_relative 'schemas/vml_schema'
require_relative 'schemas/erg_schema'
require_relative 'schemas/vrl_schema'

module Dsv7
  class Validator
    class LineAnalyzer
      include LineAnalyzerWk
      include LineAnalyzerVml
      include LineAnalyzerErg
      include LineAnalyzerVrl

      def initialize(result)
        @result = result
        @effective_index = 0
        @format_line_index = nil
        @dateiende_index = nil
        @after_dateiende_effective_line_number = nil
        init_schemas_and_counters
      end

      def init_schemas_and_counters
        @wk_elements = Hash.new(0)
        @wk_schema = WkSchema.new(@result)
        @vml_elements = Hash.new(0)
        @vml_schema = VmlSchema.new(@result)
        @erg_elements = Hash.new(0)
        @erg_schema = ErgSchema.new(@result)
        @vrl_elements = Hash.new(0)
        @vrl_schema = VrlSchema.new(@result)
      end

      def process_line(line, line_number)
        check_comment_balance(line, line_number)
        trimmed = strip_inline_comment(line)
        return if trimmed.empty?

        @effective_index += 1
        return handle_first_effective(trimmed, line_number) if @effective_index == 1
        return @dateiende_index = line_number if trimmed == 'DATEIENDE'

        handle_content_line(trimmed, line_number)
      end

      def finish
        post_validate_positions
        validate_wk_list_elements if @result.list_type == 'Wettkampfdefinitionsliste'
        validate_vml_list_elements if @result.list_type == 'Vereinsmeldeliste'
        validate_erg_list_elements if @result.list_type == 'Wettkampfergebnisliste'
        validate_vrl_list_elements if @result.list_type == 'Vereinsergebnisliste'
      end

      private

      def check_comment_balance(line, line_number)
        return unless line.include?('(*') || line.include?('*)')

        opens = line.scan('(*').size
        closes = line.scan('*)').size
        return unless opens != closes

        @result.add_error("Unmatched comment delimiters (line #{line_number})")
      end

      def handle_first_effective(trimmed, line_number)
        @format_line_index = line_number
        check_format_line(trimmed, line_number)
      end

      def strip_inline_comment(line)
        Dsv7::Stream.strip_inline_comment(line).strip
      end

      def check_format_line(trimmed, line_number)
        m = Dsv7::Lex.parse_format(trimmed)
        return format_error(line_number) unless m

        list_type, ver = m
        # Enforce numeric version token for exact syntax compatibility
        return format_error(line_number) unless ver.match?(/^\d+$/)

        @result.set_format(list_type, ver)
        check_list_type(list_type, line_number)
        check_format_version(ver, line_number)
      end

      def format_error(line_number)
        @result.add_error(
          "First non-empty line must be 'FORMAT:<Listentyp>;7;' " \
          "(line #{line_number})"
        )
      end

      def check_list_type(list_type, line_number)
        return if Validator::ALLOWED_LIST_TYPES.include?(list_type)

        @result.add_error("Unknown list type in FORMAT: '#{list_type}' (line #{line_number})")
      end

      def check_format_version(ver, line_number)
        return if ver == '7'

        @result.add_error("Unsupported format version '#{ver}', expected '7' (line #{line_number})")
      end

      def require_semicolon(trimmed, line_number)
        return if trimmed.include?(';')

        @result.add_error("Missing attribute delimiter ';' (line #{line_number})")
      end

      def post_validate_positions
        @result.add_error('Missing FORMAT line at top of file') if @format_line_index.nil?
        return @result.add_error("Missing 'DATEIENDE' terminator line") if @dateiende_index.nil?

        return unless @after_dateiende_effective_line_number

        n = @after_dateiende_effective_line_number
        @result.add_error("Content found after 'DATEIENDE' (line #{n})")
      end

      def handle_content_line(trimmed, line_number)
        @after_dateiende_effective_line_number ||= line_number if @dateiende_index
        require_semicolon(trimmed, line_number)
        track_wk_element(trimmed)
        track_vml_element(trimmed)
        track_erg_element(trimmed)
        track_vrl_element(trimmed)
        validate_wk_line(trimmed, line_number)
        validate_vml_line(trimmed, line_number)
        validate_erg_line(trimmed, line_number)
        validate_vrl_line(trimmed, line_number)
      end
    end
  end
end
