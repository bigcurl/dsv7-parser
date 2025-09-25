# frozen_string_literal: true

require 'stringio'
require_relative '../stream'

module Dsv7
  module Parser
    module IoUtil
      module_function

      def to_io(input)
        return input if input.respond_to?(:read)
        return File.open(input, 'rb') if input.is_a?(String) && File.file?(input)
        return StringIO.new(String(input).b) if input.is_a?(String)

        raise ArgumentError, 'Unsupported input; pass IO, file path String, or content String'
      end

      def with_io(input)
        close_after = input.is_a?(String) && File.file?(input)
        io = to_io(input)
        Dsv7::Stream.binmode_if_possible(io)
        Dsv7::Stream.read_bom?(io) # parser tolerates BOM
        yield io
      ensure
        io&.close if close_after
      end

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
