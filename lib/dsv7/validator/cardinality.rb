# frozen_string_literal: true

module Dsv7
  class Validator
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

    # Validates Wettkampfergebnisliste element cardinalities
    class ErgCardinality
      def initialize(result, elements)
        @result = result
        @elements = elements
      end

      def validate!
        require_exactly_one(%w[ERZEUGER VERANSTALTUNG VERANSTALTER AUSRICHTER])
        require_at_least_one(%w[ABSCHNITT WETTKAMPF WERTUNG VEREIN])
      end

      private

      def require_exactly_one(elements)
        elements.each do |el|
          count = @elements[el]
          if count.zero?
            @result.add_error("Wettkampfergebnisliste: missing required element '#{el}'")
          elsif count != 1
            @result.add_error(
              "Wettkampfergebnisliste: element '#{el}' occurs #{count} times (expected 1)"
            )
          end
        end
      end

      def require_at_least_one(elements)
        elements.each do |el|
          count = @elements[el]
          next if count >= 1

          @result.add_error("Wettkampfergebnisliste: missing required element '#{el}'")
        end
      end
    end
  end
end
