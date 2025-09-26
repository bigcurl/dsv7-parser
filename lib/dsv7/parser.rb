# frozen_string_literal: true

require_relative 'parser/version'
require_relative 'parser/engine'
require_relative 'validator'
require_relative 'stream'
require_relative 'lex'

module Dsv7
  ##
  # Dsv7::Parser
  #
  # Streaming parser for DSV7 lists. It yields a simple event stream so callers
  # can build their own structures without loading the whole file into memory.
  # The parser is intentionally tolerant (e.g., it scrubs invalid UTF‑8 and
  # accepts BOM) — pair it with {Dsv7::Validator} for strict conformance.
  #
  # Events
  # - `[:format, { list_type: String, version: String }, line_number]` — first
  #   effective line must be a FORMAT line.
  # - `[:element, { name: String, attrs: Array<String> }, line_number]` — for
  #   each element line between FORMAT and DATEIENDE.
  # - `[:end, nil, line_number]` — emitted after `DATEIENDE` (or EOF if missing).
  #
  # @api public
  # @since 7.0.0
  # @example Enumerate events for any list type
  #   Dsv7::Parser.parse(io_or_path_or_string) do |type, payload, ln|
  #     case type
  #     when :format  then # inspect payload[:list_type], payload[:version]
  #     when :element then # payload[:name], payload[:attrs]
  #     when :end     then # done
  #     end
  #   end
  #
  # Documenting new helpers
  # - Describe when a helper raises (e.g., wrong list type for a type‑specific
  #   parser) and what it yields.
  # - Note streaming/encoding behavior and that comments are stripped inline.
  module Parser
    # Error type raised by the parser when the input
    # does not satisfy basic envelope expectations.
    class Error < StandardError; end

    # @!group Parsers
    #
    # Generic streaming parser that auto-detects the list type from the
    # first effective FORMAT line and yields events for any DSV7 list.
    #
    # The first event is always `:format` with payload
    # `{ list_type: <String>, version: <String> }`.
    #
    # @api public
    # @since 7.0.0
    # @overload parse(input, &block)
    #   @param input [IO, String] An IO, a file path String, or a String with file content
    #   @yield [type, payload, line_number] Emitted for each event
    #   @yieldparam type [Symbol] Event type (:format, :element, :end)
    #   @yieldparam payload [Hash, nil] Event payload
    #   @yieldparam line_number [Integer] 1-based line number of the event
    #   @return [void]
    # @overload parse(input)
    #   @param input [IO, String]
    #   @return [Enumerator] Enumerator over `[type, payload, line_number]`
    # @see Dsv7::Validator
    # @raise [Dsv7::Parser::Error] when the first effective line is not FORMAT
    # @raise [ArgumentError] if the input type is unsupported
    def self.parse(input, &block)
      enum = Enumerator.new { |y| Engine.stream_any(input, y) }
      return enum.each(&block) if block_given?

      enum
    end

    # Streaming parser for Wettkampfdefinitionsliste (WKDL).
    # Performs inline comment stripping, tolerates BOM, and scrubs UTF-8.
    #
    # @api public
    # @since 7.0.0
    # @overload parse_wettkampfdefinitionsliste(input, &block)
    #   @param input [IO, String]
    #   @yield [type, payload, line_number]
    #   @yieldparam type [Symbol] Event type (:format, :element, :end)
    #   @yieldparam payload [Hash, nil]
    #   @yieldparam line_number [Integer]
    #   @return [void]
    # @overload parse_wettkampfdefinitionsliste(input)
    #   @param input [IO, String]
    #   @return [Enumerator]
    # @raise [Dsv7::Parser::Error] if the list type is not WKDL
    # @raise [ArgumentError] if the input type is unsupported
    # @see Dsv7::Validator
    def self.parse_wettkampfdefinitionsliste(input, &block)
      enum = Enumerator.new { |y| Engine.stream_list(input, y, 'Wettkampfdefinitionsliste') }
      return enum.each(&block) if block_given?

      enum
    end

    # Streaming parser for Vereinsmeldeliste (VML).
    # Same contract as {parse_wettkampfdefinitionsliste}, but expects
    # `FORMAT:Vereinsmeldeliste;7;` as the first effective line.
    # @api public
    # @since 7.0.0
    # @overload parse_vereinsmeldeliste(input, &block)
    #   @param input [IO, String]
    #   @yield [type, payload, line_number]
    #   @return [void]
    # @overload parse_vereinsmeldeliste(input)
    #   @param input [IO, String]
    #   @return [Enumerator]
    # @raise [Dsv7::Parser::Error] if the list type is not VML
    # @raise [ArgumentError] if the input type is unsupported
    # @see Dsv7::Validator
    def self.parse_vereinsmeldeliste(input, &block)
      enum = Enumerator.new { |y| Engine.stream_list(input, y, 'Vereinsmeldeliste') }
      return enum.each(&block) if block_given?

      enum
    end

    # Streaming parser for Wettkampfergebnisliste (ERG).
    # Same contract as the other parse_* methods, but expects
    # `FORMAT:Wettkampfergebnisliste;7;` as the first effective line.
    # @api public
    # @since 7.0.0
    # @overload parse_wettkampfergebnisliste(input, &block)
    #   @param input [IO, String]
    #   @yield [type, payload, line_number]
    #   @return [void]
    # @overload parse_wettkampfergebnisliste(input)
    #   @param input [IO, String]
    #   @return [Enumerator]
    # @raise [Dsv7::Parser::Error] if the list type is not ERG
    # @raise [ArgumentError] if the input type is unsupported
    # @see Dsv7::Validator
    def self.parse_wettkampfergebnisliste(input, &block)
      enum = Enumerator.new { |y| Engine.stream_list(input, y, 'Wettkampfergebnisliste') }
      return enum.each(&block) if block_given?

      enum
    end

    # Streaming parser for Vereinsergebnisliste (VRL).
    # Same contract as the other parse_* methods, but expects
    # `FORMAT:Vereinsergebnisliste;7;` as the first effective line.
    # @api public
    # @since 7.0.0
    # @overload parse_vereinsergebnisliste(input, &block)
    #   @param input [IO, String]
    #   @yield [type, payload, line_number]
    #   @return [void]
    # @overload parse_vereinsergebnisliste(input)
    #   @param input [IO, String]
    #   @return [Enumerator]
    # @raise [Dsv7::Parser::Error] if the list type is not VRL
    # @raise [ArgumentError] if the input type is unsupported
    # @see Dsv7::Validator
    def self.parse_vereinsergebnisliste(input, &block)
      enum = Enumerator.new { |y| Engine.stream_list(input, y, 'Vereinsergebnisliste') }
      return enum.each(&block) if block_given?

      enum
    end
    # @!endgroup
    # no additional private class methods
  end
end
