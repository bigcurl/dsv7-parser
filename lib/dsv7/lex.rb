# frozen_string_literal: true

module Dsv7
  module Lex
    module_function

    # Parses a FORMAT line. Returns [list_type, version] or nil if not a FORMAT line.
    def parse_format(line)
      m = line.match(/^FORMAT:([^;]+);([^;]+);$/)
      return nil unless m

      [m[1], m[2]]
    end

    # Splits an element content line into name and attributes.
    # Returns [name, attrs] or nil if the line is not an element line.
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
