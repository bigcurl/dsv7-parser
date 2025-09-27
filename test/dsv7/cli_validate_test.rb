# frozen_string_literal: true

require_relative '../test_helper'
require 'minitest/autorun'
require 'open3'
require 'rbconfig'
require 'tmpdir'
require 'fileutils'
require_relative 'e2e_helpers'

class CliValidateTest < Minitest::Test
  include Dsv7E2EHelpers

  BIN_PATH = File.expand_path('../../bin/dsv7-validate', __dir__)
  RUBY = RbConfig.ruby

  def test_valid_file_exits_success
    Dir.mktmpdir do |dir|
      path = File.join(dir, '2024-01-01-Duisburg-Wk.DSV7')
      File.write(path, wkdl_minimal)

      stdout, stderr, status = Open3.capture3(RUBY, BIN_PATH, path)

      assert(status.success?, 'expected exit status 0')
      assert_empty(stderr)
      assert_empty(stdout)
    end
  end

  def test_invalid_file_reports_errors_and_nonzero_exit
    Dir.mktmpdir do |dir|
      path = File.join(dir, '2024-01-01-Duisburg-Wk.DSV7')
      File.write(path, <<~DSV)
        FORMAT:Wettkampfdefinitionsliste;7;
      DSV

      stdout, stderr, status = Open3.capture3(RUBY, BIN_PATH, path)

      refute(status.success?, 'expected non-zero exit status')
      assert_empty(stderr)
      assert_includes(stdout, 'ERROR:')
    end
  end

  def test_reads_from_stdin_when_dash_argument
    stdout, stderr, status = Open3.capture3(
      RUBY,
      BIN_PATH,
      '-',
      stdin_data: wkdl_minimal
    )

    assert(status.success?, 'expected exit status 0')
    assert_empty(stderr)
    assert_empty(stdout)
  end
end
