# frozen_string_literal: true

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
