# frozen_string_literal: true

require 'minitest/autorun'
require 'dsv7/parser'

class Dsv7ValidatorFormatSyntaxTest < Minitest::Test
  def validate_string(content)
    Dsv7::Validator.validate(content)
  end

  def format_line(type = 'Wettkampfergebnisliste', version = '7')
    "FORMAT:#{type};#{version};"
  end

  def wk_minimal
    <<~DSV
      FORMAT:Wettkampfdefinitionsliste;7;
      ERZEUGER:Soft;1.0;mail@example.com;
      VERANSTALTUNG:Name;Ort;25;HANDZEIT;
      VERANSTALTUNGSORT:Schwimmstadion Duisburg-Wedau;Margaretenstr. 11;47055;Duisburg;GER;09999/11111;Kein Fax;;
      AUSSCHREIBUNGIMNETZ:;
      VERANSTALTER:Club;
      AUSRICHTER:SC Duisburg;Biene, Petra;Wabenstr. 69;47055;Duisburg;GER;0888/22222;0888/22223;PetraBiene@GibtsNicht.de;
      MELDEADRESSE:Kontakt;;;;;;;kontakt@example.com;
      MELDESCHLUSS:01.01.2024;12:00;
      ABSCHNITT:1;01.01.2024;;;10:00;;
      WETTKAMPF:1;V;1;;100;F;GL;M;SW;;;
      WERTUNG:1;V;1;JG;0;9999;;OFFENE WERTUNG;
      MELDEGELD:EINZELMELDEGELD;2,00;;
      DATEIENDE
    DSV
  end

  def vml_minimal
    <<~DSV
      FORMAT:Vereinsmeldeliste;7;
      ERZEUGER:Soft;1.0;mail@example.com;
      VERANSTALTUNG:Name;Ort;25;HANDZEIT;
      ABSCHNITT:1;01.01.2024;10:00;N;
      WETTKAMPF:1;V;1;;100;F;GL;M;;;
      VEREIN:Mein Verein;1234;17;GER;
      ANSPRECHPARTNER:Beispiel, Alice;;;;;;;alice@example.com;
      DATEIENDE
    DSV
  end

  def content_for_type(type)
    return wk_minimal if type == 'Wettkampfdefinitionsliste'
    return vml_minimal if type == 'Vereinsmeldeliste'

    "#{format_line(type)}\nDATA;ok\nDATEIENDE\n"
  end

  def test_all_allowed_list_types_accept
    types = %w[
      Wettkampfdefinitionsliste Vereinsmeldeliste
      Wettkampfergebnisliste Vereinsergebnisliste
    ]
    types.each do |type|
      result = validate_string(content_for_type(type))
      assert result.valid?, "Expected valid for #{type}: #{result.errors.inspect}"
    end
  end

  def test_format_missing_trailing_semicolon_errors
    content = "FORMAT:Wettkampfdefinitionsliste;7\nDATA;ok\nDATEIENDE\n"
    result = validate_string(content)
    msg = "First non-empty line must be 'FORMAT:<Listentyp>;7;' (line 1)"
    assert_includes result.errors, msg
  end

  def test_inline_comment_on_format_is_ok
    content = "#{format_line} (* inline *)\nDATA;ok\nDATEIENDE\n"
    result = validate_string(content)
    assert result.valid?, result.errors.inspect
  end

  def test_leading_trailing_spaces_on_keywords_are_ok
    content = "  #{format_line}  \nDATA;ok\n  DATEIENDE   \n"
    result = validate_string(content)
    assert result.valid?, result.errors.inspect
  end

  def test_lowercased_keywords_error
    content = "format:Wettkampfdefinitionsliste;7;\nDateIEnde\n"
    result = validate_string(content)
    msg = "First non-empty line must be 'FORMAT:<Listentyp>;7;' (line 1)"
    assert_includes result.errors, msg
    assert_includes result.errors, "Missing 'DATEIENDE' terminator line"
  end

  def test_dateiende_with_trailing_spaces_is_ok
    content = "#{format_line}\nDATA;ok\nDATEIENDE   \n"
    result = validate_string(content)
    assert result.valid?, result.errors.inspect
  end

  def test_missing_semicolon_on_data_line_errors
    content = "#{format_line}\nDATA\nDATEIENDE\n"
    result = validate_string(content)
    assert_includes result.errors, "Missing attribute delimiter ';' on line 2"
  end
end
