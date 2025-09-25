# frozen_string_literal: true

require_relative 'parser/version'
require_relative 'parser/engine'
require_relative 'validator'
require_relative 'stream'
require_relative 'lex'

module Dsv7
  module Parser
    class Error < StandardError; end

    # Generic streaming parser that auto-detects the list type from the
    # first effective FORMAT line and yields events for any DSV7 list.
    # Yields [:format|:element|:end, payload, line_number].
    # The first event is always :format with payload
    #   { list_type: <String>, version: <String> }.
    def self.parse(input, &block)
      enum = Enumerator.new { |y| Engine.stream_any(input, y) }
      return enum.each(&block) if block_given?

      enum
    end

    # Streaming parser for Wettkampfdefinitionsliste (WKDL).
    # Yields [:format|:element|:end, payload, line_number].
    # Performs inline comment stripping, tolerates BOM, and scrubs UTF-8.
    def self.parse_wettkampfdefinitionsliste(input, &block)
      enum = Enumerator.new { |y| Engine.stream_list(input, y, 'Wettkampfdefinitionsliste') }
      return enum.each(&block) if block_given?

      enum
    end

    # Streaming parser for Vereinsmeldeliste (VML).
    # Same contract as parse_wettkampfdefinitionsliste, but expects
    # FORMAT:Vereinsmeldeliste;7; as the first effective line.
    def self.parse_vereinsmeldeliste(input, &block)
      enum = Enumerator.new { |y| Engine.stream_list(input, y, 'Vereinsmeldeliste') }
      return enum.each(&block) if block_given?

      enum
    end

    # Streaming parser for Wettkampfergebnisliste (ERG).
    # Same contract as the other parse_* methods, but expects
    # FORMAT:Wettkampfergebnisliste;7; as the first effective line.
    def self.parse_wettkampfergebnisliste(input, &block)
      enum = Enumerator.new { |y| Engine.stream_list(input, y, 'Wettkampfergebnisliste') }
      return enum.each(&block) if block_given?

      enum
    end

    # Streaming parser for Vereinsergebnisliste (VRL).
    # Same contract as the other parse_* methods, but expects
    # FORMAT:Vereinsergebnisliste;7; as the first effective line.
    def self.parse_vereinsergebnisliste(input, &block)
      enum = Enumerator.new { |y| Engine.stream_list(input, y, 'Vereinsergebnisliste') }
      return enum.each(&block) if block_given?

      enum
    end
    # no additional private class methods
  end
end
