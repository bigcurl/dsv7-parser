# frozen_string_literal: true

require 'stringio'
require_relative '../stream'
require_relative '../lex'
require_relative 'io_util'

module Dsv7
  module Parser
    # Internal engine that implements the streaming mechanics.
    ##
    # Internal streaming engine used by {Dsv7::Parser}.
    #
    # Converts an input (path/IO/String) into a stream of parser events. It
    # performs the same line normalization as the validator (via Stream/IoUtil),
    # strips inline comments, and stops emitting at `DATEIENDE`.
    #
    # @api private
    class Engine
      # @api private
      def self.stream_any(input, emitter)
        new(input, emitter).stream_any
      end

      # @api private
      def self.stream_list(input, emitter, expected_list_type)
        new(input, emitter).stream_list(expected_list_type)
      end

      def initialize(input, emitter)
        @input = input
        @emitter = emitter
      end

      def stream_any
        state = { ln: 0, saw: false }
        IoUtil.with_io(@input) do |io|
          IoUtil.each_content_line(io) do |content, ln|
            state[:ln] = ln
            break if handle_first_or_emit_any?(content, ln, @emitter, state)
          end
        end
        @emitter << [:end, nil, state[:ln]]
      end

      def stream_list(expected_list_type)
        state = { ln: 0, saw: false }
        IoUtil.with_io(@input) do |io|
          IoUtil.each_content_line(io) do |content, ln|
            state[:ln] = ln
            break if handle_first_or_emit?(content, ln, @emitter, state, expected_list_type)
          end
        end
        @emitter << [:end, nil, state[:ln]]
      end

      private

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

      def handle_first_or_emit_any?(content, line_number, emitter, state)
        unless state[:saw]
          lt, ver = parse_format_any(content, line_number)
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
        format_required!(line_number) unless m

        list_type, version = m
        unless list_type == expected_list_type
          short = parser_short_name(expected_list_type)
          raise Dsv7::Parser::Error, "Unsupported list type '#{list_type}' for #{short} parser"
        end

        [list_type, version]
      end

      def parse_format_any(content, line_number)
        pair = Dsv7::Lex.parse_format(content)
        format_required!(line_number) unless pair
        pair
      end

      def format_required!(line_number)
        raise Dsv7::Parser::Error, "First non-empty line must be FORMAT (line #{line_number})"
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
