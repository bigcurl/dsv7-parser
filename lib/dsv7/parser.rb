# frozen_string_literal: true

require_relative 'parser/version'
require_relative '../dsv7/validator'

module Dsv7
  module Parser
    class Error < StandardError; end

    # Streaming parser for Wettkampfdefinitionsliste (WKDL).
    #
    # Usage:
    # - With block: yields events [:format, payload, line_number],
    #   [:element, payload, line_number], [:end, nil, line_number]
    #   payload for :format => { list_type: 'Wettkampfdefinitionsliste', version: '7' }
    #   payload for :element => { name: 'ERZEUGER', attrs: ['Soft', '1.0', 'mail@example.com'] }
    # - Without block: returns an Enumerator that yields the same triplets.
    #
    # Note: This is a tolerant parser focused on streaming extraction, not validation.
    # It performs basic stripping of inline comments, BOM handling and UTF-8 scrubbing.
    def self.parse_wettkampfdefinitionsliste(input, &block)
      enum = Enumerator.new do |y|
        io = to_io(input)
        begin
          io.binmode
        rescue StandardError
          # no-op for StringIO
        end

        # Skip UTF-8 BOM if present (validator reports this as an error; parser tolerates it)
        head = io.read(3)
        if head && !head.empty? && head.bytes != [0xEF, 0xBB, 0xBF]
          head.bytes.reverse_each { |b| io.ungetbyte(b) }
        end

        line_number = 0
        saw_format = false
        list_type = nil
        version = nil

        io.each_line("\n") do |raw|
          line_number += 1
          line = sanitize_line(raw)
          content = strip_inline_comment(line).strip
          next if content.empty?

          unless saw_format
            if (m = content.match(/^FORMAT:([^;]+);([^;]+);$/))
              list_type = m[1]
              version = m[2]
              unless list_type == 'Wettkampfdefinitionsliste'
                raise Error, "Unsupported list type '#{list_type}' for WKDL parser"
              end

              y << [:format, { list_type: list_type, version: version }, line_number]
              saw_format = true
            else
              raise Error, "First non-empty line must be FORMAT (line #{line_number})"
            end
            next
          end

          break if content == 'DATEIENDE'

          name, rest = parse_element_line(content)
          next if name.nil?

          attrs = rest.split(';', -1)
          attrs.pop if attrs.last == ''
          y << [:element, { name: name, attrs: attrs }, line_number]
        end

        y << [:end, nil, line_number]
      end

      return enum.each(&block) if block_given?

      enum
    end

    class << self
      private

      def to_io(input)
        return input if input.respond_to?(:read)
        return File.open(input, 'rb') if input.is_a?(String) && File.file?(input)
        return StringIO.new(String(input).b) if input.is_a?(String)

        raise ArgumentError, 'Unsupported input; pass IO, file path String, or content String'
      end

      def sanitize_line(raw)
        s = raw.delete_suffix("\n").delete_suffix("\r")
        s.force_encoding(Encoding::UTF_8)
        return s if s.valid_encoding?

        s.scrub('�')
      end

      def strip_inline_comment(line)
        return line unless line.include?('(*') && line.include?('*)')

        line.gsub(/\(\*.*?\*\)/, '')
      end

      def parse_element_line(content)
        return [nil, nil] unless content.include?(':')

        content.split(':', 2).tap do |pair|
          pair[0] = pair[0].strip if pair[0]
        end
      end
    end
  end
end
