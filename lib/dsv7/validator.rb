# frozen_string_literal: true

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
#   `Dsv7::Parser`.
#
# Public API
# - `.validate(input) -> Dsv7::Validator::Result`
#   Accepts a file path String, an IO, or a content String (streamed via
#   StringIO). Always returns a `Result` object with `errors`, `warnings`,
#   `list_type`, `version`, and `valid?`.
#
# Examples
#   result = Dsv7::Validator.validate('2024-01-01-Example-Wk.DSV7')
#   result.valid?        # => true/false
#   result.errors        # => ["..."]
#   result.warnings      # => ["..."]
#   result.list_type     # => 'Wettkampfdefinitionsliste' (after FORMAT)
#   result.version       # => '7'
#
# Writing good docs for new checks
# - State the rule’s purpose and scope (what it enforces, and why).
# - Describe inputs/outputs and when an error vs. warning is emitted.
# - Keep messages actionable and stable; include line numbers where helpful.
# - Reference spec sections or examples in commit messages or tests.
# - Add both accept and reject tests under `test/dsv7/`.

require 'stringio'
require_relative 'validator/result'
require_relative 'validator/core'

module Dsv7
  # Validates overall conformity of a DSV7 file against high-level rules
  # extracted from the specification markdown under `specification/dsv7`.
  #
  # Scope: structural and format-level checks that do not require
  # knowledge of the full element schemas.
  class Validator
    # Known list types from the overview section
    ALLOWED_LIST_TYPES = %w[
      Wettkampfdefinitionsliste
      Vereinsmeldeliste
      Wettkampfergebnisliste
      Vereinsergebnisliste
    ].freeze

    # Single public entrypoint. Accepts:
    # - IO-like objects (respond_to?(:read)) → streamed
    # - String paths to files → streamed
    # - String content → streamed via StringIO
    def self.validate(input)
      return new.send(:validate_stream, input) if input.respond_to?(:read)
      return validate_path(input) if input.is_a?(String) && File.file?(input)
      return new.send(:validate_stream, StringIO.new(input.b)) if input.is_a?(String)

      raise ArgumentError, 'Unsupported input; pass IO, file path String, or content String'
    end

    class << self
      private

      def validate_path(path)
        File.open(path, 'rb') do |io|
          return new.send(:validate_stream, io, filename: File.basename(path))
        end
      end
    end

    private

    def validate_stream(io, filename: nil)
      result = Result.new
      Core.new(result, filename).call_io(io)
    end
  end
end
