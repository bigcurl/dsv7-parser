# frozen_string_literal: true

require 'minitest/autorun'
require 'fileutils'
require 'dsv7/parser'

class Dsv7ValidatorFilenameTest < Minitest::Test
  def setup
    FileUtils.mkdir_p('tmp')
  end

  def format_line(type = 'Wettkampfdefinitionsliste', version = '7')
    "FORMAT:#{type};#{version};"
  end

  def test_filename_pattern_warning
    path = 'tmp/badname.txt'
    File.write(path, "#{format_line}\nDATEIENDE\n")
    result = Dsv7::Validator.validate(path)
    msg = "Filename 'badname.txt' does not follow 'JJJJ-MM-TT-Ort-Zusatz.DSV7'"
    assert_includes result.warnings, msg
    assert result.valid?
  ensure
    FileUtils.rm_f(path)
  end

  def test_filename_pattern_conforming_has_no_warning
    path = 'tmp/2025-09-22-Berlin-Wk.DSV7'
    File.write(path, "#{format_line}\nDATEIENDE\n")
    result = Dsv7::Validator.validate(path)
    assert_empty result.warnings
    assert result.valid?
  ensure
    FileUtils.rm_f(path)
  end
end
