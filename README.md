# dsv7-parser

Ruby gem stub for a SAX parser targeting the DSV7 swim file format.

## Specification

- DSV-Standard zur Datenübermittlung "Format 7" (external, DE): https://www.dsv.de/de/service/formulare/schwimmen/

## Validator

Basic and WKDL‑aware validation of DSV7 files is available via one entrypoint:

```
require 'dsv7/parser'

# Pass a path, IO, or a String with file content
result = Dsv7::Validator.validate('path/to/file.DSV7')

puts "valid?     #{result.valid?}"
puts "list_type: #{result.list_type}"
puts "version:   #{result.version}"
puts "errors:    #{result.errors.inspect}"
puts "warnings:  #{result.warnings.inspect}"
```

Accepted inputs:

- File path String: streamed from disk
- IO object (e.g., `File.open` or `StringIO`): streamed
- Content String: streamed via `StringIO`

Structural checks (all list types):

- First effective line is `FORMAT:<Listentyp>;7;` (whitespace tolerated)
- List type is one of: `Wettkampfdefinitionsliste`, `Vereinsmeldeliste`,
  `Wettkampfergebnisliste`, `Vereinsergebnisliste`
- UTF‑8 encoding, BOM detection (BOM is an error)
- Inline comments `(* ... *)` stripped; unbalanced `(*`/`*)` on a line is an error
- Non‑empty data lines after FORMAT must contain at least one `;`
- Terminator `DATEIENDE` present; no effective content after it

Filename guidance (when validating by path):

- Warns if the filename does not match `JJJJ-MM-TT-Ort-Zusatz.DSV7`

Minimal example (generic list type):

```
content = <<~DSV
  FORMAT:Vereinsmeldeliste;7;
  DATA;ok
  DATEIENDE
DSV

result = Dsv7::Validator.validate(content)
puts result.valid? # => true
```

Wettkampfdefinitionsliste validation (cardinality + attribute types):

```
wkdl = <<~DSV
  FORMAT:Wettkampfdefinitionsliste;7;
  ERZEUGER:Soft;1.0;mail@example.com;
  VERANSTALTUNG:Name;Ort;25;HANDZEIT;
  VERANSTALTUNGSORT:Schwimmstadion;Strasse;12345;Ort;GER;tel;fax;mail@ex.amp.le;
  AUSSCHREIBUNGIMNETZ:;
  VERANSTALTER:Club;
  AUSRICHTER:Verein;Kontakt;;;Ort;GER;;;kontakt@example.com;
  MELDEADRESSE:Kontakt;;;;;;;kontakt@example.com;
  MELDESCHLUSS:01.01.2024;12:00;
  ABSCHNITT:1;01.01.2024;;;10:00;;
  WETTKAMPF:1;V;1;;100;F;GL;M;SW;;;
  MELDEGELD:EINZELMELDEGELD;2,00;;
  DATEIENDE
DSV

wk_result = Dsv7::Validator.validate(wkdl)
puts wk_result.valid?      # => true
puts wk_result.errors      # => []
puts wk_result.warnings    # => []
```

Common error and warning examples:

```
# 1) Unknown list type and missing DATEIENDE
bad = "FORMAT:Unbekannt;7;\n"
r = Dsv7::Validator.validate(bad)
r.errors.include?("Unknown list type in FORMAT: 'Unbekannt'")
r.errors.include?("Missing 'DATEIENDE' terminator line")

# 2) Unsupported version
r = Dsv7::Validator.validate("FORMAT:Vereinsergebnisliste;6;\nDATEIENDE\n")
r.errors.include?("Unsupported format version '6', expected '7'")

# 3) Unbalanced comment delimiters
r = Dsv7::Validator.validate("FORMAT:Vereinsmeldeliste;7; (* open\nDATEIENDE\n")
r.errors.any? { |e| e.include?('Unmatched comment delimiters on line') }

# 4) CRLF detection (warning only)
crlf = "FORMAT:Vereinsmeldeliste;7;\r\nDATEIENDE\r\n"
r = Dsv7::Validator.validate(crlf)
r.valid?          # => true
r.warnings        # => ['CRLF line endings detected']

# 5) Missing delimiter ';' in a data line
r = Dsv7::Validator.validate("FORMAT:Vereinsmeldeliste;7;\nDATA no semicolon\nDATEIENDE\n")
r.errors.include?("Missing attribute delimiter ';' on line 2")

# 6) Filename pattern warning
File.write('tmp/badname.txt', "FORMAT:Vereinsmeldeliste;7;\nDATEIENDE\n")
begin
  r = Dsv7::Validator.validate('tmp/badname.txt')
  r.warnings.first.include?("does not follow 'JJJJ-MM-TT-Ort-Zusatz.DSV7'")
ensure
  File.delete('tmp/badname.txt')
end
```

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
