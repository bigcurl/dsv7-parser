# frozen_string_literal: true

require 'stringio'
require_relative 'validator/result'
require_relative 'validator/core'

module Dsv7
  ##
  # Dsv7::Validator
  #
  # Validates DSV7 files (German Swimming Federation “Format 7”) against a
  # pragmatic subset of the official specification. The validator focuses on
  # high‑level envelope rules (FORMAT/DATEIENDE, encoding, comments, delimiters),
  # filename hints, element cardinalities, and per‑element attribute types for all
  # four supported list types (WKDL, VML, ERG, VRL).
  #
  # Intent
  # - Provide fast, streaming validation without external dependencies.
  # - Produce precise, stable error and warning messages suitable for tooling and
  #   tests (see `test/dsv7/*`).
  # - Keep responsibilities narrow: structural checks here; parsing in
  #   {Dsv7::Parser}.
  #
  # Semantics
  # - Errors on UTF‑8 BOM and on invalid UTF‑8 (input is scrubbed for messages).
  # - Warns once when CRLF line endings are detected (still valid).
  # - When validating a file path, may add a filename pattern warning if it
  #   does not match `JJJJ-MM-TT-Ort-Zusatz.DSV7`.
  #
  # @api public
  # @since 7.0.0
  # @example Validate a file by path
  #   result = Dsv7::Validator.validate('2024-01-01-Example-Wk.DSV7')
  #   result.valid?        # => true/false
  #   result.errors        # => ["..."]
  #   result.warnings      # => ["..."]
  #   result.list_type     # => 'Wettkampfdefinitionsliste' (after FORMAT)
  #   result.version       # => '7'
  #
  # @see Dsv7::Parser For streaming parsing helpers and event API
  # Validates overall conformity of a DSV7 file against high-level rules
  # extracted from the specification markdown under `specification/dsv7`.
  #
  # Scope: structural and format-level checks that do not require
  # knowledge of the full element schemas.
  class Validator
    # Known list types from the overview section
    # @return [Array<String>]
    ALLOWED_LIST_TYPES = %w[
      Wettkampfdefinitionsliste
      Vereinsmeldeliste
      Wettkampfergebnisliste
      Vereinsergebnisliste
    ].freeze

    # Validate a DSV7 input.
    #
    # Accepts:
    # - IO-like objects (`respond_to?(:read)`) → streamed
    # - String paths to files → streamed
    # - String content → streamed via StringIO
    #
    # @param input [IO, String] An IO, a file path String, or a String with file content
    # @api public
    # @since 7.0.0
    # @return [Dsv7::Validator::Result] Validation result with errors/warnings and metadata
    # @raise [ArgumentError] if an unsupported input type is provided
    def self.validate(input)
      return new.send(:validate_stream, input) if input.respond_to?(:read)
      return validate_path(input) if input.is_a?(String) && File.file?(input)
      return new.send(:validate_stream, StringIO.new(input.b)) if input.is_a?(String)

      raise ArgumentError, 'Unsupported input; pass IO, file path String, or content String'
    end

    class << self
      private

      # @api private
      def validate_path(path)
        File.open(path, 'rb') do |io|
          return new.send(:validate_stream, io, filename: File.basename(path))
        end
      end
    end

    private

    # @api private
    # @param io [IO]
    # @param filename [String, nil]
    # @return [Dsv7::Validator::Result]
    def validate_stream(io, filename: nil)
      result = Result.new
      Core.new(result, filename).call_io(io)
    end
  end
end
