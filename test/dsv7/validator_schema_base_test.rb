# frozen_string_literal: true

require_relative '../test_helper'
require 'minitest/autorun'
require 'dsv7/parser'

class Dsv7ValidatorSchemaBaseTest < Minitest::Test
  def setup
    @result = Dsv7::Validator::Result.new
  end

  def test_unknown_element_is_ignored
    schema = Dsv7::Validator::VmlSchema.new(@result)
    schema.validate_element('UNKNOWN', %w[a b c], 5)
    assert_empty @result.errors
  end

  def test_attribute_count_mismatch_adds_error
    schema = Dsv7::Validator::VmlSchema.new(@result)
    # ERZEUGER expects 3 attributes
    schema.validate_element('ERZEUGER', %w[a], 7)
    assert_includes @result.errors,
                    "Element ERZEUGER: expected 3 attributes, got 1 (line 7)"
  end

  def test_attribute_count_match_and_type_checks_ok
    schema = Dsv7::Validator::VmlSchema.new(@result)
    schema.validate_element('ERZEUGER', %w[Soft 1.0 mail@example.com], 3)
    assert_empty @result.errors
  end

  def test_required_attribute_missing_reports_error
    schema = Dsv7::Validator::VmlSchema.new(@result)
    # ERZEUGER has 3 required attributes; empty strings trigger required check
    schema.validate_element('ERZEUGER', ['', '', ''], 10)
    assert_includes @result.errors,
                    'Element ERZEUGER: missing required attribute 1 (line 10)'
    assert_includes @result.errors,
                    'Element ERZEUGER: missing required attribute 2 (line 10)'
    assert_includes @result.errors,
                    'Element ERZEUGER: missing required attribute 3 (line 10)'
  end

  def test_optional_attribute_empty_is_accepted
    schema = Dsv7::Validator::VmlSchema.new(@result)
    # ABSCHNITT has 4th attribute optional (:relativ)
    schema.validate_element('ABSCHNITT', %w[1 01.01.2024 10:00], 12)
    # count mismatch will not happen because 3 provided for 4 expected, so add the optional as empty
    # (ensure count is correct and optional empty is skipped)
    @result = Dsv7::Validator::Result.new
    schema = Dsv7::Validator::VmlSchema.new(@result)
    schema.validate_element('ABSCHNITT', ['1', '01.01.2024', '10:00', ''], 12)
    assert_empty @result.errors
  end

  def test_type_check_invoked_and_reports_invalid
    schema = Dsv7::Validator::VmlSchema.new(@result)
    # STARTPN expects Zahl; provide invalid to trigger check_zahl
    schema.validate_element('STARTPN', ['x', '2', '01:23:45,67'], 15)
    assert_includes @result.errors,
                    "Element STARTPN, attribute 1: invalid Zahl 'x' (line 15)"
  end

  def test_cross_rules_invoked_for_wk_schema
    result = Dsv7::Validator::Result.new
    schema = Dsv7::Validator::WkSchema.new(result)
    # WKMELDEGELD requires Wettkampfnr (attr 3)
    schema.validate_element('MELDEGELD', ['WKMELDEGELD', '2,00', ''], 22)
    assert_includes result.errors,
                    "Element MELDEGELD: 'WKMELDEGELD' requires Wettkampfnr (attr 3) (line 22)"
  end
end
