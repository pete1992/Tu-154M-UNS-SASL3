# USVP: Zuständigkeit und Abnahme

Stand: 26.09.2026. Ziel: aktive Installation auf `I:`; X-Plane 12.
Keine Änderungen an `mech_aneroid.lua`, Kabinendruck, OBJ oder DataRef-Creators.

## Genau ein aktiver Schreiber je Ausgang

- `plugins/xtlua/init/scripts/T154.usvp/T154.usvp.lua` besitzt die USVP-Nadel:
  TAS/GS-Auswahl, ursprüngliche Euler-Dämpfung, km/h → Grad und DISS-Anlaufsperre.
- Der SASL-Host lädt `usvp {}` nicht mehr. `main_panel/usvp.lua` bleibt ausdrücklich
  als inaktive Vergleichsreferenz erhalten; der Regressionstest führt sie isoliert aus.
- `T154.systems` bindet/schreibt weder die Nadel noch DISS-Messwerte weiter.
- `main_panel/diss/diss_logic.lua` besitzt jetzt auch die 180-Sekunden-Anlaufphase
  seiner Messwerte. Berechnungen laufen während der gehaltenen Veröffentlichung weiter.
  Modus 0 bei eingeschaltetem DISS ist das Verfügbarkeitssignal für USVP.
- Nach der Anlaufphase veröffentlicht DISS seinen tatsächlichen Modus 1/2/3,
  nicht den früher für einen Frame erzwungenen Automatikmodus 1.
- DISS verfolgt Stromversorgung/Anlaufzeit auf beiden SmartCopilot-Seiten; nur der
  Master veröffentlicht Messwerte. Die nicht synchronisierte USVP-Nadel wird weiterhin
  auf beiden Seiten berechnet. `T154.zmisc` bleibt reiner Leser der Nadel (>1000 km/h).

USVP verwendet den klassischen Main-Timer mit Nullintervall, keinen Worker und keinen
zusätzlichen `after_physics`-Aufruf. Das erhält die framegebundene Dämpfung; es ist kein
behaupteter FPS-Gewinn. Vor Zugriff müssen alle acht skalaren DataRefs aufgelöst sein.

## Offline

Aus dem Flugzeugordner mit LuaJIT:

```text
luajit tests/xtlua_usvp_test.lua
PASS: 16690 offline assertions

luajit tests/xtlua_instruments_test.lua
PASS: 6806 offline assertions
```

Der neue Test führt den tatsächlich installierten Classic-Main-Bootstrap, die frühere
USVP-/Zeitlogik und den geänderten DISS-Produzenten aus; native APIs und Terrain-Probe
sind nachgebildet. Geprüft wurden verzögerte/verschwindende Bindings, TAS/GS-Auswahl,
10/20/30/60/120 FPS, dt-Begrenzung, Pause/Replay-Callbacks, ungültige Zahlen, unbeschnittene
Werte über 360°, gehaltene Filterzustände, 180-Sekunden-Grenze, Stromausfall/Wiederkehr,
Auto-/Manuell-/Prüfmodus sowie Master/Slave-Wechsel einschließlich Stromzyklus als Slave.
Alle sechs beteiligten Lua-Dateien bestehen die Syntaxprüfung.

## Echter Simulatorlauf

X-Plane wurde für diesen Test gestartet. Flugzeug stand mit laufenden Triebwerken am
Boden in EDDV. Bedienung erfolgte über die vorhandenen Prüfschalter/DataRefs, den realen
USVP-Cockpitknopf und die [lokale X-Plane-API](https://developer.x-plane.com/article/x-plane-web-api/).
Keine künstliche Änderung der globalen Uhr, keine Zeitbeschleunigung und keine direkten
Testschreibzugriffe auf die Nadel oder die von SASL berechneten Messwerte.

| Prüfung | Beobachtung |
| --- | --- |
| SVS-Prüfsignal, TAS gewählt | 900 km/h → stabile 324°; auch während DISS-Anlauf verfügbar |
| DISS aus | `diss_cc=0`, Modus 0, GS 0; Zeiger läuft bei GS-Auswahl auf null |
| DISS ein, GS gewählt | `diss_cc=1`, Modus 0, Nadel 0 während Anlauf |
| Vollständiger 180-s-Anlauf | Start um Simzeit 139 s; letzter gesperrter Messpunkt 318,784 s, erster freigegebener 319,060 s |
| Freigabe im DISS-Prüfmodus | Modus 3, GS 709,9992 km/h, Nadel stabil 255,59972° |
| Grenzbereich-Messreihe | 122 Stichproben; kein von null abweichender Nadelwert bei Modus 0 |
| Cockpit-Umschalter | Realer Mausklick wechselt GS → TAS; Schrift und Zeiger reagieren korrekt |
| Pause bei geändertem TAS-Eingang | TAS fällt auf 0, Nadel bleibt bei 324°; nach Fortsetzen gedämpfter Rücklauf |
| Erneutes Aus-/Einschalten | Frische Anlaufsperre: Strom 1, Modus 0, GS-Nadel 0 |
| Laufendes Replay | Bei Pause hält die Nadel; während rückwärts laufendem Replay steigt TAS-Nadel auf 324° |
| Vollständiger Aircraft-Reload | Neue Instanz startet mit Nadel 0; TAS-Prüfsignal erreicht danach wieder etwa 324° |
| Dämpfung vor/nach Reload | Grob aus REST-Stichproben ermittelte Rate 5,18/s bzw. 5,62/s; kein Hinweis auf verdoppelte Integration |

GS- und TAS-Anzeige wurden zusätzlich im Cockpit visuell geprüft. REST-Abfragen sind
nicht frameatomar; der Übergang ist innerhalb der Abtastauflösung, nicht auf einen
exakten Frame, nachgewiesen. Die Schätzraten sind keine präzise Scheduler-Messung.

Testschalter, Replay/Pause und Kamera wurden auf den Ausgangszustand zurückgestellt.
X-Plane bleibt geöffnet. Simulatorgenerierte Änderungen an SASLLog, state.txt und der
Hobbs-Zeit in tu154_prefs.txt wurden nicht zurückgesetzt oder als Codeänderung behandelt.

Keine USVP-/DISS-Lua-Laufzeitfehler in den geprüften X-Plane-/SASL-Logs. Separater
vorhandener Loaderhinweis: `plugins/xtlua/scripts/tests/tests.lua` fehlt; dort liegt nur
`tests.lua.bak`. Dieses nicht zum USVP-Port gehörende Testmodul blieb unverändert.

## Grenzen und Rückweg

Nicht live geprüft: SmartCopilot mit einem zweiten Rechner, volle Flugphase mit
automatischer DISS-Messung, Zeitbeschleunigung und Langzeitbetrieb. Die betreffenden
Offline-Prüfungen ersetzen diese Abnahme nicht.

Bei einer Rücknahme zuerst `T154.usvp` aus dem aktiven Loaderpfad nehmen, dann den
früheren SASL-Hosteintrag wieder aktivieren. DISS-Anlaufblock und Systeme-Override nur
gemeinsam zurücknehmen; niemals beide Schreiber parallel aktivieren. Vollständig neu laden.
