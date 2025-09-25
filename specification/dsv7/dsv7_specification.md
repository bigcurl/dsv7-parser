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

## Vereinsmeldeliste

### `FORMAT`

- Vorkommen: **genau 1**
- Hinweis: Dieses Element muss **immer** als **erste Zeile der Datei** stehen.

| Attribut  | Datentyp | Pflicht | Beschreibung |
|-----------|----------|---------|--------------|
| Listart   | ZK       | J       | Konstant: `Vereinsmeldeliste` |
| Version   | Zahl     | J       | Versionsnummer des DSV-Standards (aktuell: `7`) |

### `ERZEUGER`

- Vorkommen: **genau 1**
- Hinweis: Informationen zur Software, die die Datei erzeugt hat.

| Attribut | Datentyp | Pflicht | Beschreibung |
|----------|----------|---------|--------------|
| Software | ZK       | J       | Name der Software, die die Datei erzeugt hat |
| Version  | ZK       | J       | Versionskennung der Software |
| Kontakt  | ZK       | J       | E-Mail-Adresse des Software-Herstellers |

### `VERANSTALTUNG`

- Vorkommen: **genau 1**
- Hinweis: Beschreibung der Wettkampfveranstaltung.

| Attribut               | Datentyp | Pflicht | Beschreibung |
|------------------------|----------|---------|--------------|
| Veranstaltungsbezeichnung | ZK    | J       | Name der Veranstaltung |
| Veranstaltungsort         | ZK    | J       | Ort der Veranstaltung |
| Bahnlänge                 | ZK    | J       | Bahnlänge in Metern (`16`, `20`, `25`, `33`, `50`, `FW` oder `X` bei abweichend) |
| Zeitmessung              | ZK    | J       | Art der Zeitmessung: `HANDZEIT`, `AUTOMATISCH`, `HALBAUTOMATISCH` |

### `ABSCHNITT`

- Vorkommen: **1 bis N**
- Hinweis: Definition der einzelnen Veranstaltungsabschnitte.

| Attribut          | Datentyp | Pflicht | Beschreibung |
|-------------------|----------|---------|--------------|
| Abschnittsnr.     | Zahl     | J       | Nummer des Abschnitts (max. zweistellig) |
| Abschnittsdatum   | Datum    | J       | Datum des Abschnitts (`TT.MM.JJJJ`) |
| Anfangszeit       | Uhrzeit  | J       | Beginn des Abschnitts (`HH:MM`, 24h-Format) |
| Relative Angabe   | Zeichen  | N       | `N` = absolute Zeit, `J` = relativ zur Vorzeit (Standard: `N`) |

### `WETTKAMPF`

- Vorkommen: **1 bis N**
- Hinweis: Definition der einzelnen Wettkämpfe der Veranstaltung.

| Attribut                 | Datentyp | Pflicht | Beschreibung |
|--------------------------|----------|---------|--------------|
| Wettkampfnr.             | Zahl     | J       | Nummer des Wettkampfs (max. dreistellig) |
| Wettkampfart             | Zeichen  | J       | `V` = Vorlauf, `E` = Entscheidung |
| Abschnittsnr.            | Zahl     | J       | Nummer des zugehörigen Abschnitts |
| Anzahl Starter           | Zahl     | N       | Anzahl Teilnehmer (Standard: `1` bei Einzeldisziplin) |
| Einzelstrecke            | Zahl     | J       | Streckenlänge in Metern (`1–25000` oder `0` für sonstige) |
| Technik                  | Zeichen  | J       | `F` = Freistil, `R` = Rücken, `B` = Brust, `S` = Schmetterling, `L` = Lagen, `X` = Sonstiges |
| Ausübung                 | ZK       | J       | `GL` = ganze Lage, `BE`, `AR`, `ST`, `WE`, `GB`, `X` |
| Geschlecht               | Zeichen  | J       | `M` = männlich, `W` = weiblich, `X` = gemischt |
| Qualifikationswettkampfnr | Zahl    | N       | Nummer des Qualifikationswettkampfs |
| Qualifikationswettkampfart | Zeichen | N       | `V`, `Z`, `F`, `E` |

### `VEREIN`

- Vorkommen: **genau 1**
- Hinweis: Informationen über den meldenden Verein.

| Attribut             | Datentyp | Pflicht | Beschreibung |
|----------------------|----------|---------|--------------|
| Vereinsbezeichnung   | ZK       | J       | Name des Vereins |
| Vereinskennzahl      | Zahl     | J       | 4-stellige vom DSV vergebene Kennzahl (bei nicht DSV-Vereinen: `0`) |
| Landesschwimmverband | Zahl     | J       | Numerische Kennung des LSV (1–18, bei Ausland `0`, bei Auswahlmannschaften `99`) |
| FINA-Nationenkürzel  | ZK       | J       | 3-stelliges Länderkürzel nach FINA, z. B. `GER` |

### `ANSPRECHPARTNER`

- Vorkommen: **genau 1**
- Hinweis: Kontaktdaten der meldenden Person.

| Attribut | Datentyp | Pflicht | Beschreibung |
|----------|----------|---------|--------------|
| Name     | ZK       | J       | Nachname, Vorname |
| Straße   | ZK       | N       | Straße der meldenden Person |
| PLZ      | ZK       | N       | Postleitzahl |
| Ort      | ZK       | N       | Ort |
| Land     | ZK       | N       | Länderkürzel nach FINA, z. B. `GER` |
| Telefon  | ZK       | N       | Telefonnummer |
| Fax      | ZK       | N       | Faxnummer |
| eMail    | ZK       | J       | E-Mail-Adresse |


### `KARIMELDUNG`

- Vorkommen: **0 bis N**
- Hinweis: Meldung der eingesetzten Kampfrichter*innen.

| Attribut        | Datentyp | Pflicht | Beschreibung |
|------------------|----------|---------|--------------|
| Nummer Kampfrichter | Zahl  | J       | Eindeutige numerische ID des Kampfrichters |
| Name            | ZK       | J       | Nachname, Vorname |
| Kampfrichtergruppe | ZK    | J       | `WKR`, `AUS`, `SCH`, `SPR` |


### `KARIABSCHNITT`

- Vorkommen: **0 bis N**
- Hinweis: Angabe, in welchen Abschnitten ein Kampfrichter zur Verfügung steht.

| Attribut        | Datentyp | Pflicht | Beschreibung |
|------------------|----------|---------|--------------|
| Nummer Kampfrichter | Zahl  | J       | Referenz auf `KARIMELDUNG` |
| Abschnittsnummer   | Zahl  | J       | Nummer des Abschnitts |
| Einsatzwunsch      | ZK    | N       | Gewünschter Einsatzbereich, z. B. `SCH`, `STA`, `ZR`, `ZN`, `SR`, `WR`, `AUS`, `SP`, `PKF`, `STO`, `ASCH`, `SIB`, `SAUF`, `VER` |


### `TRAINER`

- Vorkommen: **0 bis N**
- Hinweis: Angaben zu den Trainer*innen des Vereins.

| Attribut        | Datentyp | Pflicht | Beschreibung |
|------------------|----------|---------|--------------|
| Nummer Trainer   | Zahl     | J       | Eindeutige numerische ID zur Zuordnung bei `PNMELDUNG` |
| Name             | ZK       | J       | Nachname, Vorname des Trainers/der Trainerin |

### `PNMELDUNG`

- Vorkommen: **0 bis N**
- Hinweis: Meldung der einzelnen Teilnehmer*innen.

| Attribut                  | Datentyp | Pflicht | Beschreibung |
|---------------------------|----------|---------|--------------|
| Name                      | ZK       | J       | Nachname, Vorname des Teilnehmers/der Teilnehmerin |
| DSV-ID Schwimmer          | Zahl     | J       | 6-stellige DSV-ID (bei unbekannt: `0`) |
| Veranstaltungs-ID         | Zahl     | J       | Eindeutige ID zur Zuordnung innerhalb der Veranstaltung |
| Geschlecht des Schwimmers | Zeichen  | J       | `M` = männlich, `W` = weiblich, `D` = divers |
| Jahrgang                  | Zahl     | J       | Jahrgang vierstellig (z. B. `1990`) |
| Altersklasse              | Zahl     | N       | Altersklasse (optional) |
| Nummer Trainer            | Zahl     | N       | Referenz auf `TRAINER`, falls zugeordnet |
| Nationalität 1            | ZK       | N       | 3-stelliger FINA-Code, z. B. `GER` |
| Nationalität 2            | ZK       | N       | Weitere Staatsangehörigkeit |
| Nationalität 3            | ZK       | N       | Weitere Staatsangehörigkeit |

### `HANDICAP`

- Vorkommen: **0 bis N**
- Hinweis: Nur für Para-Schwimmer*innen (ergänzend zur `PNMELDUNG`).

| Attribut                  | Datentyp | Pflicht | Beschreibung |
|---------------------------|----------|---------|--------------|
| Veranstaltungs-ID         | Zahl     | J       | Referenz auf `PNMELDUNG` |
| DBS-ID                    | ZK       | N       | Nationale ID des/der Schwimmer*in beim DBS |
| IPC-ID                    | ZK       | N       | Internationale IPC-ID |
| Startklasse               | ZK       | J       | Startklasse (außer Lagen/Brust), z. B. `S8`, `AB` |
| Startklasse Brust         | ZK       | J       | Startklasse für Brust, z. B. `SB5`, `AB` |
| Startklasse Lagen         | ZK       | J       | Startklasse für Lagen, z. B. `SM6`, `AB` |
| Exceptions                | ZK       | N       | Liste

### `STARTPN`

- Vorkommen: **0 bis N**
- Hinweis: Einzelstart eines Schwimmers in einem bestimmten Wettkampf.

| Attribut                  | Datentyp | Pflicht | Beschreibung |
|---------------------------|----------|---------|--------------|
| Veranstaltungs-ID des Schwimmers | Zahl | J | Referenz auf `PNMELDUNG` |
| Wettkampfnummer           | Zahl     | J       | Nummer des Wettkampfs |
| Meldezeit                 | Zeit     | N       | Gemeldete Zeit (Standard: `00:00:00,00`) |

### `STMELDUNG`

- Vorkommen: **0 bis N**
- Hinweis: Meldung einer Staffel für einen bestimmten Wettkampf.

| Attribut                      | Datentyp | Pflicht | Beschreibung |
|-------------------------------|----------|---------|--------------|
| Nummer der Mannschaft         | Zahl     | J       | Mannschaftsnummer (z. B. `1`, `2`, ...) |
| Veranstaltungs-ID der Staffel | Zahl     | J       | Eindeutige ID der Staffel in dieser Veranstaltung |
| Wertungsklasse Typ            | ZK       | J       | `JG` = Jahrgang, `AK` = Altersklasse |
| Mindest‑JG/AK                 | JGAK     | J       | Mindestjahrgang oder maximale Altersklasse (bei offenen Klassen: `0`) |
| Maximale JG/AK                | JGAK     | N       | Falls abweichend vom Mindestwert; sonst leer |
| Name der Staffel              | ZK       | N       | Optionaler Staffelname (z. B. „Nachwuchsteam“) |

### `STARTST`

- Vorkommen: **0 bis N**
- Hinweis: Startmeldung einer Staffel in einem bestimmten Wettkampf.

| Attribut                      | Datentyp | Pflicht | Beschreibung |
|-------------------------------|----------|---------|--------------|
| Veranstaltungs-ID der Staffel | Zahl     | J       | Referenz auf `STMELDUNG` |
| Wettkampfnummer               | Zahl     | J       | Nummer des Wettkampfs |
| Meldezeit                     | Zeit     | N       | Gemeldete Zeit (Standard: `00:00:00,00`) |

### `STAFFELPERSON`

- Vorkommen: **0 bis N**
- Hinweis: Zuweisung der Schwimmer*innen zu einer Staffel in einem bestimmten Wettkampf.

| Attribut                          | Datentyp | Pflicht | Beschreibung |
|-----------------------------------|----------|---------|--------------|
| Veranstaltungs-ID der Staffel     | Zahl     | J       | Referenz auf `STMELDUNG` |
| Wettkampfnummer                   | Zahl     | J       | Nummer des Wettkampfs |
| Veranstaltungs-ID des Schwimmers  | Zahl     | J       | Referenz auf `PNMELDUNG` |
| Startnummer innerhalb der Staffel | Zahl     | J       | Position im Staffelverlauf (1–4) |

### `DATEIENDE`

- Vorkommen: **genau 1**
- Hinweis: Dieses Element muss **immer die letzte Zeile** der Datei sein.  
  Es besitzt **keine Attribute**.

| Attribut | Datentyp | Pflicht | Beschreibung |
|----------|----------|---------|--------------|
| *(keine)* | –        | –       | Dieses Element enthält keine Datenfelder. |


### Beispiel: Vereinsmeldeliste

Dateiname: `2002-03-10-Duisburg-SVHansaA-Me.DSV7`

```
FORMAT:Vereinsmeldeliste;7;
ERZEUGER:Schwimmsoftware;1.01;info@meinewebseite.de;
VERANSTALTUNG:EDV-Testwettkampf des SV NRW;Duisburg;50;HANDZEIT;
ABSCHNITT:1;09.03.2002;16:00;;
ABSCHNITT:2;10.03.2002;16:00;;
WETTKAMPF:1;V;1;;100;F;GL;W;;;
WETTKAMPF:2;V;1;;50;R;GL;M;;;
WETTKAMPF:3;E;2;;200;S;GL;W;;;
WETTKAMPF:4;E;2;4;100;B;GL;M;;;
WETTKAMPF:5;E;1;;100;F;GL;W;;;
WETTKAMPF:101;F;1;;100;F;GL;W;1;V;
VEREIN:SV Hansa Adorf;1234;17;GER;
ANSPRECHPARTNER:Mücke, Heinz;Kastenstr.69;12345;Adorf;GER;09999/11111;Kein Fax;
HeinzMuecke@GibtsNicht.de;
KARIMELDUNG:1;Mücke, Gerda;WKR;
KARIABSCHNITT:1;1;;
KARIABSCHNITT:1;2;;
KARIMELDUNG:2;Mücke, Heinz;AUS;
KARIABSCHNITT:2;1;:
KARIABSCHNITT:2;2;AUS;
TRAINER:1;Meyer,Paul;
PNMELDUNG:Keller, Simone;123456;4711;W;1990;;1;GER;;;
STARTPN:4711;1;00:01:01,02;
STARTPN:4711;3;00:02:38,10;
PNMELDUNG:Schumann, Sandra;123457;4712;W;1990;;;GER;;;
STARTPN:4712;1;00:01:03,30;
STARTPN:4712;3;00:02:42,52;
PNMELDUNG:Lustig, Peter;123450;4713;M;1989;;;GER;;;
PNMELDUNG:Reimer, Ralf;123451;4714;M;1989;;;GER;;;
PNMELDUNG:Buchen, Thomas;123452;4715;M;1990;;;GER;;;
PNMELDUNG:Schlimm, Ralf;123453;4716;M;1989;;;GER;;;
STMELDUNG:1;2525;JG;1989;1990;;
STARTST:2525;4;00:04:30,04;
STAFFELPERSON:2525;4;4713;1;
STAFFELPERSON:2525;4;4714;2;
STAFFELPERSON:2525;4;4715;3;
STAFFELPERSON:2525;4;4716;4;
DATEIENDE
```

## Vereinsergebnisliste

### `FORMAT`

- Vorkommen: **genau 1**
- Hinweis: Dieses Element muss **immer die erste Zeile der Datei** sein.

| Attribut  | Datentyp | Pflicht | Beschreibung |
|-----------|----------|---------|--------------|
| Listart   | ZK       | J       | Konstant: `Vereinsergebnisliste` |
| Version   | Zahl     | J       | Versionsnummer des DSV-Standards (aktuell: `7`) |

### `ERZEUGER`

- Vorkommen: **genau 1**
- Hinweis: Informationen zur Software, die die Datei erzeugt hat.

| Attribut | Datentyp | Pflicht | Beschreibung |
|----------|----------|---------|--------------|
| Software | ZK       | J       | Name der Software, die die Datei erzeugt hat |
| Version  | ZK       | J       | Versionskennung der Software |
| Kontakt  | ZK       | J       | E-Mail-Adresse des Software-Herstellers |

### `VERANSTALTUNG`

- Vorkommen: **genau 1**
- Hinweis: Beschreibung der Wettkampfveranstaltung.

| Attribut               | Datentyp | Pflicht | Beschreibung |
|------------------------|----------|---------|--------------|
| Veranstaltungsbezeichnung | ZK    | J       | Name der Veranstaltung |
| Veranstaltungsort         | ZK    | J       | Ort der Veranstaltung |
| Bahnlänge                 | ZK    | J       | Bahnlänge in Metern (`16`, `20`, `25`, `33`, `50`, `FW` oder `X` bei abweichend) |
| Zeitmessung              | ZK    | J       | Art der Zeitmessung: `HANDZEIT`, `AUTOMATISCH`, `HALBAUTOMATISCH` |

### `VERANSTALTER`

- Vorkommen: **genau 1**
- Hinweis: Angaben zum Veranstalter der Veranstaltung.

| Attribut                 | Datentyp | Pflicht | Beschreibung |
|--------------------------|----------|---------|--------------|
| Name des Veranstalters   | ZK       | J       | Name des Veranstalters |

### `AUSRICHTER`

- Vorkommen: **genau 1**
- Hinweis: Angaben zum Ausrichter der Veranstaltung inkl. Kontaktperson.

| Attribut       | Datentyp | Pflicht | Beschreibung |
|----------------|----------|---------|--------------|
| Name des Ausrichters | ZK | J | Name des Ausrichters |
| Name                | ZK       | J       | Nachname, Vorname der Kontaktperson |
| Straße              | ZK       | N       | Straße der Kontaktperson |
| PLZ                 | ZK       | N       | Postleitzahl |
| Ort                 | ZK       | N       | Ort |
| Land                | ZK       | N       | Länderkürzel nach FINA (z. B. `GER`) |
| Telefon             | ZK       | N       | Telefonnummer |
| Fax                 | ZK       | N       | Faxnummer |
| eMail               | ZK       | J       | E-Mail-Adresse der Kontaktperson |


### `ABSCHNITT`

- Vorkommen: **1 bis N**
- Hinweis: Definition der Veranstaltungsabschnitte.

| Attribut         | Datentyp | Pflicht | Beschreibung |
|------------------|----------|---------|--------------|
| Abschnittsnr.    | Zahl     | J       | Nummer des Abschnitts (max. zweistellig) |
| Abschnittsdatum  | Datum    | J       | Datum des Abschnitts (`TT.MM.JJJJ`) |
| Anfangszeit      | Uhrzeit  | J       | Beginn des Abschnitts (`HH:MM`, 24h-Format) |
| Relative Angabe  | Zeichen  | N       | `N` = echte Uhrzeit, `J` = relativ zum vorherigen Abschnitt (Standard: `N`) |

### `KAMPFGERICHT`

- Vorkommen: **0 bis N**
- Hinweis: Kampfrichter*innen-Zuordnung zu Abschnitten und Positionen.

| Attribut           | Datentyp | Pflicht | Beschreibung |
|--------------------|----------|---------|--------------|
| Abschnittsnr.      | Zahl     | J       | Abschnitt, in dem der Kampfrichter eingesetzt wurde |
| Position           | ZK       | J       | Funktion, z. B. `SCH`, `STA`, `ZR`, `ZN`, `SR`, `WR`, `AUS`, `SP`, `PKF`, `STO`, `ASCH`, `SIB`, `SAUF`, `VER`, `WKH`, `ZBV` |
| Name Kampfrichter  | ZK       | J       | Nachname, Vorname |
| Verein des Kampfrichters | ZK | J       | Verein, der den Kampfrichter gestellt hat |

### `WETTKAMPF`

- Vorkommen: **1 bis N**
- Hinweis: Detaillierte Beschreibung jedes Wettkampfs.

| Attribut                 | Datentyp | Pflicht | Beschreibung |
|--------------------------|----------|---------|--------------|
| Wettkampfnr.             | Zahl     | J       | Nummer des Wettkampfes |
| Wettkampfart             | Zeichen  | J       | `V`, `Z`, `F`, `E`, `A`, `N` |
| Abschnittsnr.            | Zahl     | J       | Nummer des Abschnitts |
| Anzahl Starter           | Zahl     | N       | Anzahl Teilnehmer (Standard: 1 bei Einzel) |
| Einzelstrecke            | Zahl     | J       | Streckenlänge in Metern (1–25000, `0` = sonstige) |
| Technik                  | Zeichen  | J       | `F`, `R`, `B`, `S`, `L`, `X` |
| Ausübung                 | ZK       | J       | `GL`, `BE`, `AR`, `ST`, `WE`, `GB`, `X` |
| Geschlecht               | Zeichen  | J       | `M`, `W`, `X` |
| Zuordnung Bestenliste    | ZK       | J       | `SW`, `MS`, `KG`, `EW`, `PA`, `XX` |
| Qualifikationswettkampfnr | Zahl    | N       | Nummer des zugehörigen Quali-Wettkampfs |
| Qualifikationswettkampfart | Zeichen | N       | `V`, `Z`, `F`, `E` |

### `WERTUNG`

- Vorkommen: **1 bis N**
- Hinweis: Definition der Wertungsklassen pro Wettkampf.

| Attribut                 | Datentyp | Pflicht | Beschreibung |
|--------------------------|----------|---------|--------------|
| Wettkampfnr.             | Zahl     | J       | Nummer des Wettkampfs |
| Wettkampfart             | Zeichen  | J       | `V`, `Z`, `F`, `E` |
| WertungsID               | Zahl     | J       | Eindeutige ID für die Wertung |
| Wertungsklasse Typ       | ZK       | J       | `JG` = Jahrgang, `AK` = Altersklasse |
| Mindest‑JG/AK            | JGAK     | J       | Kleinster Jahrgang / größte Altersklasse (offen = `0`) |
| Maximale JG/AK           | JGAK     | N       | Wenn abweichend, sonst gleich Mindestwert (`0` = „und jünger“) |
| Geschlecht               | Zeichen  | N       | `M`, `W`, `X`, `D` – Standard: vom Wettkampf übernommen |
| Wertungsname             | ZK       | J       | Freie Bezeichnung (z. B. „Jahrgang 2010 und älter“) |

### `VEREIN`

- Vorkommen: **1 bis N**
- Hinweis: Enthält Vereinsdaten für alle Vereine mit gewerteten Ergebnissen.

| Attribut             | Datentyp | Pflicht | Beschreibung |
|----------------------|----------|---------|--------------|
| Vereinsbezeichnung   | ZK       | J       | Name des Vereins |
| Vereinskennzahl      | Zahl     | J       | 4-stellige DSV-Kennzahl (bei ausländischen Vereinen: `0`) |
| Landesschwimmverband | Zahl     | J       | Nummer des LSV (1–18, Ausland: `0`, Auswahl: `99`) |
| FINA-Nationenkürzel  | ZK       | J       | 3-stelliger Ländercode nach FINA, z. B. `GER` |

### `PERSON`

- Vorkommen: **0 bis N**
- Hinweis: Detaillierte Angaben zu den gewerteten Schwimmer*innen.

| Attribut                  | Datentyp | Pflicht | Beschreibung |
|---------------------------|----------|---------|--------------|
| Name                      | ZK       | J       | Nachname, Vorname |
| DSV-ID Schwimmer          | Zahl     | J       | 6-stellige DSV-ID (`0` falls nicht vorhanden) |
| Veranstaltungs-ID         | Zahl     | J       | Eindeutige ID der Person in dieser Veranstaltung |
| Geschlecht                | Zeichen  | J       | `M` = männlich, `W` = weiblich, `D` = divers |
| Jahrgang                  | Zahl     | J       | Vierstelliger Jahrgang (z. B. `2008`) |
| Altersklasse              | Zahl     | N       | Optional |
| Nationalität 1            | ZK       | N       | FINA-Code (z. B. `GER`) |
| Nationalität 2            | ZK       | N       | Weitere Staatsangehörigkeit |
| Nationalität 3            | ZK       | N       | Weitere Staatsangehörigkeit |

### `PERSONENERGEBNIS`

- Vorkommen: **0 bis N**
- Hinweis: Einzelergebnis eines Schwimmers in einer bestimmten Wertung.

| Attribut                        | Datentyp | Pflicht | Beschreibung |
|---------------------------------|----------|---------|--------------|
| Veranstaltungs-ID des Schwimmers | Zahl    | J       | Referenz auf `PERSON` |
| Wettkampf-Nr                    | Zahl     | J       | Nummer des Wettkampfs |
| Wettkampfart                    | Zeichen  | J       | `V`, `Z`, `F`, `E`, `A`, `N` |
| WertungsID                      | Zahl     | J       | Referenz auf `WERTUNG` |
| Platz                           | Zahl     | J       | Platzierung (bei Disqualifikation: `0`) |
| Endzeit                         | Zeit     | J       | Endzeit (z. B. `00:01:03,20`) |
| Grund der Nichtwertung          | ZK       | N       | `DS`, `NA`, `AB`, `AU`, `ZU` |
| Disqualifikationsbemerkung      | ZK       | N       | Freitext zu Disqualifikation |
| Erhöhtes nachträgliches Meldegeld | Zeichen | N       | `E`, `F`, `N` |

### `PNZWISCHENZEIT`

- Vorkommen: **0 bis N**
- Hinweis: Zwischenzeit eines Einzelstarts eines Schwimmers.

| Attribut                  | Datentyp | Pflicht | Beschreibung |
|---------------------------|----------|---------|--------------|
| Veranstaltungs-ID des Schwimmers | Zahl | J | Referenz auf `PERSON` |
| Wettkampf-Nr              | Zahl     | J       | Nummer des Wettkampfs |
| Wettkampfart              | Zeichen  | J       | `V`, `Z`, `F`, `E`, `A`, `N` |
| Distanz                   | Zahl     | J       | Zurückgelegte Distanz in Metern |
| Zwischenzeit              | Zeit     | J       | Zwischenzeit (`HH:MM:SS,hh`) |

### `PNREAKTION`

- Vorkommen: **0 bis N**
- Hinweis: Reaktionszeit eines Schwimmers beim Start.

| Attribut                  | Datentyp | Pflicht | Beschreibung |
|---------------------------|----------|---------|--------------|
| Veranstaltungs-ID des Schwimmers | Zahl | J | Referenz auf `PERSON` |
| Wettkampf-Nr              | Zahl     | J       | Nummer des Wettkampfs |
| Wettkampfart              | Zeichen  | J       | `V`, `Z`, `F`, `E`, `A`, `N` |
| Art                       | Zeichen  | N       | `+` = Start nach Signal (Standard), `-` = Frühstart |
| Reaktionszeit             | Zeit     | J       | Reaktionszeit (`HH:MM:SS,hh`) |

### `STAFFEL`

- Vorkommen: **0 bis N**
- Hinweis: Angaben zur Staffelmannschaft.

| Attribut                      | Datentyp | Pflicht | Beschreibung |
|-------------------------------|----------|---------|--------------|
| Nummer der Mannschaft         | Zahl     | J       | Laufende Nummer der Mannschaft |
| Veranstaltungs-ID der Staffel | Zahl     | J       | Eindeutige ID innerhalb der Veranstaltung |
| Wertungsklasse Typ            | ZK       | J       | `JG` = Jahrgang, `AK` = Altersklasse |
| Mindest‑JG/AK                 | JGAK     | J       | Mindestjahrgang / größte Altersklasse |
| Maximale JG/AK                | JGAK     | N       | Wenn abweichend, sonst wie Mindestwert |

### `STAFFELPERSON`

- Vorkommen: **0 bis N**
- Hinweis: Schwimmer*innen einer Staffel in einem bestimmten Wettkampf.

| Attribut                          | Datentyp | Pflicht | Beschreibung |
|-----------------------------------|----------|---------|--------------|
| Veranstaltungs-ID der Staffel     | Zahl     | J       | Referenz auf `STAFFEL` |
| Wettkampfnr.                      | Zahl     | J       | Nummer des Wettkampfs |
| Wettkampfart                      | Zeichen  | J       | `V`, `Z`, `F`, `E`, `A`, `N` |
| Name                              | ZK       | J       | Nachname, Vorname |
| DSV-ID Schwimmer                  | Zahl     | J       | DSV-ID (`0`, falls unbekannt) |
| Startnummer innerhalb der Staffel | Zahl     | J       | Staffelposition (1–4) |
| Geschlecht                        | Zeichen  | J       | `M`, `W`, `D` |
| Jahrgang                          | Zahl     | J       | Vierstelliger Jahrgang |
| Altersklasse                      | Zahl     | N       | Optional |
| Nationalität 1                    | ZK       | N       | FINA-Code, z. B. `GER` |
| Nationalität 2                    | ZK       | N       | Weitere Staatsangehörigkeit |
| Nationalität 3                    | ZK       | N       | Weitere Staatsangehörigkeit |

### `STAFFELERGEBNIS`

- Vorkommen: **0 bis N**
- Hinweis: Ergebnis einer Staffel in einer bestimmten Wertung.

| Attribut                          | Datentyp | Pflicht | Beschreibung |
|-----------------------------------|----------|---------|--------------|
| Veranstaltungs-ID der Staffel     | Zahl     | J       | Referenz auf `STAFFEL` |
| Wettkampf-Nr                      | Zahl     | J       | Nummer des Wettkampfs |
| Wettkampfart                      | Zeichen  | J       | `V`, `Z`, `F`, `E`, `A`, `N` |
| WertungsID                        | Zahl     | J       | Referenz auf `WERTUNG` |
| Platz                             | Zahl     | J       | Platzierung (bei DQ: `0`) |
| Endzeit                           | Zeit     | J       | Zeit der Staffel |
| Grund der Nichtwertung            | ZK       | N       | `DS`, `NA`, `AB`, `AU`, `ZU` |
| Startnummer disqualifizierter Schwimmer | Zahl | N | Staffelplatz (1–4) oder `0` für generisch |
| Disqualifikationsbemerkung        | ZK       | N       | Freitext |
| Erhöhtes nachträgliches Meldegeld | Zeichen  | N       | `E`, `F`, `N` |

### `STZWISCHENZEIT`

- Vorkommen: **0 bis N**
- Hinweis: Zwischenzeiten für Staffelstarts, bezogen auf die einzelnen Streckenabschnitte.

| Attribut                          | Datentyp | Pflicht | Beschreibung |
|-----------------------------------|----------|---------|--------------|
| Veranstaltungs-ID der Staffel     | Zahl     | J       | Referenz auf `STAFFEL` |
| Wettkampf-Nr                      | Zahl     | J       | Nummer des Wettkampfs |
| Wettkampfart                      | Zeichen  | J       | `V`, `Z`, `F`, `E`, `A`, `N` |
| Startnummer innerhalb der Staffel | Zahl     | J       | Schwimmerposition (1–4) |
| Distanz                           | Zahl     | J       | Zurückgelegte Distanz in Metern |
| Zwischenzeit                      | Zeit     | J       | Zwischenzeit (`HH:MM:SS,hh`) |

### `STABLOESE`

- Vorkommen: **0 bis N**
- Hinweis: Reaktionszeit beim Staffelwechsel (Stabübergabe).

| Attribut                          | Datentyp | Pflicht | Beschreibung |
|-----------------------------------|----------|---------|--------------|
| Veranstaltungs-ID der Staffel     | Zahl     | J       | Referenz auf `STAFFELERGEBNIS` |
| Wettkampf-Nr                      | Zahl     | J       | Nummer des Wettkampfs |
| Wettkampfart                      | Zeichen  | J       | `V`, `Z`, `F`, `E`, `A`, `N` |
| Startnummer innerhalb der Staffel | Zahl     | J       | Staffelposition (1–4) |
| Art                               | Zeichen  | N       | `+` = gültig, `-` = Frühstart (Standard: `+`) |
| Reaktionszeit                     | Zeit     | J       | Zeit beim Staffelwechsel (`HH:MM:SS,hh`) |

### `DATEIENDE`

- Vorkommen: **genau 1**
- Hinweis: Dieses Element **muss die letzte Zeile** der Datei sein.

| Attribut | Datentyp | Pflicht | Beschreibung |
|----------|----------|---------|--------------|
| *(keine)* | –        | –       | Dieses Element hat **keine Attribute**. |

### Beispiel: Vereinsergebnisliste

Dateiname: `2002-03-10-Duisburg-SVHansaA-Pr.DSV7`

```txt
FORMAT:VEREINSERGEBNISLISTE;7;
ERZEUGER:Schwimmsoftware;1.01;info@meinewebseite.de;
VERANSTALTUNG:EDV-Testwettkampf des SV NRW;Duisburg;25;HANDZEIT;
VERANSTALTER:Schwimmverband NRW;
AUSRICHTER:SC Duisburg;Biene, Petra;Wabenstr. 69;47055;Duisburg;GER;0888/22222;
0888/22223;PetraBiene@GibtsNicht.de;
ABSCHNITT:1;09.03.2002;16:00;;
ABSCHNITT:2;10.03.2002;16:00;;

KAMPFGERICHT:1;SPR;Heinze, Wolfgang; SV Hansa Adorf;

WETTKAMPF:1;V;1;;100;F;GL;W;SW;;;
WETTKAMPF:2;V;1;;50;R;GL;M;SW;;;
WETTKAMPF:3;E;2;;200;S;GL;W;SW;;;
WETTKAMPF:4;E;2;4;100;B;GL;M;SW;;;
WETTKAMPF:5;E;1;;100;F;GL;W;SW;;;
WETTKAMPF:101;F;1;;100;F;GL;W;SW;1;V;

WERTUNG:1;V;1;JG;0;9999;;OFFENE WERTUNG;
WERTUNG:1;V,2;JG;1989;;;JAHRGANG 1989;
WERTUNG:1;V;3;JG;1990;;;JAHRGANG 1990;
WERTUNG:2;V;4;JG;0;9999;;OFFENE WERTUNG;
WERTUNG:3;E;5;JG;0;9999;;OFFENE WERTUNG;
WERTUNG:4;E;6;JG;0;9999;;OFFENE WERTUNG;
WERTUNG:5;F,7;JG;0;9999;;OFFENE WERTUNG;

VEREIN:SV Hansa Adorf;1234;17;GER;

PERSON:Keller, Simone;123456;4711;W;1990;;GER;;;

PERSONENERGEBNIS:4711;1;V;1;7;00:01:00,82;;;;
PERSONENERGEBNIS:4711;1;V;3;1;00:01:00,82;;;;

PNZWISCHENZEIT:4711;1;V;50;00:00:29,03;

STAFFEL:1;2525;JG;1989;1990;

STAFFELPERSON:2525;4;E;Lustig, Peter;123450;1;M;1989;;GER;;;
STAFFELPERSON:2525;4;E;Reimer, Ralf;123451;2;M;1989;;GER;;;
STAFFELPERSON:2525;4;E;Buchen, Thomas;123452;3;M;1990;;GER;;;
STAFFELPERSON:2525;4;E;Schlimm, Ralf;123453;4;M;1989;;GER;;;

STAFFELERGEBNIS:2525;4;E;4;2;00:04:30,84;;;;;

STZWISCHENZEIT:2525;4;E;1;100;00:01:03,61;
STZWISCHENZEIT:2525;4;E;2;200;00:02:10,02;
STZWISCHENZEIT:2525;4;E;3;300;00:03:22,83;
STZWISCHENZEIT:2525;4;E;4;400;00:04:30,84;

DATEIENDE
```

## Wettkampfergebnisliste

### `FORMAT`

- Vorkommen: **genau 1**
- Hinweis: Dieses Element muss **immer die erste Zeile** der Datei sein.

| Attribut  | Datentyp | Pflicht | Beschreibung |
|-----------|----------|---------|--------------|
| Listart   | ZK       | J       | Konstant: `Wettkampfergebnisliste` |
| Version   | Zahl     | J       | Versionsnummer des DSV-Standards (aktuell: `7`) |

### `ERZEUGER`

- Vorkommen: **genau 1**
- Hinweis: Informationen zur Software, die die Datei erzeugt hat.

| Attribut | Datentyp | Pflicht | Beschreibung |
|----------|----------|---------|--------------|
| Software | ZK       | J       | Name der Software, die die Datei erzeugt hat |
| Version  | ZK       | J       | Versionskennung der Software |
| Kontakt  | ZK       | J       | E-Mail-Adresse des Software-Herstellers |

### `VERANSTALTUNG`

- Vorkommen: **genau 1**
- Hinweis: Beschreibung der Wettkampfveranstaltung.

| Attribut               | Datentyp | Pflicht | Beschreibung |
|------------------------|----------|---------|--------------|
| Veranstaltungsbezeichnung | ZK    | J       | Name der Veranstaltung |
| Veranstaltungsort         | ZK    | J       | Ort der Veranstaltung |
| Bahnlänge                 | ZK    | J       | Bahnlänge: `16`, `20`, `25`, `33`, `50`, `FW` oder `X` (abweichend) |
| Zeitmessung              | ZK    | J       | `HANDZEIT`, `AUTOMATISCH`, `HALBAUTOMATISCH` |

### `VERANSTALTER`

- Vorkommen: **genau 1**
- Hinweis: Angaben zum Veranstalter der Veranstaltung.

| Attribut                 | Datentyp | Pflicht | Beschreibung |
|--------------------------|----------|---------|--------------|
| Name des Veranstalters   | ZK       | J       | Name des Veranstalters |

### `AUSRICHTER`

- Vorkommen: **genau 1**
- Hinweis: Angaben zum Ausrichter inkl. Kontaktperson.

| Attribut       | Datentyp | Pflicht | Beschreibung |
|----------------|----------|---------|--------------|
| Name des Ausrichters | ZK  | J       | Name des Ausrichters |
| Name                | ZK   | J       | Nachname, Vorname der Kontaktperson |
| Straße              | ZK   | N       | Straße der Kontaktperson |
| PLZ                 | ZK   | N       | Postleitzahl |
| Ort                 | ZK   | N       | Ort |
| Land                | ZK   | N       | FINA-Länderkürzel, z. B. `GER` |
| Telefon             | ZK   | N       | Telefonnummer |
| Fax                 | ZK   | N       | Faxnummer |
| eMail               | ZK   | J       | E-Mail-Adresse der Kontaktperson |

### `ABSCHNITT`

- Vorkommen: **1 bis N**
- Hinweis: Definition der Veranstaltungsabschnitte.

| Attribut         | Datentyp | Pflicht | Beschreibung |
|------------------|----------|---------|--------------|
| Abschnittsnr.    | Zahl     | J       | Nummer des Abschnitts (max. zweistellig) |
| Abschnittsdatum  | Datum    | J       | Datum im Format `TT.MM.JJJJ` |
| Anfangszeit      | Uhrzeit  | J       | Beginn des Abschnitts (`HH:MM`, 24h) |
| Relative Angabe  | Zeichen  | N       | `N` = echte Uhrzeit, `J` = relativ zum vorherigen Abschnitt (Standard: `N`) |

### `KAMPFGERICHT`

- Vorkommen: **0 bis N**
- Hinweis: Eintrag pro Kampfrichter-Einsatz im Abschnitt.

| Attribut               | Datentyp | Pflicht | Beschreibung |
|------------------------|----------|---------|--------------|
| Abschnittsnr.          | Zahl     | J       | Referenz auf Abschnitt |
| Position               | ZK       | J       | Funktion, z. B. `SCH`, `STA`, `ZR`, `ZN`, `SR`, `WR`, `AUS`, `SP`, `PKF`, `STO`, `ASCH`, `SIB`, `SAUF`, `VER`, `ZBV`, `WKH` |
| Name Kampfrichter      | ZK       | J       | Nachname, Vorname |
| Verein des Kampfrichters | ZK     | J       | Verein, der den Kampfrichter gestellt hat |

### `WETTKAMPF`

- Vorkommen: **1 bis N**
- Hinweis: Definition aller durchgeführten Wettkämpfe.

| Attribut                 | Datentyp | Pflicht | Beschreibung |
|--------------------------|----------|---------|--------------|
| Wettkampfnr.             | Zahl     | J       | Nummer des Wettkampfs (max. 3-stellig) |
| Wettkampfart             | Zeichen  | J       | `V`, `Z`, `F`, `E`, `A`, `N` |
| Abschnittsnr.            | Zahl     | J       | Nummer des Abschnitts |
| Anzahl Starter           | Zahl     | N       | Anzahl Teilnehmer (Standard: `1`) |
| Einzelstrecke            | Zahl     | J       | Strecke in Metern (`1–25000`, `0` = sonstige) |
| Technik                  | Zeichen  | J       | `F`, `R`, `B`, `S`, `L`, `X` |
| Ausübung                 | ZK       | J       | `GL`, `BE`, `AR`, `ST`, `WE`, `GB`, `X` |
| Geschlecht               | Zeichen  | J       | `M`, `W`, `X` |
| Zuordnung Bestenliste    | ZK       | J       | `SW`, `MS`, `KG`, `EW`, `PA`, `XX` |
| Qualifikationswettkampfnr | Zahl    | N       | Nr. des Qualifikationswettkampfs |
| Qualifikationswettkampfart | Zeichen | N       | `V`, `Z`, `F`, `E` |

### `WERTUNG`

- Vorkommen: **1 bis N**
- Hinweis: Definition der Wertungsklassen innerhalb eines Wettkampfs.

| Attribut                 | Datentyp | Pflicht | Beschreibung |
|--------------------------|----------|---------|--------------|
| Wettkampfnr.             | Zahl     | J       | Referenz auf Wettkampf |
| Wettkampfart             | Zeichen  | J       | `V`, `Z`, `F`, `E`, `A`, `N` |
| WertungsID               | Zahl     | J       | Eindeutige ID der Wertung |
| Wertungsklasse Typ       | ZK       | J       | `JG` = Jahrgang, `AK` = Altersklasse |
| Mindest‑JG/AK            | JGAK     | J       | Kleinster Jahrgang / größte Altersklasse (offen: `0`) |
| Maximale JG/AK           | JGAK     | N       | Falls abweichend, sonst wie Mindestwert |
| Geschlecht               | Zeichen  | N       | `M`, `W`, `X` – wenn leer: aus Wettkampf übernommen |
| Wertungsname             | ZK       | J       | Freie Bezeichnung (z. B. „Jahrgang 2008 und älter“) |

### `VEREIN`

- Vorkommen: **1 bis N**
- Hinweis: Liste aller teilnehmenden Vereine.

| Attribut             | Datentyp | Pflicht | Beschreibung |
|----------------------|----------|---------|--------------|
| Vereinsbezeichnung   | ZK       | J       | Name des Vereins |
| Vereinskennzahl      | Zahl     | J       | 4-stellige DSV-Kennung (`0` für ausländische Vereine) |
| Landesschwimmverband | Zahl     | J       | Nummer des LSV (1–18, Ausland: `0`, Auswahlmannschaften: `99`) |
| FINA-Nationenkürzel  | ZK       | J       | 3-stelliger FINA-Ländercode, z. B. `GER` |

### `PNERGEBNIS`

- Vorkommen: **0 bis N**
- Hinweis: Einzelwettkampfergebnis eines Schwimmers in einer bestimmten Wertung.

| Attribut                         | Datentyp | Pflicht | Beschreibung |
|----------------------------------|----------|---------|--------------|
| Wettkampfnr.                     | Zahl     | J       | Nummer des Wettkampfs |
| Wettkampfart                     | Zeichen  | J       | `V`, `Z`, `F`, `E`, `A`, `N` |
| WertungsID                       | Zahl     | J       | Referenz auf `WERTUNG` |
| Platz                            | Zahl     | J       | Platzierung (`0` bei Disqualifikation) |
| Grund der Nichtwertung           | ZK       | N       | `DS`, `NA`, `AB`, `AU`, `ZU` |
| Name                             | ZK       | J       | Nachname, Vorname |
| DSV-ID Schwimmer                 | Zahl     | J       | 6-stellige DSV-ID (`0` falls unbekannt) |
| Veranstaltungs-ID des Schwimmers| Zahl     | J       | Interne ID innerhalb dieser Veranstaltung |
| Geschlecht                       | Zeichen  | J       | `M`, `W`, `D` |
| Jahrgang                         | Zahl     | J       | Vierstelliger Jahrgang |
| Altersklasse                     | Zahl     | N       | Optional |
| Verein                           | ZK       | J       | Name des Vereins |
| Vereinskennzahl                  | Zahl     | J       | DSV-Kennung des Vereins |
| Endzeit                          | Zeit     | J       | Endzeit (`HH:MM:SS,hh`) |
| Disqualifikationsbemerkung       | ZK       | N       | Freitext zum DQ-Grund |
| Erhöhtes nachträgliches Meldegeld| Zeichen  | N       | `E`, `F`, `N` |
| Nationalität 1                   | ZK       | N       | FINA-Code (z. B. `GER`) |
| Nationalität 2                   | ZK       | N       | Weitere Staatsangehörigkeit |
| Nationalität 3                   | ZK       | N       | Weitere Staatsangehörigkeit |

### `PNZWISCHENZEIT`

- Vorkommen: **0 bis N**
- Hinweis: Zwischenzeit eines Schwimmers über eine bestimmte Distanz.

| Attribut                         | Datentyp | Pflicht | Beschreibung |
|----------------------------------|----------|---------|--------------|
| Veranstaltungs-ID des Schwimmers| Zahl     | J       | Referenz auf `PNERGEBNIS` |
| Wettkampf-Nr                    | Zahl     | J       | Nummer des Wettkampfs |
| Wettkampfart                    | Zeichen  | J       | `V`, `Z`, `F`, `E`, `A`, `N` |
| Distanz                         | Zahl     | J       | Zurückgelegte Distanz in Metern |
| Zwischenzeit                    | Zeit     | J       | Zwischenzeit (`HH:MM:SS,hh`) |

### `PNREAKTION`

- Vorkommen: **0 bis N**
- Hinweis: Startreaktionszeit eines Schwimmers.

| Attribut                         | Datentyp | Pflicht | Beschreibung |
|----------------------------------|----------|---------|--------------|
| Veranstaltungs-ID des Schwimmers| Zahl     | J       | Referenz auf `PNERGEBNIS` |
| Wettkampf-Nr                    | Zahl     | J       | Nummer des Wettkampfs |
| Wettkampfart                    | Zeichen  | J       | `V`, `Z`, `F`, `E`, `A`, `N` |
| Art                             | Zeichen  | N       | `+` = normal, `-` = Frühstart (Standard: `+`) |
| Reaktionszeit                   | Zeit     | J       | Reaktionszeit (`HH:MM:SS,hh`) |

### `STAFFELERGEBNIS`

- Vorkommen: **0 bis N**
- Hinweis: Ergebnis einer Staffel in einer bestimmten Wertung.

| Attribut                            | Datentyp | Pflicht | Beschreibung |
|-------------------------------------|----------|---------|--------------|
| Wettkampfnr.                        | Zahl     | J       | Nummer des Wettkampfs |
| Wettkampfart                        | Zeichen  | J       | `V`, `Z`, `F`, `E`, `A`, `N` |
| WertungsID                          | Zahl     | J       | Referenz auf `WERTUNG` |
| Platz                               | Zahl     | J       | Platzierung (`0` bei Disqualifikation) |
| Grund der Nichtwertung              | ZK       | N       | `DS`, `NA`, `AB`, `AU`, `ZU` |
| Nummer der Mannschaft               | Zahl     | J       | Nummer der Mannschaft |
| Veranstaltungs-ID der Staffel       | Zahl     | J       | Referenz auf `STAFFEL` |
| Verein                              | ZK       | J       | Name des Vereins |
| Vereinskennzahl                     | Zahl     | J       | 4-stellige DSV-Vereins-ID |
| Endzeit                             | Zeit     | J       | Endzeit (`HH:MM:SS,hh`) |
| Startnummer disqualifizierter Schwimmer | Zahl | N       | Staffelposition (1–4) oder `0` |
| Disqualifikationsbemerkung          | ZK       | N       | Freitext |
| Erhöhtes nachträgliches Meldegeld   | Zeichen  | N       | `E`, `F`, `N` |

### `STAFFELPERSON`

- Vorkommen: **0 bis N**
- Hinweis: Detaillierte Angaben zu den Staffelteilnehmer*innen.

| Attribut                          | Datentyp | Pflicht | Beschreibung |
|-----------------------------------|----------|---------|--------------|
| Veranstaltungs-ID der Staffel     | Zahl     | J       | Referenz auf `STAFFEL` |
| Wettkampfnr.                      | Zahl     | J       | Nummer des Wettkampfs |
| Wettkampfart                      | Zeichen  | J       | `V`, `Z`, `F`, `E`, `A`, `N` |
| Name                              | ZK       | J       | Nachname, Vorname |
| DSV-ID Schwimmer                  | Zahl     | J       | 6-stellige DSV-ID (`0` falls unbekannt) |
| Startnummer innerhalb der Staffel | Zahl     | J       | Position im Staffelverlauf (1–4) |
| Geschlecht                        | Zeichen  | J       | `M`, `W`, `D` |
| Jahrgang                          | Zahl     | J       | Vierstelliger Jahrgang |
| Altersklasse                      | Zahl     | N       | Optional |
| Nationalität 1                    | ZK       | N       | FINA-Code (z. B. `GER`) |
| Nationalität 2                    | ZK       | N       | Weitere Staatsangehörigkeit |
| Nationalität 3                    | ZK       | N       | Weitere Staatsangehörigkeit |

### `STZWISCHENZEIT`

- Vorkommen: **0 bis N**
- Hinweis: Zwischenzeiten für einzelne Schwimmer*innen in der Staffel.

| Attribut                          | Datentyp | Pflicht | Beschreibung |
|-----------------------------------|----------|---------|--------------|
| Veranstaltungs-ID der Staffel     | Zahl     | J       | Referenz auf `STAFFEL` |
| Wettkampf-Nr                      | Zahl     | J       | Nummer des Wettkampfs |
| Wettkampfart                      | Zeichen  | J       | `V`, `Z`, `F`, `E`, `A`, `N` |
| Startnummer innerhalb der Staffel | Zahl     | J       | Staffelposition (1–4) |
| Distanz                           | Zahl     | J       | Zurückgelegte Distanz in Metern |
| Zwischenzeit                      | Zeit     | J       | Zwischenzeit (`HH:MM:SS,hh`) |

### `STABLOESE`

- Vorkommen: **0 bis N**
- Hinweis: Reaktionszeit beim Staffelwechsel.

| Attribut                          | Datentyp | Pflicht | Beschreibung |
|-----------------------------------|----------|---------|--------------|
| Veranstaltungs-ID der Staffel     | Zahl     | J       | Referenz auf `STAFFELERGEBNIS` |
| Wettkampf-Nr                      | Zahl     | J       | Nummer des Wettkampfs |
| Wettkampfart                      | Zeichen  | J       | `V`, `Z`, `F`, `E`, `A`, `N` |
| Startnummer innerhalb der Staffel | Zahl     | J       | Staffelposition (1–4) |
| Art                               | Zeichen  | N       | `+` = normal, `-` = Frühstart (Standard: `+`) |
| Reaktionszeit                     | Zeit     | J       | Zeit (`HH:MM:SS,hh`) |

### `DATEIENDE`

- Vorkommen: **genau 1**
- Hinweis: Muss die **letzte Zeile** der Datei sein.

| Attribut | Datentyp | Pflicht | Beschreibung |
|----------|----------|---------|--------------|
| *(keine)* | –        | –       | Dieses Element enthält **keine Attribute** |


### Beispiel: Wettkampfergebnisliste

Dateiname: `2002-03-10-Duisburg-Pr.DSV7`

```txt
FORMAT:WETTKAMPFERGEBNISLISTE;7;
ERZEUGER:Schwimmsoftware;1.01;info@meinewebseite.de;
VERANSTALTUNG:EDV-Testwettkampf des SV NRW;Duisburg;25;HANDZEIT;
VERANSTALTER:Schwimmverband NRW;
AUSRICHTER:SC Duisburg;Biene, Petra;Wabenstr. 69;47055;Duisburg;GER;0888/22222;
0888/22223;PetraBiene@GibtsNicht.de;
ABSCHNITT:1;09.03.2002;16:00;;
ABSCHNITT:2;10.03.2002;16:00;;
KAMPFGERICHT:1;SPR;Heinze, Wolfgang; SV Hansa Adorf;
WETTKAMPF:1;V;1;;100;F;GL;W;SW;;;
WETTKAMPF:2;V;1;;50;R;GL;M;SW;;;
WETTKAMPF:3;E;2;;200;S;GL;W;SW;;;
WETTKAMPF:4;E;2;4;100;B;GL;M;SW;;;
WETTKAMPF:5;E;1;;100;F;GL;W;SW;;;
WETTKAMPF:101;F;1;;100;F;GL;W;SW;1;V;
WERTUNG:1;V;1;JG;0;9999;;OFFENE WERTUNG;
WERTUNG:1;V,2;JG;1989;;;JAHRGANG 1989;
WERTUNG:1;V;3;JG;1990;;;JAHRGANG 1990;
WERTUNG:2;V;4;JG;0;9999;;OFFENE WERTUNG;
WERTUNG:3;E;5;JG;0;9999;;OFFENE WERTUNG;
WERTUNG:4;E;6;JG;0;9999;;OFFENE WERTUNG;
WERTUNG:5;F,7;JG;0;9999;;OFFENE WERTUNG;
VEREIN:SV Hansa Adorf;1234;17;GER;
VEREIN:Delphin Burgstadt;1235;10;GER;
VEREIN:SC Wfr. Cleve;1236;10;GER;
VEREIN:SC Duisburg;1237;10;GER;
VEREIN:SG Essen-Nord;1238;10;GER;
PNERGEBNIS:1;V;1;7;;Keller, Simone;123456;4711;W;1990;;SV Hansa Adorf;1234;00:01:00,82;;;GER;;;
PNERGEBNIS:1;V;3;1;;Keller, Simone;123456;4711;W;1990;;SV Hansa Adorf;1234;00:01:00,82;;;GER;;;
PNZWISCHENZEIT:4711;1;V;50;00:00:29,06;
PNERGEBNIS:1;V;1;8;;Evers, Claudia;123459;5001;W;1990;;SC Duisburg;1237;00:01:00,93;;;GER;;;
PNERGEBNIS:1;V;3;;2;;Evers, Claudia;123459;5001;W;1990;;SC Duisburg;1237;00:01:00,93;;;GER;;;
PNZWISCHENZEIT:5001;1;V;50;00:00:29,07;
PNERGEBNIS:1;V;1;9;;Post, Nicola;123440;5002;W;1990;;SG Essen-Nord;1238;1:01,44;;;GER;;;
PNERGEBNIS:1;V;3;5;;Post, Nicola;123440;5002;W;1990;;SG Essen-Nord;1238;1:01,44;;;GER;;;
PNZWISCHENZEIT:5002;1;V;50;0:30,00;
STERGEBNIS:4;E;6;1;;1;2012;Delphin Burgstadt;1235;00:04:29,74;;;;
STAFFELPERSON:2012;4;E;Lücke, Volker;123437;1;M;1989;;GER;;;
STAFFELPERSON:2012;4;E;Heider, Oliver;123435;2;M;1990;;GER;;;
STAFFELPERSON:2012;4;E;Berger, Thomas;123438;3;M;1990;;GER;;;
STAFFELPERSON:2012;4;E;Schön, Holger;123439;4;M;1989;;GER;;;
STZWISCHENZEIT:2012;4;E,1;100;00:01:04,11;
STZWISCHENZEIT:2012;4;E,2;200;00:02:10,82;
STZWISCHENZEIT:2012;4;E,3;300;00:03:20,73;
STZWISCHENZEIT:2012;4;E,4;400;00:04:29,74;
DATEIENDE
```

## 

## Hinweiß
_(Hinweis: Dieses Dokument ist automatisch aus der DSV7-Spezifikation erzeugt worden und ersetzt **nicht** das offizielle Dokument. Es dient der technischen Verarbeitung.)_

