# frozen_string_literal: true

##
# Validation result container.
#
# Collects errors and warnings during a validation run and exposes
# `list_type`/`version` after a valid FORMAT line is seen. `valid?` is true
# iff there are no errors; warnings never affect validity.
#
# Message stability
# - Keep message texts stable where possible; tests rely on them.
# - Include line numbers when relevant to aid debugging.

module Dsv7
  class Validator
    # Result container for validation
    #
    # @api public
    # @since 7.0.0
    class Result
      # @!attribute [r] errors
      #   @return [Array<String>] Collected human-readable error messages
      # @!attribute [r] warnings
      #   @return [Array<String>] Collected warnings; do not affect validity
      # @!attribute [r] list_type
      #   @return [String, nil] List type after parsing the FORMAT line
      # @!attribute [r] version
      #   @return [String, nil] Format version after parsing the FORMAT line
      attr_reader :errors, :warnings, :list_type, :version

      def initialize
        @errors = []
        @warnings = []
        @list_type = nil
        @version = nil
      end

      # Add an error message.
      # @param message [String]
      # @return [void]
      def add_error(message)
        @errors << message
      end

      # Add a warning message.
      # @param message [String]
      # @return [void]
      def add_warning(message)
        @warnings << message
      end

      # Set FORMAT metadata after a valid FORMAT line was observed.
      # @param list_type [String]
      # @param version [String]
      # @return [void]
      def set_format(list_type, version)
        @list_type = list_type
        @version = version
      end

      # Whether the validation run produced no errors.
      # @return [Boolean]
      def valid?
        @errors.empty?
      end
    end
  end
end
