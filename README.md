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

## Development

- Tests use Minitest and live under `test/dsv7/`.
- Version is defined in `lib/dsv7/parser/version.rb`.
