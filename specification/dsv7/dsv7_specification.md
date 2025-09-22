# DSV7 Datenaustausch-Spezifikation (Überarbeitet)

Diese Datei stellt die strukturierte, bereinigte und vereinheitlichte Version der DSV7-Spezifikation dar.  
Ziel ist die einfache Weiterverarbeitung in Parsern, Webanwendungen oder Dokumentationssystemen.

## Allgemeines

- Beschreibung: Standard für den Datenaustausch von Meldungen und Ergebnissen bei Schwimmwettkämpfen.
- Vorherige Veröffentlichungen ungültig: true
- Herausgeber: Deutscher Schwimm-Verband (DSV)
- Format-Version: 7
- Format-Bezeichnung: Format 7
- Format-Datum: 2022-08
- In Kraft ab: 2023-01-01
- Format 6 gültig bis: 2023-07-31
- Format 7 alleinig ab: 2023-08-01
- Dokument-Stand: 2022-08-31

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

## Wettkampfdefinitionsliste

### `FORMAT`

- Vorkommen: 1

| Attribut | Datentyp | Pflicht | Beschreibung |
|----------|----------|---------|--------------|
| Listart  | ZK       | J       | Konstante: `Wettkampfdefinitionsliste` |
| Version  | Zahl     | J       | Versionsnummer des DSV-Standards (derzeit 7) |

### `ERZEUGER`

- Vorkommen: 1

| Attribut | Datentyp | Pflicht | Beschreibung |
|----------|----------|---------|--------------|
| Software | ZK       | J       | Name der Software, die die Datei erzeugt hat |
| Version  | ZK       | J       | Versionskennung der Software |
| Kontakt  | ZK       | J       | E-Mail-Adresse des Software-Herstellers |

### `VERANSTALTUNG`

- Vorkommen: 1

| Attribut       | Datentyp | Pflicht | Beschreibung |
|----------------|----------|---------|--------------|
| Bezeichnung    | ZK       | J       | Name der Veranstaltung |
| Ort            | ZK       | J       | Veranstaltungsort |
| Bahnlänge      | ZK       | J       | Falls nicht `16`, `20`, `25`, `33`, `50` Meter oder `FW` (Freiwasser), ist `X` anzugeben. Für 16 2/3 m ist `16` zu verwenden, für 33 1/3 m `33`. |
| Zeitmessung    | ZK       | J       | Werte: `HANDZEIT`, `AUTOMATISCH`, `HALBAUTOMATISCH` |

### `VERANSTALTUNGSORT`

- Vorkommen: 1

| Attribut     | Datentyp | Pflicht | Beschreibung |
|--------------|----------|---------|--------------|
| Schwimmhalle | ZK       | J       | Bezeichnung der Schwimmhalle |
| Straße       | ZK       | N       | Straße der Schwimmhalle |
| PLZ          | ZK       | N       | Postleitzahl der Schwimmhalle |
| Ort          | ZK       | J       | Ort der Schwimmhalle |
| Land         | ZK       | J       | Land (Nation) als FINA‑Kürzel, z. B. `GER` |
| Telefon      | ZK       | N       | Telefonnummer der Schwimmhalle |
| Fax          | ZK       | N       | Fax der Schwimmhalle |
| E‑Mail       | ZK       | N       | E‑Mail‑Adresse der Schwimmhalle |

### `AUSSCHREIBUNGIMNETZ`

- Vorkommen: 1

| Attribut       | Datentyp | Pflicht | Beschreibung |
|----------------|----------|---------|--------------|
| Internetadresse | ZK      | N       | Gültige Internetadresse, unter der die Ausschreibung zu finden ist |

### `VERANSTALTER`

- Vorkommen: 1

| Attribut               | Datentyp | Pflicht | Beschreibung |
|------------------------|----------|---------|--------------|
| Name des Veranstalters | ZK       | J       | Name des Veranstalters |

### `AUSRICHTER`

- Vorkommen: 1

| Attribut                 | Datentyp | Pflicht | Beschreibung |
|--------------------------|----------|---------|--------------|
| Name des Ausrichters     | ZK       | J       | Name des Ausrichters |
| Name                     | ZK       | J       | Name, Vorname des/der Ansprechpartner\*in |
| Straße                   | ZK       | N       | Straße des/der Ansprechpartner\*in |
| PLZ                      | ZK       | N       | PLZ des/der Ansprechpartner\*in |
| Ort                      | ZK       | N       | Ort des/der Ansprechpartner\*in |
| Land                     | ZK       | N       | Land (Nation) als FINA‑Kürzel, z. B. `GER` |
| Telefon                  | ZK       | N       | Telefonnummer des/der Ansprechpartner\*in |
| Fax                      | ZK       | N       | Fax des/der Ansprechpartner\*in |
| E‑Mail                   | ZK       | J       | E‑Mail‑Adresse des/der Ansprechpartner\*in |

### `MELDEADRESSE`

- Vorkommen: 1

| Attribut | Datentyp | Pflicht | Beschreibung |
|----------|----------|---------|--------------|
| Name     | ZK       | J       | Name, Vorname der Meldeadresse |
| Straße   | ZK       | N       | Straße der Meldeadresse |
| PLZ      | ZK       | N       | PLZ der Meldeadresse |
| Ort      | ZK       | N       | Ort der Meldeadresse |
| Land     | ZK       | N       | Land (Nation) als FINA‑Kürzel, z. B. `GER` |
| Telefon  | ZK       | N       | Telefonnummer der Meldeadresse |
| Fax      | ZK       | N       | Fax der Meldeadresse |
| E‑Mail   | ZK       | J       | E‑Mail‑Adresse der Meldeadresse |

### `MELDESCHLUSS`

- Vorkommen: 1

| Attribut | Datentyp | Pflicht | Beschreibung |
|----------|----------|---------|--------------|
| Datum    | Datum    | J       | Datum Meldeschluss |
| Uhrzeit  | Uhrzeit  | J       | Uhrzeit Meldeschluss |

### `BANKVERBINDUNG`

- Vorkommen: 0‑1

| Attribut      | Datentyp | Pflicht | Beschreibung |
|---------------|----------|---------|--------------|
| Name der Bank | ZK       | N       | Bankverbindung für die Überweisung der Meldegelder |
| IBAN          | ZK       | J       | IBAN |
| BIC           | ZK       | N       | BIC |

### `BESONDERES`

- Vorkommen: 0‑1

| Attribut   | Datentyp | Pflicht | Beschreibung |
|------------|----------|---------|--------------|
| Anmerkungen| ZK       | J       | Bestimmungen, die nicht durch die restlichen Regeln definiert wurden (z. B. besondere Wertungen, Meldegelder; Ausschreibung im Internet beachten). |

### `NACHWEIS`

- Vorkommen: 0‑1

| Attribut     | Datentyp | Pflicht | Beschreibung |
|--------------|----------|---------|--------------|
| Nachweis von | Datum    | J       | Datum, ab wann Zeiten für den Pflichtzeitennachweis berücksichtigt werden können |
| Nachweis bis | Datum    | N       | Datum, bis wann Zeiten für den Pflichtzeitennachweis berücksichtigt werden können |
| Bahnlänge    | ZK       | J       | Werte: `25` (nur 25 m), `50` (nur 50 m), `FW` (Freiwasser), `AL` (alle Bahnlängen) |

### `ABSCHNITT`

- Vorkommen: 1 bis N

| Attribut           | Datentyp | Pflicht | Beschreibung |
|--------------------|----------|---------|--------------|
| Abschnittsnr.      | Zahl     | J       | Nummer des Abschnitts, maximal zweistellig |
| Abschnittsdatum    | Datum    | J       | Datum des Abschnitts |
| Einlass            | Uhrzeit  | N       | Zeitpunkt Einlass |
| Kampfrichtersitzung| Uhrzeit  | N       | Anfangszeit der Kampfrichtersitzung |
| Anfangszeit        | Uhrzeit  | J       | Anfangszeit des Abschnitts |
| Relative Angabe    | Zeichen  | N       | `J`/`N`. `N` = Einlass/KR‑Sitzung/Anfangszeit sind echte Uhrzeiten. `J` = relative Angaben (Stunden:Minuten) nach dem vorherigen Abschnitt. Unterlassungswert: `N`. |

### `WETTKAMPF`

- Vorkommen: 1 bis N

| Attribut                 | Datentyp | Pflicht | Beschreibung |
|--------------------------|----------|---------|--------------|
| Wettkampfnr.             | Zahl     | J       | Nummer des Wettkampfes, maximal dreistellig |
| Wettkampfart             | Zeichen  | J       | `V` = Vorlauf, `Z` = Zwischenlauf, `F` = Finale, `E` = Entscheidung |
| Abschnittsnr.            | Zahl     | J       | Nummer des Abschnitts |
| Anzahl Starter           | Zahl     | N       | Unterlassungswert: `1` (Einzeldisziplin); bei Staffeln: Anzahl der Staffelteilnehmer\*innen |
| Einzelstrecke            | Zahl     | J       | Strecke in Metern; zulässig: Ganzzahlen `1..25000` sowie `0` (sonstige) |
| Technik                  | Zeichen  | J       | `F` = Freistil, `R` = Rücken, `B` = Brust, `S` = Schmetterling, `L` = Lagen, `X` = Sonderform |
| Ausübung                 | ZK       | J       | `GL` = ganze Lage, `BE` = Beine, `AR` = Arme, `ST` = Start, `WE` = Wende, `GB` = Gleitübung, `X` = Sonderform |
| Geschlecht               | Zeichen  | J       | `M` = männlich, `W` = weiblich, `X` = gemischt |
| Zuordnung Bestenliste    | ZK       | J       | `SW` = Schwimmen (Jugend/offen, Standard), `EW` = vereinfachter Wettkampf, `PA` = Para‑Schwimmen, `MS` = Masters, `KG` = kindgerechter Wettkampf, `XX` = andere (z. B. Schule/Universität/Organisationen). Bei gemischten Wettkämpfen ist `SW` anzugeben. |
| Qualifikationswettkampfnr| Zahl     | N       | Bei Zwischenläufen/Finals: Nr. des Vorlaufs bzw. Zwischenlaufs |
| Qualifikationswettkampfart| Zeichen | N       | `V` = Vorlauf, `Z` = Zwischenlauf, `F` = Finale, `E` = Entscheidung |

### `WERTUNG`

- Vorkommen: 1 bis N

| Attribut                   | Datentyp | Pflicht | Beschreibung |
|----------------------------|----------|---------|--------------|
| Wettkampfnr.               | Zahl     | J       | Nummer des Wettkampfes |
| Wettkampfart               | Zeichen  | J       | `V` = Vorlauf, `Z` = Zwischenlauf, `F` = Finale, `E` = Entscheidung |
| WertungsID                 | Zahl     | J       | Eindeutige, in der gesamten Veranstaltung nur einmal vergebene Nummer für diese Wertung |
| Wertungsklasse (Typ)       | ZK       | J       | `JG` = Jahrgang, `AK` = Altersklasse |
| Mindest‑JG/AK              | JGAK     | J       | Kleinster Jahrgang / größte Altersklasse (offene Klasse: `0`) |
| Maximale JG/AK             | JGAK     | N       | Unterlassungswert: wie Mindest‑JG/AK; ansonsten größter Jahrgang / kleinste Altersklasse (`0` für „und jünger“) |
| Geschlecht                 | Zeichen  | N       | Zulässig: `M` (männlich), `W` (weiblich), `X` (mixed), `D` (divers). Fehlt Angabe, wird Geschlecht aus der Wettkampffolge verwendet. |
| Wertungsname               | ZK       | J       | Textliche Bezeichnung, z. B. „Jahrgang 1990 und älter“ |

### `PFLICHTZEIT`

- Vorkommen: 0 bis N
- Hinweis: Wird dieses Element für einen Wettkampf nicht angegeben, gibt es keine Pflichtzeit.

| Attribut                   | Datentyp | Pflicht | Beschreibung |
|----------------------------|----------|---------|--------------|
| Wettkampfnr.               | Zahl     | J       | Nummer des Wettkampfes |
| Wettkampfart               | Zeichen  | J       | `V` = Vorlauf, `Z` = Zwischenlauf, `F` = Finale, `E` = Entscheidung |
| Wertungsklasse (Typ)       | ZK       | J       | `JG` = Jahrgang, `AK` = Altersklasse |
| Mindest‑JG/AK              | JGAK     | J       | Kleinster Jahrgang / größte Altersklasse (offene Klasse: `0`) |
| Maximale JG/AK             | JGAK     | N       | Unterlassungswert: wie Mindest‑JG/AK; ansonsten größter Jahrgang / kleinste Altersklasse (`0` für „und jünger“) |
| Pflichtzeit                | Zeit     | J       | Pflichtzeit für die Wertungsklasse |
| Geschlecht                 | Zeichen  | N       | Zulässig: `M` (männlich), `W` (weiblich), `D` (divers). Für gemischte Ausschreibung mit getrennten Pflichtzeiten für Frauen/Männer entsprechend angeben. |

### `MELDEGELD`

- Vorkommen: 1 bis N

| Attribut        | Datentyp | Pflicht | Beschreibung |
|-----------------|----------|---------|--------------|
| Meldegeld Typ   | ZK       | J       | Zulässig: `Meldegeldpauschale`, `Einzelmeldegeld`, `Staffelmeldegeld`, `Wkmeldegeld`, `Mannschaftmeldegeld` |
| Betrag          | Betrag   | J       | Meldegeldbetrag |
| Wettkampfnr.    | Zahl     | N       | Nummer des Wettkampfes; Pflicht bei `Meldegeld Typ = Wkmeldegeld` |

Erläuterungen zum „Meldegeld Typ“:

- Meldegeldpauschale: Pauschaler Betrag, der pro Meldung hinzukommt.
- Einzelmeldegeld: Betrag je Einzelwettkampf (für alle Einzelwettkämpfe).
- Staffelmeldegeld: Betrag je Staffelwettkampf (für alle Staffelwettkämpfe).
- Wkmeldegeld: Meldegeld pro Wettkampf (hat Vorrang vor Einzel-/Staffelmeldegeld); `Wettkampfnr.` ist Pflicht.
- Mannschaftmeldegeld: Für Mannschaftswettkämpfe, z. B. DMS und DMS‑J.

### `DATEIENDE`

- Vorkommen: 1
- Hinweis: Am Ende der Datei muss dieses Element ausgegeben werden.
- Attribute: keine

### Beispiel

Beispiel für eine Wettkampfdefinitionsliste (Dateiname: `2002-03-10-Duisburg-Wk.DSV7`):

```
FORMAT:Wettkampfdefinitionsliste;7;
ERZEUGER:Schwimmsoftware;1.01;info@meinewebseite.de;
VERANSTALTUNG:EDV-Testwettkampf des SV NRW;Duisburg;50;HANDZEIT;
VERANSTALTUNGSORT:Schwimmstadion Duisburg-Wedau;Margaretenstr. 11;47055;Duisburg;GER;09999/11111;Kein Fax;;
AUSSCHREIBUNGIMNETZ:http://www.GibtsNicht.de;
VERANSTALTER:Schwimmverband NRW;
AUSRICHTER:SC Duisburg;Biene, Petra;Wabenstr. 69;47055;Duisburg;GER;0888/22222;0888/22223;PetraBiene@GibtsNicht.de;
MELDEADRESSE:Biene, Petra;Wabenstr. 69;47055;Duisburg;GER;0888/22222;0888/22223;PetraBiene@GibtsNicht.de;
MELDESCHLUSS:01.03.2002;18:00;
BESONDERES:Bitte Ausschreibung im www bezüglich Meldegelderstattung beachten!;
ABSCHNITT:1;09.03.2002;15:00;15:15;16:00;;
ABSCHNITT:2;10.03.2002;15:00;15:15;16:00;;
WETTKAMPF:1;V;1;;100;F;GL;W;SW;;;
WETTKAMPF:2;V;1;;50;R;GL;M;SW;;;
WETTKAMPF:3;E;2;;200;S;GL;W;SW;;;
WETTKAMPF:4;E;2;4;100;B;GL;M;SW;;;
WETTKAMPF:5;E;1;;100;F;GL;W;SW;;;
WETTKAMPF:101;F;1;;100;F;GL;W;SW;1;V;
WERTUNG:1;V;1;JG;0;9999;;OFFENE WERTUNG;
WERTUNG:1;V;2;JG;1989;;;JAHRGANG 1989;
WERTUNG:1;V;3;JG;1990;;;JAHRGANG 1990;
WERTUNG:2;V;4;JG;0;9999;;OFFENE WERTUNG;
WERTUNG:3;E;5;JG;0;9999;;OFFENE WERTUNG;
WERTUNG:4;E;6;JG;0;9999;;OFFENE WERTUNG;
WERTUNG:5;F;7;JG;0;9999;;OFFENE WERTUNG;
PFLICHTZEIT:1;V;JG;0;1990;00:00:55,00;;
PFLICHTZEIT:1;V;JG;1991;9999;00:00:56,00;;
MELDEGELD:MELDEGELDPAUSCHALE;10,00;;
MELDEGELD:EINZELMELDEGELD;2,50;;
MELDEGELD:STAFFELMELDEGELD;5,00;;
MELDEGELD:WKMELDEGELD;6,00;3;
DATEIENDE
```
---

_(Hinweis: Dieses Dokument ist automatisch aus der DSV7-Spezifikation erzeugt worden und ersetzt **nicht** das offizielle Dokument. Es dient der technischen Verarbeitung.)_
