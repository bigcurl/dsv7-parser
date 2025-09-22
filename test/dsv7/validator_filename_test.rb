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

  def assert_filename_ok(path, list_type)
    File.write(path, "FORMAT:#{list_type};7;\nDATEIENDE\n")
    result = Dsv7::Validator.validate(path)
    assert_empty result.warnings, "Expected no filename warnings for #{File.basename(path)}"
    assert result.valid?
  ensure
    FileUtils.rm_f(path)
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

  def test_filename_examples_from_spec_are_accepted
    [
      ['tmp/2001-12-16-Berlin-Pr.DSV7', 'Wettkampfergebnisliste'],
      ['tmp/2001-12-16-Muenster-Pr.DSV7', 'Wettkampfergebnisliste'],
      ['tmp/2001-12-16-Frankfur-Pr.DSV7', 'Wettkampfergebnisliste']
    ].each { |path, type| assert_filename_ok(path, type) }
  end

  def test_ort_numbering_variants_are_accepted
    [
      ['tmp/2025-09-22-Berlin1-Wk.DSV7', 'Wettkampfdefinitionsliste'],
      ['tmp/2025-09-22-Berlin2-Me.DSV7', 'Vereinsmeldeliste']
    ].each { |path, type| assert_filename_ok(path, type) }
  end

  def test_filename_ort_umlaut_normalization_examples_accepted
    %w[Muenchen Koeln Duesseldorf GrossGerau].each do |ort|
      path = "tmp/2025-09-22-#{ort}-Wk.DSV7"
      assert_filename_ok(path, 'Wettkampfdefinitionsliste')
    end
  end

  def test_filename_zusatz_umlaut_normalization_examples_accepted
    %w[
      SCMuenchen-Me SSVKoeln-Me SchwimmfreundeDuesseldorf-Me TSVGrossGerau-Me
    ].each do |zusatz|
      path = "tmp/2025-09-22-Berlin-#{zusatz}.DSV7"
      assert_filename_ok(path, 'Vereinsmeldeliste')
    end
  end
end
