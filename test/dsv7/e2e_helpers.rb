# frozen_string_literal: true

module Dsv7E2EHelpers
  def setup
    FileUtils.mkdir_p('tmp')
  end

  def validate_string(content)
    Dsv7::Validator.validate(content)
  end

  def parse_for_list_type(list_type, input)
    map = {
      'Wettkampfdefinitionsliste' => Dsv7::Parser.method(:parse_wettkampfdefinitionsliste),
      'Vereinsmeldeliste' => Dsv7::Parser.method(:parse_vereinsmeldeliste),
      'Wettkampfergebnisliste' => Dsv7::Parser.method(:parse_wettkampfergebnisliste),
      'Vereinsergebnisliste' => Dsv7::Parser.method(:parse_vereinsergebnisliste)
    }
    raise ArgumentError, "Unknown list type: #{list_type}" unless map[list_type]

    map[list_type].call(input)
  end

  def wkdl_minimal
    <<~DSV
      (* header comment *)
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
      (* header comment *)
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

  def erg_minimal
    <<~DSV
      (* header comment *)
      FORMAT:Wettkampfergebnisliste;7;
      ERZEUGER:Soft;1.0;mail@example.com;
      VERANSTALTUNG:Name;Ort;25;HANDZEIT;
      VERANSTALTER:Club;
      AUSRICHTER:SC Duisburg;Biene, Petra;Wabenstr. 69;47055;Duisburg;GER;0888/22222;0888/22223;PetraBiene@GibtsNicht.de;
      ABSCHNITT:1;01.01.2024;10:00;N;
      WETTKAMPF:1;A;1;;100;F;GL;M;SW;;;
      WERTUNG:1;V;1;JG;0;;;OFFEN;
      VEREIN:SV Hansa Adorf;1234;17;GER;
      DATEIENDE
    DSV
  end

  def vrl_minimal
    <<~DSV
      (* header comment *)
      FORMAT:Vereinsergebnisliste;7;
      ERZEUGER:Soft;1.0;mail@example.com;
      VERANSTALTUNG:Name;Ort;25;HANDZEIT;
      VERANSTALTER:Club;
      AUSRICHTER:SC Duisburg;Biene, Petra;Wabenstr. 69;47055;Duisburg;GER;0888/22222;0888/22223;PetraBiene@GibtsNicht.de;
      ABSCHNITT:1;01.01.2024;10:00;N;
      WETTKAMPF:1;A;1;;100;F;GL;M;SW;;;
      WERTUNG:1;V;1;JG;0;;;OFFEN;
      VEREIN:SV Hansa Adorf;1234;17;GER;
      DATEIENDE
    DSV
  end

  def assert_format(events, expected_list_type)
    fmt = events.first
    assert_equal :format, fmt[0]
    assert_equal expected_list_type, fmt[1][:list_type]
    assert_equal '7', fmt[1][:version]
  end

  def assert_has_element_and_end(events)
    assert(events.any? { |e| e[0] == :element })
    assert_equal :end, events.last[0]
  end

  def assert_parses_minimally(enum, expected_list_type)
    events = enum.to_a
    refute_empty events
    assert_format(events, expected_list_type)
    assert_has_element_and_end(events)
  end
end
