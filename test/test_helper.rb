# frozen_string_literal: true

# Ensure local lib is on the load path when running tests directly
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

begin
  require 'simplecov'
  # Normalize the command name to a single bucket so merges are consistent
  SimpleCov.command_name 'Unit Tests'
  SimpleCov.start do
    # Collect line coverage for reliable per-file stats
    enable_coverage :line
    add_filter %r{^/test/}
    add_filter %r{^/specification/}
    add_filter %r{^/tmp/}
  end
rescue LoadError
  # SimpleCov not available (e.g., without dev/test gems); run tests without coverage
end
