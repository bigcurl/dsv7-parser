# frozen_string_literal: true

module Dsv7
  class Validator
    # Core pipeline for validator: encoding + line parsing
    class Core
      def initialize(result, filename)
        @result = result
        @filename = filename
      end

      def call_io(io)
        io.binmode
        check_bom_and_rewind(io)
        process_lines(io)
      end

      private

      def check_bom_and_rewind(io)
        head = io.read(3)
        return if head.nil? || head.empty?

        if head.bytes == [0xEF, 0xBB, 0xBF]
          @result.add_error('UTF-8 BOM detected (spec requires UTF-8 without BOM)')
        else
          head.bytes.reverse_each { |b| io.ungetbyte(b) }
        end
      end

      def sanitize_line(raw_line)
        # Remove trailing LF then CR for CRLF compatibility
        s = raw_line.delete_suffix("\n").delete_suffix("\r")
        s.force_encoding(Encoding::UTF_8)
        return s if s.valid_encoding?

        @result.add_error('File is not valid UTF-8 encoding')
        s.scrub('�')
      end

      def process_lines(io)
        analyzer = LineAnalyzer.new(@result)
        had_crlf = iterate(io) { |line, no| analyzer.process_line(line, no) }
        @result.add_warning('CRLF line endings detected') if had_crlf
        analyzer.finish
        check_filename(@filename)
        @result
      end

      def iterate(io)
        had_crlf = false
        line_no = 0
        io.each_line("\n") do |raw_line|
          line_no += 1
          had_crlf ||= raw_line.end_with?("\r\n")
          yield sanitize_line(raw_line), line_no
        end
        had_crlf
      end

      def check_filename(filename)
        return if filename.nil?
        return if filename.match(/^\d{4}-\d{2}-\d{2}-[^.]+\.DSV7$/)

        @result.add_warning(
          "Filename '#{filename}' does not follow 'JJJJ-MM-TT-Ort-Zusatz.DSV7'"
        )
      end
    end

    # Handles line-by-line structural checks
    class LineAnalyzer
      def initialize(result)
        @result = result
        @effective_index = 0
        @format_line_index = nil
        @dateiende_index = nil
        @after_dateiende_effective_line_no = nil
      end

      def process_line(line, line_no)
        check_comment_balance(line, line_no)
        trimmed = strip_inline_comment(line)
        return if trimmed.empty?

        @effective_index += 1
        return handle_first_effective(trimmed, line_no) if @effective_index == 1

        return @dateiende_index = line_no if trimmed == 'DATEIENDE'

        @after_dateiende_effective_line_no ||= line_no if @dateiende_index
        require_semicolon(trimmed, line_no)
      end

      def finish
        post_validate_positions
      end

      private

      def check_comment_balance(line, line_no)
        return unless line.include?('(*') || line.include?('*)')

        opens = line.scan('(*').size
        closes = line.scan('*)').size
        return unless opens != closes

        @result.add_error("Unmatched comment delimiters on line #{line_no}")
      end

      def handle_first_effective(trimmed, line_no)
        @format_line_index = line_no
        check_format_line(trimmed, line_no)
      end

      def strip_inline_comment(line)
        remove_inline_comments(line).strip
      end

      def check_format_line(trimmed, line_no)
        m = trimmed.match(/^FORMAT:([^;]+);(\d+);$/)
        msg = "First non-empty line must be 'FORMAT:<Listentyp>;7;' (line #{line_no})"
        return @result.add_error(msg) unless m

        @result.set_format(lt = m[1], m[2])
        @result.add_error("Unknown list type in FORMAT: '#{lt}'") unless
          Validator::ALLOWED_LIST_TYPES.include?(lt)
        @result.add_error("Unsupported format version '#{m[2]}', expected '7'") unless m[2] == '7'
      end

      def require_semicolon(trimmed, line_no)
        return if trimmed.include?(';')

        @result.add_error("Missing attribute delimiter ';' on line #{line_no}")
      end

      def post_validate_positions
        @result.add_error('Missing FORMAT line at top of file') if @format_line_index.nil?
        return @result.add_error("Missing 'DATEIENDE' terminator line") if @dateiende_index.nil?

        return unless @after_dateiende_effective_line_no

        n = @after_dateiende_effective_line_no
        @result.add_error("Content found after 'DATEIENDE' (line #{n})")
      end

      def remove_inline_comments(line)
        return line unless line.include?('(*') && line.include?('*)')

        line.gsub(/\(\*.*?\*\)/, '')
      end
    end
  end
end
