# frozen_string_literal: true

require 'stringio'
require_relative '../stream'

module Dsv7
  module Parser
    module IoUtil
      ##
      # Parser IO utilities.
      #
      # `to_io` converts supported inputs to an IO; `with_io` manages lifetime
      # and applies Stream normalization; `each_content_line` yields non‑empty,
      # comment‑stripped content lines with 1‑based line numbers.
      #
      # @api private

      module_function

      # Convert supported inputs into an IO instance.
      # @param input [IO, String]
      # @return [IO]
      # @raise [ArgumentError] for unsupported input types
      def to_io(input)
        return input if input.respond_to?(:read)
        return File.open(input, 'rb') if input.is_a?(String) && File.file?(input)
        return StringIO.new(String(input).b) if input.is_a?(String)

        raise ArgumentError, 'Unsupported input; pass IO, file path String, or content String'
      end

      # Open/normalize an input and yield an IO. Closes the IO when it was
      # opened from a file path.
      # @param input [IO, String]
      # @yield [io]
      # @yieldparam io [IO]
      # @return [void]
      def with_io(input)
        close_after = input.is_a?(String) && File.file?(input)
        io = to_io(input)
        Dsv7::Stream.binmode_if_possible(io)
        Dsv7::Stream.read_bom?(io) # parser tolerates BOM
        yield io
      ensure
        io&.close if close_after
      end

      # Yield each non-empty, comment-stripped content line with 1-based
      # line numbers.
      # @param io [IO]
      # @yield [content, line_number]
      # @yieldparam content [String]
      # @yieldparam line_number [Integer]
      # @return [void]
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
    end
  end
end
