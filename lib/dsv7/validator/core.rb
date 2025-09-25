# frozen_string_literal: true

require_relative '../stream'
require_relative '../lex'
require_relative 'line_analyzer'

module Dsv7
  class Validator
    # Core pipeline for validator: encoding + line parsing
    class Core
      def initialize(result, filename)
        @result = result
        @filename = filename
      end

      def call_io(io)
        Dsv7::Stream.binmode_if_possible(io)
        check_bom_and_rewind(io)
        process_lines(io)
      end

      private

      def check_bom_and_rewind(io)
        bom = Dsv7::Stream.read_bom?(io)
        @result.add_error('UTF-8 BOM detected (spec requires UTF-8 without BOM)') if bom
      end

      def process_lines(io)
        analyzer = LineAnalyzer.new(@result)
        had_crlf = iterate(io) { |line, line_number| analyzer.process_line(line, line_number) }
        @result.add_warning('CRLF line endings detected') if had_crlf
        analyzer.finish
        check_filename(@filename)
        @result
      end

      def iterate(io, &block)
        Dsv7::Stream.each_sanitized_line(
          io,
          on_invalid: -> { @result.add_error('File is not valid UTF-8 encoding') }
        ) do |line, line_number|
          block.call(line, line_number)
        end
      end

      def check_filename(filename)
        return if filename.nil?
        return if filename.match(/^\d{4}-\d{2}-\d{2}-[^.]+\.DSV7$/)

        @result.add_warning(
          "Filename '#{filename}' does not follow 'JJJJ-MM-TT-Ort-Zusatz.DSV7'"
        )
      end
    end
  end
end
