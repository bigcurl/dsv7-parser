# frozen_string_literal: true

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
