# Agent Guide for dsv7-parser

This repo contains a Ruby gem stub for parsing and validating DSV7 files (German Swimming Federation, “Format 7”). It already includes a high-level validator and a growing specification captured in Markdown.

## Repo Layout

- `lib/dsv7/validator.rb` — public entrypoint `Dsv7::Validator.validate(...)`
- `lib/dsv7/validator/core.rb` — core stream pipeline (BOM/encoding, line parsing)
- `lib/dsv7/validator/result.rb` — result container (`errors`, `warnings`, `valid?`)
- `lib/dsv7/parser.rb` — parser namespace and version loader
- `specification/dsv7/dsv7_specification.md` — cleaned, structured spec text
- `test/dsv7/*_test.rb` — Minitest suite covering validator behavior
- `Rakefile` — `rake test` (default), `rake rubocop`

## Dev Quick Start

- Install deps: `bundle install`
- Run tests: `bundle exec rake` (or `bundle exec rake test`)
- Run RuboCop: `bundle exec rake rubocop`

## Spec: “Allgemeines” (Key Rules)

From `specification/dsv7/dsv7_specification.md` → section “Allgemeines” and the general rules that impact top‑level validation:

- Scope and version
  - Standard for exchanging meet entries and results.
  - Current format is version `7`, effective from 2023‑01‑01; format 6 valid only until 2023‑07‑31.
- Encoding and separators
  - UTF‑8 without BOM.
  - Attribute delimiter is `;`.
  - No line breaks inside a single element.
- Comments
  - Syntax: `(* ... *)` (intended to be single‑line; inline allowed).
- File envelope
  - First effective line must be `FORMAT:<Listentyp>;7;`.
  - Last element is `DATEIENDE`.
- Allowed list types
  - `Wettkampfdefinitionsliste`, `Vereinsmeldeliste`, `Wettkampfergebnisliste`, `Vereinsergebnisliste`.
- Filenames
  - Pattern: `JJJJ-MM-TT-Ort-Zusatz.DSV7`.
  - `Ort`: remove spaces/hyphens; map umlauts `ä→ae`, `ö→oe`, `ü→ue`, `ß→ss`; max 8 chars.
  - `Zusatz`: `…-Me` (Vereinsmeldeliste), `…-Pr` (Vereinsergebnisliste), `Pr` (Wettkampfergebnisliste), `Wk` (Wettkampfdefinitionsliste).
- Datatypes (future schema validation)
  - ZK (string), Zeichen (char), Zahl (int), Zeit (`HH:MM:SS,hh`), Datum (`TT.MM.JJJJ`), Uhrzeit (`HH:MM`), Betrag (`x,yy`), JGAK variants.

## Current Validator Coverage (implemented)

- FORMAT line parsing and validation
  - Must be first effective line; exact syntax `FORMAT:<Listentyp>;7;`.
  - List type must be one of the four allowed types.
  - Version must be `7`.
- Terminator
  - `DATEIENDE` must be present; no effective content after it.
- Encoding and line endings
  - Detects UTF‑8 BOM (errors); validates UTF‑8 and scrubs invalid input (reports error).
  - Detects CRLF present anywhere (adds a warning) — still considered valid.
- Comments and delimiters
  - Inline comments `(* ... *)` are stripped for checks.
  - Unbalanced comment delimiters on any single line are errors.
  - Every non‑empty, non‑comment data line after FORMAT must contain at least one `;`.
- Filenames
  - When validating by path, warns if the filename does not match `^\d{4}-\d{2}-\d{2}-[^.]+\.DSV7$`.

What is not implemented yet: element‑level schemas; datatype checking; normalization of `Ort`/`Zusatz` pieces beyond the filename pattern warning; full cross‑element ordering/refs.

## Minimal Valid Example

```
FORMAT:Wettkampfdefinitionsliste;7;
DATA;ok
DATEIENDE
```

Notes:
- Leading/trailing spaces around `FORMAT`/`DATEIENDE` are tolerated.
- Inline comments are allowed, e.g. `FORMAT:... (* note *)`.

## Tests Overview and Conventions

- Location: `test/dsv7/` using Minitest.
- Common helpers in tests:
  - `format_line(type = 'Wettkampfdefinitionsliste', version = '7')`
  - `validate_string(content)` → `Dsv7::Validator.validate(content)`
- Existing coverage slices:
  - `validator_test.rb` — happy‑path and envelope errors.
  - `validator_format_syntax_test.rb` — FORMAT syntax, list types, whitespace.
  - `validator_comments_test.rb` — comment stripping and balance checks.
  - `validator_encoding_test.rb` — BOM/UTF‑8/CRLF behaviors.
  - `validator_filename_test.rb` — filename pattern warnings.
  - `validator_whitespace_test.rb` — empty and comment‑only files.

## Suggested Next Steps

- Add unit tests mapping more of “Allgemeines” and adjacent sections:
  - Explicit checks for “no content after DATEIENDE” (already present), and acceptance of comment‑only lines after it.
  - Additional filename examples from the spec (umlaut mappings, max length, numbering `Ort1`, `Ort2`).
  - Datatype conformance tests as scaffolding for future element‑schema validation.
- Implement element schema parsing (SAX‑style) to validate attributes and datatypes.

# Coding Guidelines for dsv7-parser

Concise conventions for contributing code and tests to this repo. Focus is on a small, dependency‑light Ruby library with a streaming validator and Minitest suite.

## Language & Versions

- Ruby version: `2.7.0` in `.ruby-version`; gem supports `>= 2.7` (see `dsv7-parser.gemspec`).
- Add `# frozen_string_literal: true` to the top of Ruby files.
- Avoid non‑portable syntax not available in Ruby 2.7.

## Style & Linting

- Use RuboCop; run `bundle exec rake rubocop`.
- Write both library code and tests in a RuboCop‑compliant way; fix all offenses before submitting.
- Do not change `.rubocop.yml` to satisfy offenses; fix the code instead.
- Avoid inline `# rubocop:disable` comments; refactor to comply where possible.
- New cops enabled; line length max `100` (see `.rubocop.yml`).
- `Metrics/BlockLength` is relaxed for `Rakefile` and `test/**/*`.
- `Style/Documentation` disabled (no mandatory class/module docs).
- String literals: prefer single quotes; use double quotes when interpolation/escapes are needed.
- Keep methods small and cohesive; favor clear names over brevity.
 - Names: prefer full words for variables and methods; avoid abbreviations (e.g., use `line_number` not `line_no`, `add_error` not `add_err`).

## Structure & Namespacing

- Place code under `lib/dsv7/` and namespace under `Dsv7`.
- Keep validator pipeline pieces encapsulated:
  - `Dsv7::Validator` (public API, orchestration)
  - `Dsv7::Validator::Core` (streaming + encoding + lines)
  - `Dsv7::Validator::Result` (errors/warnings container)
- Keep responsibilities narrow; prefer small classes/modules over large monoliths.

## Public API Expectations

- Single entrypoint: `Dsv7::Validator.validate(input)` supports IO, file path, or content String.
- Raise `ArgumentError` for unsupported input types.
- Do not print to stdout/stderr in library code; communicate via return values.

## Errors, Warnings, Messages

- Use precise, user‑actionable wording; match existing phrasing where possible.
- Errors go to `result.errors`; warnings to `result.warnings`.
- Include context when helpful (e.g., line numbers); keep format stable for tests.

## IO & Encoding

- Stream inputs (avoid loading entire files); set `io.binmode`.
- Detect and report UTF‑8 BOM; enforce UTF‑8 with `force_encoding` and `valid_encoding?`.
- Preserve processing order; support both LF and CRLF, adding a single warning for CRLF presence.

## Performance & Memory

- Use streaming and incremental processing wherever possible (enumerate by line).
- Optimize for low memory usage (avoid reading whole files or accumulating large arrays).
- Prefer single‑pass algorithms; keep per‑line state minimal and discard intermediate buffers.

## Comments and Parsing Rules

- Treat `(* ... *)` as inline comments and strip before structural checks.
- Ensure balanced comment delimiters on each line.
- For non‑empty, non‑comment data lines (after `FORMAT`), require at least one `;` delimiter.

## Testing Conventions

- Framework: Minitest; tests live under `test/dsv7/` with `_test.rb` suffix.
- Helpers used commonly:
  - `format_line(type = 'Wettkampfdefinitionsliste', version = '7')`
  - `validate_string(content)` → `Dsv7::Validator.validate(content)`
- Use tmp files for filename tests; clean them in `ensure` blocks.
- Assertions: prefer `assert_includes`, `assert_empty`, and `assert result.valid?` for clarity.

## Tooling

- Install deps: `bundle install`
- Run tests: `bundle exec rake` (default task)
- Lint: `bundle exec rake rubocop`

## Finish Checklist

- Run tests: `rake test` (or `bundle exec rake test`).
- Auto-correct style: `rubocop -A .` (or `bundle exec rubocop -A .`).
- Fix any remaining RuboCop items; re-run `rake test` and `rubocop` until green.
- If you add a new feature or public API, update `README.md` with usage and examples.

## Repo Quick Reference (Appendix)

- `lib/dsv7/validator.rb` — public entrypoint `Dsv7::Validator.validate(...)`
- `lib/dsv7/validator/core.rb` — core stream pipeline (BOM/encoding, line parsing)
- `lib/dsv7/validator/result.rb` — result container (`errors`, `warnings`, `valid?`)
- `lib/dsv7/parser.rb` — parser namespace and version loader
- `specification/dsv7/dsv7_specification.md` — structured spec text
- `test/dsv7/*_test.rb` — Minitest suite
- `Rakefile` — `rake test` (default), `rake rubocop`

Spec notes driving current validator behavior (from “Allgemeines”): require `FORMAT:<Listentyp>;7;`, final `DATEIENDE`, UTF‑8 without BOM, inline comment handling, semicolon on data lines, allowed list types, and filename pattern warnings.

## Patch Discipline

- Keep diffs minimal and targeted; avoid unrelated refactors.
- Do not reformat whole files; only touch necessary lines.
- Don’t add license headers or banners.
- Avoid inline code comments unless explicitly requested.
- Use descriptive names; avoid one‑letter variables.
- Prefer full-length, intent-revealing variable names; avoid abbreviations (e.g., `line_number` not `line_no`).

## Error/Warning Policy

- Errors invalidate the file; warnings do not affect `valid?`.
- Include line numbers when relevant; keep message text stable.
- Prefer new checks as additional messages over changing existing texts.
- For non‑normative guidance, favor warnings instead of errors.

## Dependency Policy

- Keep runtime dependencies at zero; prefer stdlib.
- Discuss before adding any new gem (including dev‑only).
- Maintain streaming design and dependency‑light footprint.

## API Stability

- Do not change `Dsv7::Validator.validate` signature or return type.
- `Result#valid?` is based solely on presence of errors.
- Expose new information via additional fields/methods with tests.

## Test Matrix Expectations

- Add both accept and reject tests for each new rule.
- Cover LF and CRLF, whitespace quirks, comments, UTF‑8 edge cases.
- Test both string and file‑path inputs (use `tmp` and cleanup in `ensure`).
- Prefer precise assertions (`assert_includes`, `assert_empty`, `assert result.valid?`).
- Keep tests independent, small, and fast.
