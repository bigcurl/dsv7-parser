# frozen_string_literal: true

require_relative 'parser/version'
require_relative '../dsv7/validator'
require_relative 'stream'
require_relative 'lex'

module Dsv7
  module Parser
    class Error < StandardError; end

    # Streaming parser for Wettkampfdefinitionsliste (WKDL).
    #
    # Usage:
    # - With block: yields events [:format, payload, line_number],
    #   [:element, payload, line_number], [:end, nil, line_number]
    #   payload for :format => { list_type: 'Wettkampfdefinitionsliste', version: '7' }
    #   payload for :element => { name: 'ERZEUGER', attrs: ['Soft', '1.0', 'mail@example.com'] }
    # - Without block: returns an Enumerator that yields the same triplets.
    #
    # Note: This is a tolerant parser focused on streaming extraction, not validation.
    # It performs basic stripping of inline comments, BOM handling and UTF-8 scrubbing.
    def self.parse_wettkampfdefinitionsliste(input, &block)
      enum = Enumerator.new { |y| stream_wkdl(input, y) }
      return enum.each(&block) if block_given?

      enum
    end

    class << self
      private

      def to_io(input)
        return input if input.respond_to?(:read)
        return File.open(input, 'rb') if input.is_a?(String) && File.file?(input)
        return StringIO.new(String(input).b) if input.is_a?(String)

        raise ArgumentError, 'Unsupported input; pass IO, file path String, or content String'
      end

      def stream_wkdl(input, emitter)
        state = { ln: 0, saw: false }
        io = prepare_io(input)
        each_content_line(io) do |content, ln|
          state[:ln] = ln
          break if handle_first_or_emit?(content, ln, emitter, state)
        end
        emitter << [:end, nil, state[:ln]]
      end

      def prepare_io(input)
        io = to_io(input)
        Dsv7::Stream.binmode_if_possible(io)
        Dsv7::Stream.read_bom?(io) # parser tolerates BOM
        io
      end

      def each_content_line(io)
        ln = 0
        io.each_line("\n") do |raw|
          ln += 1
          line = Dsv7::Stream.sanitize_line(raw)
          content = Dsv7::Stream.strip_inline_comment(line).strip
          next if content.empty?

          yield content, ln
        end
      end

      def handle_first_or_emit?(content, line_number, emitter, state)
        unless state[:saw]
          lt, ver = parse_wkdl_format(content, line_number)
          emitter << [:format, { list_type: lt, version: ver }, line_number]
          state[:saw] = true
          return false
        end
        return true if content == 'DATEIENDE'

        emit_wkdl_element(content, line_number, emitter)
        false
      end

      def parse_wkdl_format(content, line_number)
        m = Dsv7::Lex.parse_format(content)
        raise Error, "First non-empty line must be FORMAT (line #{line_number})" unless m

        list_type, version = m
        unless list_type == 'Wettkampfdefinitionsliste'
          raise Error, "Unsupported list type '#{list_type}' for WKDL parser"
        end

        [list_type, version]
      end

      def emit_wkdl_element(content, line_number, emitter)
        pair = Dsv7::Lex.element(content)
        return unless pair

        name, attrs = pair
        emitter << [:element, { name: name, attrs: attrs }, line_number]
      end
    end
  end
end
