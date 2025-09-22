# frozen_string_literal: true

require 'date'

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
        head = io.read(3)
        return if head.nil? || head.empty?

        if head.bytes == [0xEF, 0xBB, 0xBF]
          @result.add_error('UTF-8 BOM detected (spec requires UTF-8 without BOM)')
        else
          head.bytes.reverse_each { |b| io.ungetbyte(b) }
        end
      end

      def sanitize_line(raw_line)
        # Remove trailing LF then CR for CRLF compatibility
        s = raw_line.delete_suffix("\n").delete_suffix("\r")
        s.force_encoding(Encoding::UTF_8)
        return s if s.valid_encoding?

        @result.add_error('File is not valid UTF-8 encoding')
        s.scrub('�')
      end

      def process_lines(io)
        analyzer = LineAnalyzer.new(@result)
        had_crlf = iterate(io) { |line, line_number| analyzer.process_line(line, line_number) }
        @result.add_warning('CRLF line endings detected') if had_crlf
        analyzer.finish
        check_filename(@filename)
        @result
      end

      def iterate(io)
        had_crlf = false
        line_number = 0
        io.each_line("\n") do |raw_line|
          line_number += 1
          had_crlf ||= raw_line.end_with?("\r\n")
          yield sanitize_line(raw_line), line_number
        end
        had_crlf
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
    class LineAnalyzer
      def initialize(result)
        @result = result
        @effective_index = 0
        @format_line_index = nil
        @dateiende_index = nil
        @after_dateiende_effective_line_number = nil
        @wk_elements = Hash.new(0)
        @wk_schema = WkSchema.new(@result)
      end

      def process_line(line, line_number)
        check_comment_balance(line, line_number)
        trimmed = strip_inline_comment(line)
        return if trimmed.empty?

        @effective_index += 1
        return handle_first_effective(trimmed, line_number) if @effective_index == 1

        return @dateiende_index = line_number if trimmed == 'DATEIENDE'

        @after_dateiende_effective_line_number ||= line_number if @dateiende_index
        require_semicolon(trimmed, line_number)
        track_wk_element(trimmed)
        validate_wk_line(trimmed, line_number)
      end

      def finish
        post_validate_positions
        validate_wk_list_elements if @result.list_type == 'Wettkampfdefinitionsliste'
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
        remove_inline_comments(line).strip
      end

      def check_format_line(trimmed, line_number)
        m = trimmed.match(/^FORMAT:([^;]+);(\d+);$/)
        msg = "First non-empty line must be 'FORMAT:<Listentyp>;7;' (line #{line_number})"
        return @result.add_error(msg) unless m

        @result.set_format(lt = m[1], m[2])
        @result.add_error("Unknown list type in FORMAT: '#{lt}'") unless
          Validator::ALLOWED_LIST_TYPES.include?(lt)
        @result.add_error("Unsupported format version '#{m[2]}', expected '7'") unless m[2] == '7'
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
        return line unless line.include?('(*') && line.include?('*)')

        line.gsub(/\(\*.*?\*\)/, '')
      end

      def track_wk_element(trimmed)
        return unless @result.list_type == 'Wettkampfdefinitionsliste'
        return unless trimmed.include?(':')

        name = trimmed.split(':', 2).first.strip
        return if name == 'FORMAT'
        return if name == 'DATEIENDE'

        @wk_elements[name] += 1
      end

      def validate_wk_list_elements
        WkCardinality.new(@result, @wk_elements).validate!
      end

      def validate_wk_line(trimmed, line_number)
        return unless @result.list_type == 'Wettkampfdefinitionsliste'
        return unless trimmed.include?(':')

        name, rest = trimmed.split(':', 2)
        return if %w[FORMAT DATEIENDE].include?(name)

        attrs = rest.split(';', -1)
        attrs.pop if attrs.last == ''
        @wk_schema.validate_element(name, attrs, line_number)
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

    # Type-check and schema helpers for WKDL
    module WkTypeChecks
      def check_zk(_name, _index, _val, _line_number, _opts = nil)
        # any string (already UTF-8 scrubbed); nothing to do
      end

      def check_zahl(name, idx, val, line_number, _opts = nil)
        return if val.match?(/^\d+$/)

        add_err(
          "Element #{name}, attribute #{idx}: invalid Zahl '#{val}' (line #{line_number})"
        )
      end

      def check_datum(name, idx, val, line_number, _opts = nil)
        unless val.match?(/^\d{2}\.\d{2}\.\d{4}$/)
          return add_err(
            "Element #{name}, attribute #{idx}: invalid Datum '#{val}' " \
            "(expected TT.MM.JJJJ) on line #{line_number}"
          )
        end

        Date.strptime(val, '%d.%m.%Y')
      rescue ArgumentError
        add_err("Element #{name}, attribute #{idx}: impossible date '#{val}' on line #{line_number}")
      end

      def check_uhrzeit(name, idx, val, line_number, _opts = nil)
        unless val.match?(/^\d{2}:\d{2}$/)
          return add_err(
            "Element #{name}, attribute #{idx}: invalid Uhrzeit '#{val}' " \
            "(expected HH:MM) on line #{line_number}"
          )
        end

        hh, mm = val.split(':').map(&:to_i)
        return if (0..23).cover?(hh) && (0..59).cover?(mm)

        add_err("Element #{name}, attribute #{idx}: time out of range '#{val}' on line #{line_number}")
      end

      def check_zeit(name, idx, val, line_number, _opts = nil)
        unless val.match?(/^\d{2}:\d{2}:\d{2},\d{2}$/)
          return add_err(
            "Element #{name}, attribute #{idx}: invalid Zeit '#{val}' " \
            "(expected HH:MM:SS,hh) on line #{line_number}"
          )
        end

        h, m, s_hh = val.split(':')
        s, hh = s_hh.split(',')
        h = h.to_i
        m = m.to_i
        s = s.to_i
        hh = hh.to_i
        return if (0..23).cover?(h) && (0..59).cover?(m) && (0..59).cover?(s) && (0..99).cover?(hh)

        add_err("Element #{name}, attribute #{idx}: time out of range '#{val}' on line #{line_number}")
      end

      def check_betrag(name, idx, val, line_number, _opts = nil)
        return if val.match?(/^\d+,\d{2}$/)

        add_err(
          "Element #{name}, attribute #{idx}: invalid Betrag '#{val}' (expected x,yy) on line #{line_number}"
        )
      end

      def check_bahnl(name, idx, val, line_number, _opts = nil)
        allowed = %w[16 20 25 33 50 FW X]
        return if allowed.include?(val)

        add_err(
          "Element #{name}, attribute #{idx}: invalid Bahnlänge '#{val}' (allowed: " \
          "#{allowed.join(', ')}) on line #{line_number}"
        )
      end

      def check_zeitmessung(name, idx, val, line_number, _opts = nil)
        allowed = %w[HANDZEIT AUTOMATISCH HALBAUTOMATISCH]
        return if allowed.include?(val)

        add_err(
          "Element #{name}, attribute #{idx}: invalid Zeitmessung '#{val}' (allowed: " \
          "#{allowed.join(', ')}) on line #{line_number}"
        )
      end

      def check_land(name, idx, val, line_number, _opts = nil)
        return if val.match?(/^[A-Z]{3}$/)

        add_err(
          "Element #{name}, attribute #{idx}: invalid Land '#{val}' (expected FINA code, e.g., GER) " \
          "on line #{line_number}"
        )
      end

      def check_nachweis_bahn(name, idx, val, line_number, _opts = nil)
        allowed = %w[25 50 FW AL]
        return if allowed.include?(val)

        add_err(
          "Element #{name}, attribute #{idx}: invalid Bahnlänge '#{val}' (allowed: " \
          "#{allowed.join(', ')}) on line #{line_number}"
        )
      end

      def check_relativ(name, idx, val, line_number, _opts = nil)
        return if %w[J N].include?(val)

        add_err(
          "Element #{name}, attribute #{idx}: invalid Relative Angabe '#{val}' (allowed: J, N) " \
          "on line #{line_number}"
        )
      end

      def check_wk_art(name, idx, val, line_number, _opts = nil)
        return if %w[V Z F E].include?(val)

        add_err(
          "Element #{name}, attribute #{idx}: invalid Wettkampfart '#{val}' (allowed: V, Z, F, E) " \
          "on line #{line_number}"
        )
      end

      def check_einzelstrecke(name, idx, val, line_number, _opts = nil)
        unless val.match?(/^\d+$/)
          return add_err(
            "Element #{name}, attribute #{idx}: invalid Zahl '#{val}' (line #{line_number})"
          )
        end

        n = val.to_i
        return if n.zero? || (1..25_000).cover?(n)

        add_err(
          "Element #{name}, attribute #{idx}: Einzelstrecke out of range '#{val}' " \
          "(allowed 1..25000 or 0) on line #{line_number}"
        )
      end

      def check_technik(name, idx, val, line_number, _opts = nil)
        return if %w[F R B S L X].include?(val)

        add_err(
          "Element #{name}, attribute #{idx}: invalid Technik '#{val}' (allowed: F, R, B, S, L, X) " \
          "on line #{line_number}"
        )
      end

      def check_ausuebung(name, idx, val, line_no, _opts = nil)
        return if %w[GL BE AR ST WE GB X].include?(val)

        add_err(
          "Element #{name}, attribute #{idx}: invalid Ausübung '#{val}' (allowed: GL, BE, AR, ST, WE, GB, X) " \
          "on line #{line_no}"
        )
      end

      def check_geschlecht_wk(name, idx, val, line_no, _opts = nil)
        return if %w[M W X].include?(val)

        add_err(
          "Element #{name}, attribute #{idx}: invalid Geschlecht '#{val}' (allowed: M, W, X) " \
          "on line #{line_no}"
        )
      end

      def check_bestenliste(name, idx, val, line_no, _opts = nil)
        return if %w[SW EW PA MS KG XX].include?(val)

        add_err(
          "Element #{name}, attribute #{idx}: invalid Zuordnung '#{val}' (allowed: SW, EW, PA, MS, KG, XX) " \
          "on line #{line_no}"
        )
      end

      def check_wert_typ(name, idx, val, line_number, _opts = nil)
        return if %w[JG AK].include?(val)

        add_err(
          "Element #{name}, attribute #{idx}: invalid Wertungstyp '#{val}' (allowed: JG, AK) on line #{line_number}"
        )
      end

      def check_jgak(name, idx, val, line_number, _opts = nil)
        return if val.match?(/^\d{1,4}$/) || val.match?(/^[ABCDEJ]$/) || val.match?(/^\d{2,3}\+$/)

        add_err("Element #{name}, attribute #{idx}: invalid JG/AK '#{val}' on line #{line_number}")
      end

      def check_geschlecht_erw(name, idx, val, line_number, _opts = nil)
        return if %w[M W X D].include?(val)

        add_err(
          "Element #{name}, attribute #{idx}: invalid Geschlecht '#{val}' (allowed: M, W, X, D) " \
          "on line #{line_number}"
        )
      end

      def check_geschlecht_pf(name, idx, val, line_number, _opts = nil)
        return if %w[M W D].include?(val)

        add_err(
          "Element #{name}, attribute #{idx}: invalid Geschlecht '#{val}' (allowed: M, W, D) on line #{line_number}"
        )
      end

      def check_meldegeld_typ(name, idx, val, line_number, _opts = nil)
        allowed = %w[MELDEGELDPAUSCHALE EINZELMELDEGELD STAFFELMELDEGELD WKMELDEGELD
                     MANNSCHAFTMELDEGELD]
        return if allowed.include?(val.upcase)

        add_err(
          "Element #{name}, attribute #{idx}: invalid Meldegeld Typ '#{val}' on line #{line_number}"
        )
      end
    end

    # Validates Wettkampfdefinitionsliste attribute counts and datatypes
    class WkSchema
      include WkTypeChecks

      SCHEMAS = {
        'ERZEUGER' => [[:zk, true], [:zk, true], [:zk, true]],
        'VERANSTALTUNG' => [[:zk, true], [:zk, true], [:bahnl, true], [:zeitmessung, true]],
        'VERANSTALTUNGSORT' => [
          [:zk,
           true], [:zk, false], [:zk, false], [:zk, true], [:land, true], [:zk, false], [:zk, false], [:zk, false]
        ],
        'AUSSCHREIBUNGIMNETZ' => [[:zk, false]],
        'VERANSTALTER' => [[:zk, true]],
        'AUSRICHTER' => [
          [:zk,
           true], [:zk, true], [:zk, false], [:zk, false], [:zk, false], [:land, false], [:zk, false], [:zk, false], [:zk, true]
        ],
        'MELDEADRESSE' => [
          [:zk,
           true], [:zk, false], [:zk, false], [:zk, false], [:land, false], [:zk, false], [:zk, false], [:zk, true]
        ],
        'MELDESCHLUSS' => [[:datum, true], [:uhrzeit, true]],
        'BANKVERBINDUNG' => [[:zk, false], [:zk, true], [:zk, false]],
        'BESONDERES' => [[:zk, true]],
        'NACHWEIS' => [[:datum, true], [:datum, false], [:nachweis_bahn, true]],
        'ABSCHNITT' => [[:zahl, true], [:datum, true], [:uhrzeit, false], [:uhrzeit, false],
                        [:uhrzeit, true], [:relativ, false]],
        'WETTKAMPF' => [
          [:zahl, true], [:wk_art, true], [:zahl, true], [:zahl, false], [:einzelstrecke, true],
          [:technik, true], [:ausuebung, true], [:geschlecht_wk, true], [:bestenliste, true], [:zahl, false], [:wk_art, false]
        ],
        # Intentionally omitting WERTUNG and PFLICHTZEIT for now due to spec inconsistencies in examples
        'MELDEGELD' => [[:meldegeld_typ, true], [:betrag, true], [:zahl, false]]
      }.freeze

      def initialize(result)
        @result = result
      end

      def validate_element(name, attrs, line_number)
        schema = SCHEMAS[name]
        return unless schema

        check_count(name, attrs, schema.length, line_number)
        schema.each_with_index do |spec, i|
          type, required, opts = spec
          val = attrs[i]
          if (val.nil? || val.empty?) && required
            add_err("Element #{name}: missing required attribute #{i + 1} on line #{line_number}")
            next
          end
          next if val.nil? || val.empty?

          send("check_#{type}", name, i + 1, val, line_number, opts)
        end

        validate_cross_rules(name, attrs, line_number)
      end

      private

      def add_err(msg)
        @result.add_error(msg)
      end

      def check_count(name, attrs, expected, line_number)
        got = attrs.length
        return if got == expected

        add_err("Element #{name}: expected #{expected} attributes, got #{got} (line #{line_number})")
      end

      def validate_cross_rules(name, attrs, line_number)
        return unless name == 'MELDEGELD'

        type_str = attrs[0].to_s.upcase
        needs_wk = type_str == 'WKMELDEGELD' && (attrs[2].nil? || attrs[2].empty?)
        return unless needs_wk

        add_err(
          "Element MELDEGELD: 'WKMELDEGELD' requires Wettkampfnr (attr 3) on line #{line_number}"
        )
      end
    end
  end
end
