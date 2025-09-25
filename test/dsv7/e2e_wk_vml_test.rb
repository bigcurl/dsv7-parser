# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../test_helper'
require 'fileutils'
require 'dsv7/parser'
require_relative 'e2e_helpers'

class Dsv7E2EWkVmlTest < Minitest::Test
  include Dsv7E2EHelpers

  def test_e2e_wkdl_validate_then_parse
    content = wkdl_minimal
    result = validate_string(content)
    assert result.valid?, "Expected valid, errors: #{result.errors.inspect}"
    enum = parse_for_list_type(result.list_type, content)
    assert_parses_minimally(enum, 'Wettkampfdefinitionsliste')
  end

  def test_e2e_vml_validate_then_parse
    content = vml_minimal
    result = validate_string(content)
    assert result.valid?, "Expected valid, errors: #{result.errors.inspect}"
    enum = parse_for_list_type(result.list_type, content)
    assert_parses_minimally(enum, 'Vereinsmeldeliste')
  end
end
