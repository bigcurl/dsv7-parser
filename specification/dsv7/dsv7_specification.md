# DSV7 Datenaustausch-Spezifikation (Überarbeitet)

Diese Datei stellt die strukturierte, bereinigte und vereinheitlichte Version der DSV7-Spezifikation dar.  
Ziel ist die einfache Weiterverarbeitung in Parsern, Webanwendungen oder Dokumentationssystemen.

## Grundregeln für Daten
- Trennzeichen zwischen Attributen ist `;`
- UTF-8 (ohne BOM)
- Kommentare: `(* ... *)`
- Kein Zeilenumbruch innerhalb eines Elements
- Pflichtfelder: `J = Ja`, `N = Nein`
- Formatkennung: `FORMAT:Wettkampfdefinitionsliste;7;`
 - Abschluss: `DATEIENDE`

## Datenaustausch

- Ein einheitlicher Datenstandard ist erforderlich, damit Daten korrekt interpretiert werden können.
- Die Daten sollten in einer einzigen Datei gespeichert werden.

### Dateiname

- Schema: `JJJJ-MM-TT-Ort-Zusatz.DSV7`
- Felder:
  - `JJJJ`: Jahr
  - `MM`: Monat
  - `TT`: Tag des letzten Veranstaltungsabschnitts
  - `Ort`: Veranstaltungsort (nicht der Name des Schwimmbades), max. 8 Zeichen
    - Leerzeichen und Bindestriche entfernen
    - Umlaute: `ä->ae`, `ö->oe`, `ü->ue`, `ß->ss`
  - `Zusatz`: abhängig vom Listentyp
    - Vereinsmeldeliste: `Vereinsbezeichnung-Me`
    - Vereinsergebnisliste: `Vereinsbezeichnung-Pr`
    - Wettkampfergebnisliste: `Pr`
    - Wettkampfdefinitionsliste: `Wk`
- Vereinsbezeichnung: auf 16 Zeichen kürzen; Leerzeichen/Bindestriche entfernen; Umlaute wie oben.
- Mehrere Dateien am selben Tag/Ort: fortlaufende Nummer an `Ort` anhängen, z. B. `Ort1`, `Ort2`.

Beispiele:

```
JJJJ-MM-TT-Ort1-Zusatz.DSV7
JJJJ-MM-TT-Ort2-Zusatz.DSV7
2001-12-16-Berlin-Pr.DSV7
2001-12-16-Muenster-Pr.DSV7
2001-12-16-Frankfur-Pr.DSV7
```

### Kommentare

- Syntax: `(* ... *)`
- Kommentare sind einzeilig; mehrzeilige Hinweise müssen zeilenweise jeweils vollständig eingeschlossen werden.
- Verwendungszweck: beliebige Hinweise und Mitteilungen innerhalb der Datei.
- Parserhinweis: Text zwischen `(*` und `*)` wird als Kommentar behandelt.

Beispiel:

```
(* Dieses ist eine Kommentarzeile *)
```

## Allgemeine Festlegungen

- Listen bestehen aus Elementen.
- Elementkennung: eindeutige Konstante am Zeilenanfang.
- Attribute: feste Anzahl und Reihenfolge; Trennzeichen `;`.
- Pflicht- und Wahlattribute: optionale Attribute können fehlen, das Trennzeichen bleibt erhalten (leeres Feld).
- Optionale Attribute ohne Wert müssen als leeres Feld gekennzeichnet werden (`;;`).
- Leerzeichen: führende und abschließende Leerzeichen innerhalb eines Attributs sind erlaubt.
- Zeilenumbrüche: innerhalb eines Elements kein Zeilenvorschub (CRLF).
- Pflichtfeld-Kennzeichnung: `J` = muss vorhanden sein, `N` = kann weggelassen werden.

---

## Datentypen

- ZK: Zeichenkette; alle Zeichen außer `;` und Zeilenumbruch (CRLF) sind zulässig.
- Zeichen: genau 1 Zeichen.
- Zahl: numerischer Wert ohne Vorzeichen und Dezimalteil (positiver Integer, 32 Bit).
- Zeit: `HH:MM:SS,hh` mit führenden Nullen; z. B. `00:02:32,09`.
- Datum: `TT.MM.JJJJ` mit führenden Nullen; z. B. `03.08.1990`.
- Uhrzeit: `HH:MM` mit führenden Nullen; 24‑Stunden‑Format (z. B. `09:48`; 16 statt 04 am Nachmittag).
- Betrag: Geldbetrag mit zwei Nachkommastellen und Komma als Dezimaltrennzeichen (z. B. `5,50`).
- JGAK: vierstellige Zahl bei Jahrgang; Einzel (AK): `A,B,C,D,E,J`; Masters Einzel‑AK: `20,25,30,40,...`; Staffel (AK): `A,B,C,D,E,J`; Masters Staffel: minimales Mannschafts‑Gesamtalter mit Pluszeichen (z. B. `80+`, `100+`, `120+`).

---

## Übersicht der zur Verfügung stehenden Listen

- Wettkampfdefinitionsliste
- Vereinsmeldeliste
- Wettkampfergebnisliste
- Vereinsergebnisliste

Erläuterungen:

- Wettkampfdefinitionsliste: optionale Hilfe der Verbände/Ausrichter für meldende Vereine; stellt Ausschreibungsdaten für Verwaltungsprogramme zur vereinfachten Meldungsbearbeitung bereit.
- Vereinsergebnisliste: zusätzliche Serviceleistung an meldende Vereine; komprimierte Ergebnisse für eigene Auswertung und örtlichen Pressedienst.

Hinweise zur Reihenfolge:

- Elemente: Reihenfolge in der Datei folgt der Reihenfolge in der Beschreibung.
- Ausnahmen: Abweichungen zur Lesbarkeit sind zulässig, sofern referenzierende Elemente erst nach dem referenzierten Element erscheinen.
- Muss-Positionen: `FORMAT` ist stets das erste Element; `DATEIENDE` ist stets das letzte Element.

Wettkämpfe im Element `WETTKAMPF`:

- Die Reihenfolge der Wettkämpfe ist nicht zwingend numerisch aufsteigend.
- In Dateien sollen die Wettkämpfe in der tatsächlichen Veranstaltungsreihenfolge aufgeführt werden.

---

_(Hinweis: Dieses Dokument ist automatisch aus der DSV7-Spezifikation erzeugt worden und ersetzt **nicht** das offizielle Dokument. Es dient der technischen Verarbeitung.)_
