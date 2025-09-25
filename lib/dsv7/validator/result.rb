# frozen_string_literal: true

# Validation result container
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
    class Result
      attr_reader :errors, :warnings, :list_type, :version

      def initialize
        @errors = []
        @warnings = []
        @list_type = nil
        @version = nil
      end

      def add_error(message)
        @errors << message
      end

      def add_warning(message)
        @warnings << message
      end

      def set_format(list_type, version)
        @list_type = list_type
        @version = version
      end

      def valid?
        @errors.empty?
      end
    end
  end
end
