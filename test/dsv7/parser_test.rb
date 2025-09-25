# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../test_helper'
require 'dsv7/parser'

class Dsv7ParserTest < Minitest::Test
  def test_version_number_exists
    refute_nil Dsv7::Parser::VERSION
  end

  def test_parser_namespace_is_defined
    assert defined?(Dsv7::Parser)
  end
end
