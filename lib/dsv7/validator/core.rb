# frozen_string_literal: true

require 'date'
require_relative '../stream'
require_relative '../lex'

module Dsv7
  class Validator
    # Core pipeline for validator: encoding + line parsing
    class Core
      def initialize(result, filename)
        @result = result
        @filename = filename
        @element_counts = Hash.new(0)
      end

      def call_io(io)
        io.binmode
        check_bom_and_rewind(io)
        process_lines(io)
      end

      private

      def check_bom_and_rewind(io)
        bom = Dsv7::Stream.read_bom?(io)
        @result.add_error('UTF-8 BOM detected (spec requires UTF-8 without BOM)') if bom
      end

      def sanitize_line(raw_line)
        Dsv7::Stream.sanitize_line(
          raw_line,
          on_invalid: -> { @result.add_error('File is not valid UTF-8 encoding') }
        )
      end

      def process_lines(io)
        analyzer = LineAnalyzer.new(@result)
        had_crlf = iterate(io) { |line, line_number| analyzer.process_line(line, line_number) }
        @result.add_warning('CRLF line endings detected') if had_crlf
        analyzer.finish
        check_filename(@filename)
        @result
      end

      def iterate(io, &block)
        Dsv7::Stream.each_sanitized_line(
          io,
          on_invalid: -> { @result.add_error('File is not valid UTF-8 encoding') }
        ) do |line, line_number|
          block.call(line, line_number)
        end
      end

      def check_filename(filename)
        return if filename.nil?
        return if filename.match(/^\d{4}-\d{2}-\d{2}-[^.]+\.DSV7$/)

        @result.add_warning(
          "Filename '#{filename}' does not follow 'JJJJ-MM-TT-Ort-Zusatz.DSV7'"
        )
      end
    end

    # Handles line-by-line structural checks
    # Shared helpers extracted from LineAnalyzer to keep class small
    module LineAnalyzerWk
      def track_wk_element(trimmed)
        return unless @result.list_type == 'Wettkampfdefinitionsliste'

        pair = Dsv7::Lex.element(trimmed)
        return unless pair

        name, = pair
        return if name == 'FORMAT'
        return if name == 'DATEIENDE'

        @wk_elements[name] += 1
      end

      def validate_wk_list_elements
        WkCardinality.new(@result, @wk_elements).validate!
      end

      def validate_wk_line(trimmed, line_number)
        return unless @result.list_type == 'Wettkampfdefinitionsliste'

        pair = Dsv7::Lex.element(trimmed)
        return unless pair

        name, attrs = pair
        return if %w[FORMAT DATEIENDE].include?(name)

        @wk_schema.validate_element(name, attrs, line_number)
      end
    end

    module LineAnalyzerVml
      def track_vml_element(trimmed)
        return unless @result.list_type == 'Vereinsmeldeliste'

        pair = Dsv7::Lex.element(trimmed)
        return unless pair

        name, = pair
        return if name == 'FORMAT'
        return if name == 'DATEIENDE'

        @vml_elements[name] += 1
      end

      def validate_vml_list_elements
        VmlCardinality.new(@result, @vml_elements).validate!
      end

      def validate_vml_line(trimmed, line_number)
        return unless @result.list_type == 'Vereinsmeldeliste'

        pair = Dsv7::Lex.element(trimmed)
        return unless pair

        name, attrs = pair
        return if %w[FORMAT DATEIENDE].include?(name)

        @vml_schema.validate_element(name, attrs, line_number)
      end
    end

    class LineAnalyzer
      include LineAnalyzerWk
      include LineAnalyzerVml

      def initialize(result)
        @result = result
        @effective_index = 0
        @format_line_index = nil
        @dateiende_index = nil
        @after_dateiende_effective_line_number = nil
        @wk_elements = Hash.new(0)
        @wk_schema = WkSchema.new(@result)
        @vml_elements = Hash.new(0)
        @vml_schema = VmlSchema.new(@result)
      end

      def process_line(line, line_number)
        check_comment_balance(line, line_number)
        trimmed = strip_inline_comment(line)
        return if trimmed.empty?

        @effective_index += 1
        return handle_first_effective(trimmed, line_number) if @effective_index == 1
        return @dateiende_index = line_number if trimmed == 'DATEIENDE'

        handle_content_line(trimmed, line_number)
      end

      def finish
        post_validate_positions
        validate_wk_list_elements if @result.list_type == 'Wettkampfdefinitionsliste'
        validate_vml_list_elements if @result.list_type == 'Vereinsmeldeliste'
      end

      private

      def check_comment_balance(line, line_number)
        return unless line.include?('(*') || line.include?('*)')

        opens = line.scan('(*').size
        closes = line.scan('*)').size
        return unless opens != closes

        @result.add_error("Unmatched comment delimiters on line #{line_number}")
      end

      def handle_first_effective(trimmed, line_number)
        @format_line_index = line_number
        check_format_line(trimmed, line_number)
      end

      def strip_inline_comment(line)
        Dsv7::Stream.strip_inline_comment(line).strip
      end

      def check_format_line(trimmed, line_number)
        m = Dsv7::Lex.parse_format(trimmed)
        msg = "First non-empty line must be 'FORMAT:<Listentyp>;7;' (line #{line_number})"
        return @result.add_error(msg) unless m

        lt, ver = m
        # Enforce numeric version token for exact syntax compatibility
        return @result.add_error(msg) unless ver.match?(/^\d+$/)

        @result.set_format(lt, ver)
        @result.add_error("Unknown list type in FORMAT: '#{lt}'") unless
          Validator::ALLOWED_LIST_TYPES.include?(lt)
        @result.add_error("Unsupported format version '#{ver}', expected '7'") unless ver == '7'
      end

      def require_semicolon(trimmed, line_number)
        return if trimmed.include?(';')

        @result.add_error("Missing attribute delimiter ';' on line #{line_number}")
      end

      def post_validate_positions
        @result.add_error('Missing FORMAT line at top of file') if @format_line_index.nil?
        return @result.add_error("Missing 'DATEIENDE' terminator line") if @dateiende_index.nil?

        return unless @after_dateiende_effective_line_number

        n = @after_dateiende_effective_line_number
        @result.add_error("Content found after 'DATEIENDE' (line #{n})")
      end

      def remove_inline_comments(line)
        Dsv7::Stream.strip_inline_comment(line)
      end

      def handle_content_line(trimmed, line_number)
        @after_dateiende_effective_line_number ||= line_number if @dateiende_index
        require_semicolon(trimmed, line_number)
        track_wk_element(trimmed)
        track_vml_element(trimmed)
        validate_wk_line(trimmed, line_number)
        validate_vml_line(trimmed, line_number)
      end
    end

    # Validates Wettkampfdefinitionsliste element cardinalities
    class WkCardinality
      def initialize(result, wk_elements)
        @result = result
        @wk_elements = wk_elements
      end

      def validate!
        require_exactly_one(
          %w[ERZEUGER VERANSTALTUNG VERANSTALTUNGSORT AUSSCHREIBUNGIMNETZ
             VERANSTALTER AUSRICHTER MELDEADRESSE MELDESCHLUSS]
        )
        forbid_more_than_one(%w[BANKVERBINDUNG BESONDERES NACHWEIS])
        require_at_least_one(%w[ABSCHNITT WETTKAMPF MELDEGELD])
      end

      private

      def require_exactly_one(elements)
        elements.each do |el|
          count = @wk_elements[el]
          if count.zero?
            @result.add_error("Wettkampfdefinitionsliste: missing required element '#{el}'")
          elsif count != 1
            @result.add_error(
              "Wettkampfdefinitionsliste: element '#{el}' occurs #{count} times (expected 1)"
            )
          end
        end
      end

      def forbid_more_than_one(elements)
        elements.each do |el|
          count = @wk_elements[el]
          next if count <= 1

          @result.add_error(
            "Wettkampfdefinitionsliste: element '#{el}' occurs #{count} times (max 1)"
          )
        end
      end

      def require_at_least_one(elements)
        elements.each do |el|
          count = @wk_elements[el]
          next if count >= 1

          @result.add_error("Wettkampfdefinitionsliste: missing required element '#{el}'")
        end
      end
    end

    # Validates Vereinsmeldeliste element cardinalities
    class VmlCardinality
      def initialize(result, elements)
        @result = result
        @elements = elements
      end

      def validate!
        require_exactly_one(%w[ERZEUGER VERANSTALTUNG VEREIN ANSPRECHPARTNER])
        require_at_least_one(%w[ABSCHNITT WETTKAMPF])
      end

      private

      def require_exactly_one(elements)
        elements.each do |el|
          count = @elements[el]
          if count.zero?
            @result.add_error("Vereinsmeldeliste: missing required element '#{el}'")
          elsif count != 1
            @result.add_error(
              "Vereinsmeldeliste: element '#{el}' occurs #{count} times (expected 1)"
            )
          end
        end
      end

      def require_at_least_one(elements)
        elements.each do |el|
          count = @elements[el]
          next if count >= 1

          @result.add_error("Vereinsmeldeliste: missing required element '#{el}'")
        end
      end
    end

    # Type-check helpers for WKDL: split into small modules to keep complexity low
    module WkTypeChecksCommon
      def check_zk(_name, _index, _val, _line_number, _opts = nil)
        # any string (already UTF-8 scrubbed); nothing to do
      end

      def check_zahl(name, idx, val, line_number, _opts = nil)
        return if val.match?(/^\d+$/)

        add_error(invalid_zahl_error(name, idx, val, line_number))
      end

      def check_betrag(name, idx, val, line_number, _opts = nil)
        return if val.match?(/^\d+,\d{2}$/)

        add_error(
          "Element #{name}, attribute #{idx}: invalid Betrag '#{val}' (expected x,yy) " \
          "on line #{line_number}"
        )
      end

      def check_einzelstrecke(name, idx, val, line_number, _opts = nil)
        return add_error(invalid_zahl_error(name, idx, val, line_number)) unless val.match?(/^\d+$/)

        n = val.to_i
        return if n.zero? || (1..25_000).cover?(n)

        add_error(
          "Element #{name}, attribute #{idx}: Einzelstrecke out of range '#{val}' " \
          "(allowed 1..25000 or 0) on line #{line_number}"
        )
      end

      def invalid_zahl_error(name, idx, val, line_number)
        "Element #{name}, attribute #{idx}: invalid Zahl '#{val}' (line #{line_number})"
      end
    end

    module WkTypeChecksDateTime
      def check_datum(name, idx, val, line_number, _opts = nil)
        return add_error(datum_format_error(name, idx, val, line_number)) unless
          val.match?(/^\d{2}\.\d{2}\.\d{4}$/)

        Date.strptime(val, '%d.%m.%Y')
      rescue ArgumentError
        add_error(impossible_date_error(name, idx, val, line_number))
      end

      def check_uhrzeit(name, idx, val, line_number, _opts = nil)
        return add_error(uhrzeit_format_error(name, idx, val, line_number)) unless
          val.match?(/^\d{2}:\d{2}$/)

        hh, mm = val.split(':').map(&:to_i)
        return if (0..23).cover?(hh) && (0..59).cover?(mm)

        add_error(time_out_of_range_error(name, idx, val, line_number))
      end

      def check_zeit(name, idx, val, line_number, _opts = nil)
        return add_error(zeit_format_error(name, idx, val, line_number)) unless
          val.match?(/^\d{2}:\d{2}:\d{2},\d{2}$/)

        h, m, s, hh = parse_zeit_parts(val)
        return if (0..23).cover?(h) && (0..59).cover?(m) && (0..59).cover?(s) && (0..99).cover?(hh)

        add_error(time_out_of_range_error(name, idx, val, line_number))
      end

      def datum_format_error(name, idx, val, line_number)
        "Element #{name}, attribute #{idx}: invalid Datum '#{val}' " \
          "(expected TT.MM.JJJJ) on line #{line_number}"
      end

      def impossible_date_error(name, idx, val, line_number)
        "Element #{name}, attribute #{idx}: impossible date '#{val}' on line #{line_number}"
      end

      def uhrzeit_format_error(name, idx, val, line_number)
        "Element #{name}, attribute #{idx}: invalid Uhrzeit '#{val}' " \
          "(expected HH:MM) on line #{line_number}"
      end

      def zeit_format_error(name, idx, val, line_number)
        "Element #{name}, attribute #{idx}: invalid Zeit '#{val}' " \
          "(expected HH:MM:SS,hh) on line #{line_number}"
      end

      def time_out_of_range_error(name, idx, val, line_number)
        "Element #{name}, attribute #{idx}: time out of range '#{val}' on line #{line_number}"
      end

      def parse_zeit_parts(val)
        h, m, s_hh = val.split(':')
        s, hh = s_hh.split(',')
        [h.to_i, m.to_i, s.to_i, hh.to_i]
      end
    end

    module WkTypeChecksEnums1
      def check_bahnl(name, idx, val, line_number, _opts = nil)
        allowed = %w[16 20 25 33 50 FW X]
        return if allowed.include?(val)

        add_error(
          "Element #{name}, attribute #{idx}: invalid Bahnlänge '#{val}' (allowed: " \
          "#{allowed.join(', ')}) on line #{line_number}"
        )
      end

      def check_zeitmessung(name, idx, val, line_number, _opts = nil)
        allowed = %w[HANDZEIT AUTOMATISCH HALBAUTOMATISCH]
        return if allowed.include?(val)

        add_error(
          "Element #{name}, attribute #{idx}: invalid Zeitmessung '#{val}' (allowed: " \
          "#{allowed.join(', ')}) on line #{line_number}"
        )
      end

      def check_land(name, idx, val, line_number, _opts = nil)
        return if val.match?(/^[A-Z]{3}$/)

        add_error(
          "Element #{name}, attribute #{idx}: invalid Land '#{val}' " \
          "(expected FINA code, e.g., GER) on line #{line_number}"
        )
      end

      def check_nachweis_bahn(name, idx, val, line_number, _opts = nil)
        allowed = %w[25 50 FW AL]
        return if allowed.include?(val)

        add_error(
          "Element #{name}, attribute #{idx}: invalid Bahnlänge '#{val}' (allowed: " \
          "#{allowed.join(', ')}) on line #{line_number}"
        )
      end

      def check_relativ(name, idx, val, line_number, _opts = nil)
        return if %w[J N].include?(val)

        add_error(
          "Element #{name}, attribute #{idx}: invalid Relative Angabe '#{val}' (allowed: J, N) " \
          "on line #{line_number}"
        )
      end

      def check_wk_art(name, idx, val, line_number, _opts = nil)
        return if %w[V Z F E].include?(val)

        add_error(
          "Element #{name}, attribute #{idx}: invalid Wettkampfart '#{val}' " \
          "(allowed: V, Z, F, E) on line #{line_number}"
        )
      end
    end

    module WkTypeChecksEnums2
      def check_technik(name, idx, val, line_number, _opts = nil)
        return if %w[F R B S L X].include?(val)

        add_error(
          "Element #{name}, attribute #{idx}: invalid Technik '#{val}' " \
          "(allowed: F, R, B, S, L, X) on line #{line_number}"
        )
      end

      def check_ausuebung(name, idx, val, line_no, _opts = nil)
        return if %w[GL BE AR ST WE GB X].include?(val)

        add_error(
          "Element #{name}, attribute #{idx}: invalid Ausübung '#{val}' " \
          "(allowed: GL, BE, AR, ST, WE, GB, X) on line #{line_no}"
        )
      end

      def check_geschlecht_wk(name, idx, val, line_no, _opts = nil)
        return if %w[M W X].include?(val)

        add_error(
          "Element #{name}, attribute #{idx}: invalid Geschlecht '#{val}' (allowed: M, W, X) " \
          "on line #{line_no}"
        )
      end

      def check_bestenliste(name, idx, val, line_no, _opts = nil)
        return if %w[SW EW PA MS KG XX].include?(val)

        add_error(
          "Element #{name}, attribute #{idx}: invalid Zuordnung '#{val}' " \
          "(allowed: SW, EW, PA, MS, KG, XX) on line #{line_no}"
        )
      end

      def check_wert_typ(name, idx, val, line_number, _opts = nil)
        return if %w[JG AK].include?(val)

        add_error(
          "Element #{name}, attribute #{idx}: invalid Wertungstyp '#{val}' (allowed: JG, AK) " \
          "on line #{line_number}"
        )
      end

      def check_jgak(name, idx, val, line_number, _opts = nil)
        return if val.match?(/^\d{1,4}$/) || val.match?(/^[ABCDEJ]$/) || val.match?(/^\d{2,3}\+$/)

        add_error(
          "Element #{name}, attribute #{idx}: invalid JG/AK '#{val}' on line #{line_number}"
        )
      end

      def check_geschlecht_erw(name, idx, val, line_number, _opts = nil)
        return if %w[M W X D].include?(val)

        add_error(
          "Element #{name}, attribute #{idx}: invalid Geschlecht '#{val}' (allowed: M, W, X, D) " \
          "on line #{line_number}"
        )
      end

      def check_geschlecht_pf(name, idx, val, line_number, _opts = nil)
        return if %w[M W D].include?(val)

        add_error(
          "Element #{name}, attribute #{idx}: invalid Geschlecht '#{val}' (allowed: M, W, D) " \
          "on line #{line_number}"
        )
      end

      def check_meldegeld_typ(name, idx, val, line_number, _opts = nil)
        allowed = %w[
          MELDEGELDPAUSCHALE EINZELMELDEGELD STAFFELMELDEGELD WKMELDEGELD MANNSCHAFTMELDEGELD
        ]
        return if allowed.include?(val.upcase)

        add_error(
          "Element #{name}, attribute #{idx}: invalid Meldegeld Typ '#{val}' on line #{line_number}"
        )
      end
    end

    # Aggregate module to provide a single include point
    module WkTypeChecks
      include WkTypeChecksCommon
      include WkTypeChecksDateTime
      include WkTypeChecksEnums1
      include WkTypeChecksEnums2
    end

    # Shared schema scaffolding for element count and attribute validation
    class SchemaBase
      def initialize(result)
        @result = result
      end

      def validate_element(name, attrs, line_number)
        schema = self.class::SCHEMAS[name]
        return unless schema

        check_count(name, attrs, schema.length, line_number)
        validate_attribute_types(name, attrs, schema, line_number)
        validate_cross_rules(name, attrs, line_number) if respond_to?(:validate_cross_rules, true)
      end

      private

      def validate_attribute_types(name, attrs, schema, line_number)
        schema.each_with_index do |spec, i|
          type, required, opts = spec
          val = attrs[i]
          if (val.nil? || val.empty?) && required
            add_error("Element #{name}: missing required attribute #{i + 1} on line #{line_number}")
            next
          end
          next if val.nil? || val.empty?

          send("check_#{type}", name, i + 1, val, line_number, opts)
        end
      end

      def add_error(msg)
        @result.add_error(msg)
      end

      def check_count(name, attrs, expected, line_number)
        got = attrs.length
        return if got == expected

        add_error(
          "Element #{name}: expected #{expected} attributes, got #{got} (line #{line_number})"
        )
      end
    end

    # Validates Wettkampfdefinitionsliste attribute counts and datatypes
    class WkSchema < SchemaBase
      include WkTypeChecks

      SCHEMAS = {
        'ERZEUGER' => [[:zk, true], [:zk, true], [:zk, true]],
        'VERANSTALTUNG' => [
          [:zk, true], [:zk, true], [:bahnl, true], [:zeitmessung, true]
        ],
        'VERANSTALTUNGSORT' => [
          [:zk, true], [:zk, false], [:zk, false], [:zk, true],
          [:land, true], [:zk, false], [:zk, false], [:zk, false]
        ],
        'AUSSCHREIBUNGIMNETZ' => [[:zk, false]],
        'VERANSTALTER' => [[:zk, true]],
        'AUSRICHTER' => [
          [:zk, true], [:zk, true], [:zk, false], [:zk, false], [:zk, false],
          [:land, false], [:zk, false], [:zk, false], [:zk, true]
        ],
        'MELDEADRESSE' => [
          [:zk, true], [:zk, false], [:zk, false], [:zk, false],
          [:land, false], [:zk, false], [:zk, false], [:zk, true]
        ],
        'MELDESCHLUSS' => [[:datum, true], [:uhrzeit, true]],
        'BANKVERBINDUNG' => [[:zk, false], [:zk, true], [:zk, false]],
        'BESONDERES' => [[:zk, true]],
        'NACHWEIS' => [[:datum, true], [:datum, false], [:nachweis_bahn, true]],
        'ABSCHNITT' => [
          [:zahl, true], [:datum, true], [:uhrzeit, false],
          [:uhrzeit, false], [:uhrzeit, true], [:relativ, false]
        ],
        'WETTKAMPF' => [
          [:zahl, true], [:wk_art, true], [:zahl, true], [:zahl, false],
          [:einzelstrecke, true], [:technik, true], [:ausuebung, true],
          [:geschlecht_wk, true], [:bestenliste, true], [:zahl, false], [:wk_art, false]
        ],
        # Intentionally omitting WERTUNG and PFLICHTZEIT for now
        # (spec examples appear inconsistent)
        'MELDEGELD' => [[:meldegeld_typ, true], [:betrag, true], [:zahl, false]]
      }.freeze

      def validate_cross_rules(name, attrs, line_number)
        return unless name == 'MELDEGELD'

        type_str = attrs[0].to_s.upcase
        needs_wk = type_str == 'WKMELDEGELD' && (attrs[2].nil? || attrs[2].empty?)
        return unless needs_wk

        add_error(
          "Element MELDEGELD: 'WKMELDEGELD' requires Wettkampfnr (attr 3) on line #{line_number}"
        )
      end
    end

    # Validates Vereinsmeldeliste attribute counts and datatypes
    class VmlSchema < SchemaBase
      include WkTypeChecks

      SCHEMAS = {
        'ERZEUGER' => [[:zk, true], [:zk, true], [:zk, true]],
        'VERANSTALTUNG' => [[:zk, true], [:zk, true], [:bahnl, true], [:zeitmessung, true]],
        'ABSCHNITT' => [[:zahl, true], [:datum, true], [:uhrzeit, true], [:relativ, false]],
        'WETTKAMPF' => [
          [:zahl, true], [:wk_art, true], [:zahl, true], [:zahl, false],
          [:einzelstrecke, true], [:technik, true], [:ausuebung, true],
          [:geschlecht_wk, true], [:zahl, false], [:wk_art, false]
        ],
        'VEREIN' => [[:zk, true], [:zahl, true], [:zahl, true], [:land, true]],
        'ANSPRECHPARTNER' => [
          [:zk, true], [:zk, false], [:zk, false], [:zk, false],
          [:land, false], [:zk, false], [:zk, false], [:zk, true]
        ],
        'KARIMELDUNG' => [[:zahl, true], [:zk, true], [:zk, true]],
        'KARIABSCHNITT' => [[:zahl, true], [:zahl, true], [:zk, false]],
        'TRAINER' => [[:zahl, true], [:zk, true]],
        'PNMELDUNG' => [
          [:zk, true], [:zahl, true], [:zahl, true], [:geschlecht_pf, true],
          [:zahl, true], [:zahl, false], [:zahl, false],
          [:land, false], [:land, false], [:land, false]
        ],
        'HANDICAP' => [
          [:zahl, true], [:zk, false], [:zk, false],
          [:zk, true], [:zk, true], [:zk, true], [:zk, false]
        ],
        'STARTPN' => [[:zahl, true], [:zahl, true], [:zeit, false]],
        'STMELDUNG' => [
          [:zahl, true], [:zahl, true], [:wert_typ, true],
          [:jgak, true], [:jgak, false], [:zk, false]
        ],
        'STARTST' => [[:zahl, true], [:zahl, true], [:zeit, false]],
        'STAFFELPERSON' => [[:zahl, true], [:zahl, true], [:zahl, true], [:zahl, true]]
      }.freeze

      # no extra cross-rules for VML currently
    end
  end
end
