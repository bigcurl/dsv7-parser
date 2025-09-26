# frozen_string_literal: true

module Dsv7
  ##
  # Lexical helpers for simple DSV7 tokens.
  #
  # - {parse_format} extracts the list type and version from an exact
  #   `FORMAT:<Listentyp>;<Version>;` line.
  # - {element} splits an element line into its name and attributes.
  #
  # These functions are intentionally minimal and do not perform semantic checks.
  #
  # @api private
  module Lex
    module_function

    # Parses a FORMAT line.
    # @param line [String]
    # @return [Array<String>, nil] Pair of [list_type, version] or nil if not a FORMAT line
    def parse_format(line)
      m = line.match(/^FORMAT:([^;]+);([^;]+);$/)
      return nil unless m

      [m[1], m[2]]
    end

    # Splits an element content line into name and attributes.
    # @param content [String]
    # @return [Array, nil] Tuple `[name, attrs]` or nil if the line is not an element line
    def element(content)
      return nil unless content.include?(':')

      name, rest = content.split(':', 2)
      name = name.strip if name
      attrs = rest.split(';', -1)
      attrs.pop if attrs.last == ''
      [name, attrs]
    end
  end
end
