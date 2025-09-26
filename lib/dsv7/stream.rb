# frozen_string_literal: true

module Dsv7
  ##
  # Low‑level IO helpers for streaming DSV7 content.
  #
  # Responsibilities
  # - Binary mode, BOM detection, and UTF‑8 normalization.
  # - Per‑line sanitization and CR/LF handling.
  # - Inline single‑line comment removal using the `(* ... *)` syntax.
  #
  # These helpers are shared by both the validator and the parser.
  #
  # @api private
  module Stream
    module_function

    # Puts IO into binary mode when possible (no-op for StringIO)
    # @param io [IO]
    # @return [void]
    def binmode_if_possible(io)
      io.binmode
    rescue StandardError
      # ignore
    end

    # Reads potential UTF-8 BOM from the start of IO.
    # Returns true if a BOM was found (and consumed), false otherwise.
    # If no BOM was found, unread the peeked bytes back into the IO.
    # @param io [IO]
    # @return [Boolean]
    def read_bom?(io)
      head = io.read(3)
      return false if head.nil? || head.empty?

      if head.bytes == [0xEF, 0xBB, 0xBF]
        true
      else
        head.bytes.reverse_each { |b| io.ungetbyte(b) }
        false
      end
    end

    # Normalizes a raw line by trimming trailing LF/CR and forcing UTF-8.
    # If invalid encoding is detected, it scrubs replacement chars and
    # calls the optional on_invalid callback.
    # @param raw [String]
    # @param on_invalid [Proc,nil]
    # @return [String]
    def sanitize_line(raw, on_invalid: nil)
      s = raw.delete_suffix("\n").delete_suffix("\r")
      s.force_encoding(Encoding::UTF_8)
      return s if s.valid_encoding?

      on_invalid&.call
      s.scrub('�')
    end

    # Removes inline single-line comments in the form: (* ... *)
    # @param line [String]
    # @return [String]
    def strip_inline_comment(line)
      return line unless line.include?('(*') && line.include?('*)')

      line.gsub(/\(\*.*?\*\)/, '')
    end

    # Iterates sanitized lines, yielding [line, line_number].
    # Returns true if any CRLF lines were observed.
    # @param io [IO]
    # @param on_invalid [Proc,nil]
    # @yield [line, line_number]
    # @yieldparam line [String]
    # @yieldparam line_number [Integer]
    # @return [Boolean] whether any CRLF lines were observed
    def each_sanitized_line(io, on_invalid: nil)
      had_crlf = false
      line_number = 0
      io.each_line("\n") do |raw|
        line_number += 1
        had_crlf ||= raw.end_with?("\r\n")
        yield sanitize_line(raw, on_invalid: on_invalid), line_number
      end
      had_crlf
    end
  end
end
