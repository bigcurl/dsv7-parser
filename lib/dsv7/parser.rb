# frozen_string_literal: true

require_relative 'parser/version'
require_relative 'validator'
require_relative 'stream'
require_relative 'lex'

module Dsv7
  module Parser
    class Error < StandardError; end

    # Streaming parser for Wettkampfdefinitionsliste (WKDL).
    # Yields [:format|:element|:end, payload, line_number].
    # Performs inline comment stripping, tolerates BOM, and scrubs UTF-8.
    def self.parse_wettkampfdefinitionsliste(input, &block)
      enum = Enumerator.new { |y| stream_list(input, y, 'Wettkampfdefinitionsliste') }
      return enum.each(&block) if block_given?

      enum
    end

    # Streaming parser for Vereinsmeldeliste (VML).
    # Same contract as parse_wettkampfdefinitionsliste, but expects
    # FORMAT:Vereinsmeldeliste;7; as the first effective line.
    def self.parse_vereinsmeldeliste(input, &block)
      enum = Enumerator.new { |y| stream_list(input, y, 'Vereinsmeldeliste') }
      return enum.each(&block) if block_given?

      enum
    end

    # Streaming parser for Wettkampfergebnisliste (ERG).
    # Same contract as the other parse_* methods, but expects
    # FORMAT:Wettkampfergebnisliste;7; as the first effective line.
    def self.parse_wettkampfergebnisliste(input, &block)
      enum = Enumerator.new { |y| stream_list(input, y, 'Wettkampfergebnisliste') }
      return enum.each(&block) if block_given?

      enum
    end

    # Streaming parser for Vereinsergebnisliste (VRL).
    # Same contract as the other parse_* methods, but expects
    # FORMAT:Vereinsergebnisliste;7; as the first effective line.
    def self.parse_vereinsergebnisliste(input, &block)
      enum = Enumerator.new { |y| stream_list(input, y, 'Vereinsergebnisliste') }
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

      def stream_list(input, emitter, expected_list_type)
        state = { ln: 0, saw: false }
        with_io(input) do |io|
          each_content_line(io) do |content, ln|
            state[:ln] = ln
            break if handle_first_or_emit?(content, ln, emitter, state, expected_list_type)
          end
        end
        emitter << [:end, nil, state[:ln]]
      end

      def with_io(input)
        close_after = input.is_a?(String) && File.file?(input)
        io = to_io(input)
        Dsv7::Stream.binmode_if_possible(io)
        Dsv7::Stream.read_bom?(io) # parser tolerates BOM
        yield io
      ensure
        io&.close if close_after
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

      def handle_first_or_emit?(content, line_number, emitter, state, expected_list_type)
        unless state[:saw]
          lt, ver = parse_format_expect(content, line_number, expected_list_type)
          emitter << [:format, { list_type: lt, version: ver }, line_number]
          state[:saw] = true
          return false
        end
        return true if content == 'DATEIENDE'

        emit_element(content, line_number, emitter)
        false
      end

      def parse_format_expect(content, line_number, expected_list_type)
        m = Dsv7::Lex.parse_format(content)
        raise Error, "First non-empty line must be FORMAT (line #{line_number})" unless m

        list_type, version = m
        unless list_type == expected_list_type
          short = parser_short_name(expected_list_type)
          raise Error, "Unsupported list type '#{list_type}' for #{short} parser"
        end

        [list_type, version]
      end

      def emit_element(content, line_number, emitter)
        pair = Dsv7::Lex.element(content)
        return unless pair

        name, attrs = pair
        emitter << [:element, { name: name, attrs: attrs }, line_number]
      end

      def parser_short_name(expected_list_type)
        case expected_list_type
        when 'Wettkampfdefinitionsliste' then 'WKDL'
        when 'Vereinsmeldeliste' then 'VML'
        when 'Wettkampfergebnisliste' then 'ERG'
        else expected_list_type
        end
      end
    end
  end
end
