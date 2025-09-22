# dsv7-parser

Ruby gem stub for a SAX parser targeting the DSV7 swim file format.

## Specification

- DSV-Standard zur Datenübermittlung "Format 7" (external, DE): https://www.dsv.de/de/service/formulare/schwimmen/

## Validator

Basic high-level validation of DSV7 files is available:

```
require 'dsv7/parser'

# Single entrypoint: pass a path, IO, or a string with file content
result = Dsv7::Validator.validate('path/to/file.DSV7')
puts "valid? #{result.valid?}"
puts "list_type: #{result.list_type}, version: #{result.version}"
puts "errors:   #{result.errors.inspect}"
puts "warnings: #{result.warnings.inspect}"

# Example with string content
content = "FORMAT:Wettkampfdefinitionsliste;7;\nDATA;ok\nDATEIENDE\n"
result2 = Dsv7::Validator.validate(content)
```

Checks include:

- FORMAT line at top (`FORMAT:<Listentyp>;7;`), with known list types
- UTF-8 without BOM
- Inline/standalone comment delimiters `(* ... *)` are balanced per line
- Non-comment data lines contain at least one `;` delimiter
- Terminator `DATEIENDE` present and last

## Parser (Wettkampfdefinitionsliste)

The parser currently provides a streaming API for Wettkampfdefinitionsliste (WKDL) files. It is tolerant and focuses on extracting elements efficiently; use the validator for strict checks.

Key points:

- Input: pass a file path, an IO, or a String with file content.
- Yields events: `:format`, `:element`, `:end` along with payload and line number.
- Strips inline comments `(* ... *)` and scrubs invalid UTF‑8 in lines.
- Accepts UTF‑8 with or without BOM (validator will still report BOM as an error).

Basic example (block style):

```
require 'dsv7/parser'

content = <<~DSV
  (* header comment *)
  FORMAT:Wettkampfdefinitionsliste;7;
  ERZEUGER:Soft;1.0;mail@example.com;
  VERANSTALTUNG:Name;Ort;25;HANDZEIT; (* inline *)
  MELDESCHLUSS:01.01.2024;12:00;
  DATEIENDE
DSV

Dsv7::Parser.parse_wettkampfdefinitionsliste(content) do |type, payload, line_number|
  case type
  when :format
    # { list_type: 'Wettkampfdefinitionsliste', version: '7' }
    p [:format, payload, line_number]
  when :element
    # { name: 'ERZEUGER', attrs: ['Soft','1.0','mail@example.com'] }
    p [:element, payload, line_number]
  when :end
    p [:end, line_number]
  end
end
```

Enumerator style:

```
enum = Dsv7::Parser.parse_wettkampfdefinitionsliste('path/to/2002-03-10-Duisburg-Wk.DSV7')
enum.each do |type, payload, line_number|
  # same triplets as the block example
end
```

Building a simple structure (header + elements) from the stream:

```
data = { format: nil, elements: [] }

Dsv7::Parser.parse_wettkampfdefinitionsliste(content) do |type, payload, line_number|
  case type
  when :format
    data[:format] = payload # { list_type: 'Wettkampfdefinitionsliste', version: '7' }
  when :element
    data[:elements] << { name: payload[:name], attrs: payload[:attrs], line_number: line_number }
  end
end

# Example: pick only WETTKAMPF rows
wettkaempfe = data[:elements]
  .select { |e| e[:name] == 'WETTKAMPF' }
  .map { |e| e[:attrs] } # arrays of attributes per row
```

Combining validation with parsing:

```
result = Dsv7::Validator.validate('path/to/file.DSV7')
if result.valid?
  Dsv7::Parser.parse_wettkampfdefinitionsliste('path/to/file.DSV7') do |type, payload, line_number|
    # consume events
  end
else
  warn "Invalid DSV7: #{result.errors.join('; ')}"
end
```

Errors and edge cases:

- Raises `Dsv7::Parser::Error` if the first effective line is not a `FORMAT` line.
- Raises `Dsv7::Parser::Error` if the list type is not `Wettkampfdefinitionsliste`.
- Stops at `DATEIENDE`. Whitespace/comments after `DATEIENDE` are ignored by the parser (validator permits only comments/whitespace after it).

## Development

- Tests use Minitest and live under `test/dsv7/`.
- Version is defined in `lib/dsv7/parser/version.rb`.
