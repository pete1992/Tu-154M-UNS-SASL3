# Live-Test: clock24 und termo

Datum: 26.09.2026, Messungen ungefähr 17:13–17:30 UTC.
Ziel: `I:/X-Plane 12/Aircraft/Laminar Research/Tu-154M-UNS-SASL3`.
X-Plane wurde für den Test gestartet; EDDV, Ramp 60A, Lufthansa-Livery, Flugzeug am Boden.
Keine Port-Logik und keine Plugin-Binärdatei wurden während dieser Abnahme verändert.

## Methode

- Native Cockpit-Sichtprüfung über Computer Use; Messwerte und reversible Testeingaben über die
  [lokale X-Plane Web API](https://developer.x-plane.com/article/x-plane-web-api/).
- Kalt- und Warmstart als neue Flüge über die dokumentierte
  [Flight Initialization API](https://developer.x-plane.com/article/flight-initialization-api/).
- Insgesamt 206 gespeicherte Mess-Snapshots in der Testsession; die relevanten Ergebnisse sind unten zusammengefasst.
- Rechte Stromversorgung über die tatsächlichen Schalter `bus27_connect`, `bus27_vu2`, `bat2_on`, `bat4_on`
  abgeschaltet, nicht durch Überschreiben der erzeugten Busspannung. APU und APU-Startsequenz waren aus.
- Installierte `plugins/xtlua/64/win.xpl`, SHA-256:
  `2F8349C91BEEE9C99A8331D99B485B80F69D75D362D584128742C92A606E79BF`.
- REST-Abfragen sind keine atomaren Frame-Snapshots. Kleine Uhrdifferenzen während laufender Simulation
  werden deshalb nicht als Rechenfehler interpretiert.

## Ergebnisse

| Prüfung | Beobachtung | Ergebnis |
| --- | --- | --- |
| Ausgangszustand | Rechte Versorgung 28,5 V; OAT und Anzeige jeweils etwa 24,955 °C | Bestanden |
| Strom aus | Anzeige läuft gedämpft auf −55 °C; bei 0 V zuletzt −54,99986 °C | Bestanden |
| Strom wieder an | Anzeige kehrt gedämpft zur tatsächlichen OAT zurück, ohne beobachtetes Überschwingen | Bestanden |
| Pause mitten im Übergang | Zwölf Stichproben unverändert bei −34,346306 °C; nach Fortsetzen wieder normale Reaktion | Bestanden |
| UTC-Sprünge | 06:00, 12:00, 18:00, 23:59:59, 00:00 und beliebige Zwischenzeit | Bestanden |
| UTC-Rechenvergleich | Maximal 0,0000975° Stunden- bzw. 0,0023° Minutenabweichung zur zeitversetzt gelesenen UTC | Bestanden |
| Roter Uhrzeiger | Initial 312; extern auf 307 gesetzt und nicht vom Port zurückgeschrieben; anschließend 312 wiederhergestellt | Bestanden |
| Laufendes Replay | Replay aktiv und nicht pausiert; Uhr folgt zurückgesetzter Aufnahmezeit, Temperatur bleibt aktuell; normale Rückkehr | Bestanden |
| Sichtprüfung Uhr | Stundenzeiger sichtbar bei 6 bzw. 12; roter Zeiger bleibt dabei stehen | Bestanden |
| Sichtprüfung Temperatur | Sowohl Pilotenthermometer als auch OAT-Anzeige am Flugingenieurpanel zeigen etwa +25 °C bzw. stromlos −55 °C | Bestanden |
| Vollständiger Aircraft-Reload | Beide Ports anschließend aktiv; roter Zeiger neu initialisiert auf 251 und stabil | Bestanden |
| Neuer Cold-and-dark-Flug | Alle drei Engines aus, rechte Versorgung 0 V, Temperatur −55 °C; Uhr läuft, roter Zeiger bleibt 251 | Bestanden |
| Neuer Engines-running-Flug | Alle drei Engines laufen, Versorgung 28,5 V, Temperatur etwa 24,955 °C; roter Zeiger weiterhin 251 | Bestanden |
| Laufzeitlogs | Kein zugehöriger XTLua- oder SASL-Fehler; erfolgreiche Modulinitialisierung, Relinking und beide Startkonfigurationen protokolliert | Bestanden |

Ein erster Replay-Versuch am Aufnahmeende war pausiert und zählt ausdrücklich nicht als Nachweis für laufendes Replay.
Der erfolgreiche Wiederholungstest sprang zum Aufnahmebeginn und spielte vorwärts ab.
Die Reload-Anforderung überschritt das fünfsekündige HTTP-Zeitlimit; sie wurde nicht blind wiederholt.
Der tatsächliche Reload wurde anschließend über Cockpit, neue Initialisierung, Logs und Messwerte bestätigt.

## Dämpfung nach Reload

Zusätzlich wurde der Stromsprung nach Reload wiederholt. Eine Regression von `ln(|Anzeige − Ziel|)` gegen
die Aufnahmezeit, beschränkt auf Fehler von 0,1 bis 75 °C, ergibt folgende angenäherte Abklingraten:

| Übergang | Vor Reload | Nach Reload |
| --- | --- | --- |
| Strom aus | 5,269 s⁻¹ | 5,246 s⁻¹ |
| Strom an | 5,234 s⁻¹ | 5,292 s⁻¹ |

Die Abweichung liegt bei ungefähr einem Prozent. Das ist mit Abtastung und variabler Framedauer vereinbar
und liefert keinen Hinweis auf einen doppelt laufenden Timer. Es ist kein framegenauer Beweis nativer Aufrufzahlen.

## Ergänzende Checks und Grenzen

- Die vorhandenen LuaJIT-Tests wurden erneut ausgeführt: **6806 Offline-Assertions bestanden**.
- Originale und `.bak` weiterhin bytegleich; Plugin-Binärdatei unverändert.
- Kein SmartCopilot-Zweiinstanztest, kein gezielter Zeitbeschleunigungstest, kein Langzeitlauf und kein
  kontrollierter Performance-A/B-Vergleich. Kein behaupteter FPS-Gewinn oder Nachweis der neuen Grafik-API.
- Normales Fortsetzen und Flugneustart sind geprüft; ein isolierter SASL-Reload ist nicht Gegenstand der Freigabe.

Zum Abschluss: Flugzeug bleibt geparkt und mit laufenden Triebwerken geöffnet. Test-Stromschalter,
Kamera-FOV und ursprüngliche Yoke-Sichtpräferenz wiederhergestellt; Pause und Replay aus.
X-Plane/SASL haben während des Tests ihre normalen Zustands-, Betriebszeit- und Logdateien aktualisiert.
Diese automatisch erzeugten Änderungen wurden nicht zurückgesetzt, nicht committet und nicht gepusht.
