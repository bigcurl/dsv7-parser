# TODO

* Cardinalities are all in one file (lib/dsv7/validator/cardinality.rb). Split by list type (e.g., wk_cardinality.rb, vml_cardinality.rb, …) to keep files small and grep‑friendly.

- Standardize error/warning phrasing to always include attribute and line numbers

- Extracting allowed enum sets to named constants to reuse across modules

- Add- Add a tiny unit test for Lex.element edge cases (e.g., multiple trailing ;, empty attributes in the middle) to lock in splitting semantics.

- Parser resource handling test: add a test that parses a file path and verifies the   underlying File is closed after enumeration.

- In README.md, add a short “Supported validations” matrix per list type (what’s checked today vs. planned).

- Add fuzz/robustness slices around:
  Extremely long lines and many inline comments on a single line.

- Garbage bytes mixed into attributes (parser should still emit sanitized attributes; validator should flag encoding).

- Add a tiny CLI (bin/dsv7-validate) that reads from a path/stdin and prints errors/warnings. It improves adoption and makes quick checks easy.

- Remove Gemfile.lock from VCS for a library gem.
