# SASL → xTlua: überarbeiteter Portierungsplan

Stand: 26.09.2026. Ziel ist die aktive Tu-154M-Installation auf `I:`, ausschließlich X-Plane 12.
Zuerst Verhalten erhalten, dann Zuständigkeiten vereinfachen, erst danach weiter optimieren.
Dieser Plan ersetzt keine Simulatorabnahme und verspricht keinen bestimmten FPS-Gewinn.

## 1. Quellenstand und Aussagegrenzen

Untersucht wurde [pete1992/xtlua-Tu-154M, Commit 351ba4aee6af981607b2209b605ce77de2161da4](https://github.com/pete1992/xtlua-Tu-154M/tree/351ba4aee6af981607b2209b605ce77de2161da4).
Die Auswertung umfasst Loader/Bootstraps, Scheduling, DataRef-/Command-Brücken, Rendertransport,
SDK-Registrierung, repräsentative native Implementierungen, Fehlerpfade und Ressourcen-Lifecycle.
Nicht pauschal auditiert wurden sämtliche vendorten LuaJIT-, ImGui- und SDK-Dateien.

Die installierte `win.xpl` ist nicht byteidentisch mit der im untersuchten Repository enthaltenen Binärdatei.
Der Repository-Eigentümer bestätigt die Funktionsgleichheit trotz unterschiedlicher Compilerläufe;
die Hashabweichung ist deshalb kein Portierungsblocker. Die Hashes dienen nur der Build-Zuordnung.
Der aktuelle Auftrag ersetzt oder kompiliert die Plugin-Binärdatei nicht. Die Instrumentenports
verwenden den klassischen API-Pfad; neue XLua-2-Grafikfunktionen werden dafür nicht vorausgesetzt.

SHA-256 zur späteren Zuordnung:

- Repository `win.xpl`: `A8AB4EB80A83EEE537F7362FE70E15FA607EB747CDB23347BBD90AC6A6C2ADE4`.
- Installierte `win.xpl`: `2F8349C91BEEE9C99A8331D99B485B80F69D75D362D584128742C92A606E79BF`.
- `init/init.lua` stimmt bytegenau überein. Der installierte Worker-Bootstrap ergänzt JIT-Optionen;
  `init_v2.lua` unterscheidet sich nur in Zeilenenden. Funktionstests erfolgen mit der installierten Binärdatei.

Quellcodebefund, Mock-/Syntaxprüfung und echter Simulatorlauf werden getrennt dokumentiert.
Die in den Repository-READMEs genannten `tests/check_*.ps1`-/Lua-Prüfungen sind im untersuchten
Checkout nicht enthalten; veröffentlichte Prüfzähler sind daher kein hier wiederholter Nachweis.
`PHASE2_README.md` ist teilweise überholt: Die aktuelle ImGui-Implementierung erlaubt mehrere Fenster.

## 2. Drei Laufzeiten, nicht ein gemeinsamer Ausführungsmodus

| Laufzeit | Ort und Ausführung | Geeigneter Einsatz |
| --- | --- | --- |
| `xtlua_worker` | `plugins/xtlua/scripts/<Modul>/<Modul>.lua`, ohne XLua-2-Marker; eigener Worker | Rechenlogik, Zustandsautomaten, skalare Instrumentenwerte, vorbereitete Displaydaten |
| `xtlua_main` | `plugins/xtlua/init/scripts/<Modul>/<Modul>.lua`; X-Plane-Hauptthread | Klassische direkte Bindings und kleine synchrone Aufgaben, wenn Timingparität wichtiger als Auslagerung ist |
| `xlua2_main` | Unter `scripts`, exakte erste Zeile `--[[ XLua 2.0 ]]`; Hauptthread | Generierte SDK-APIs, PanelGraphics, native Avionik und ImGui |

Die Trennung ist im [Loader und Registrierungsweg](https://github.com/pete1992/xtlua-Tu-154M/blob/351ba4aee6af981607b2209b605ce77de2161da4/XTLua/src/module.cpp#L461)
implementiert, nicht nur eine Dokumentationskonvention. Klassische Module behalten den Dateinamen als
Kommentar in Zeile 1; ein zukünftiges XLua-2-Modul benötigt stattdessen dort zwingend den Marker.

Der Worker führt `before_physics`/`after_physics` nicht einmal je Simulatorframe aus.
Das klassische `SIM_PERIOD` wird im geprüften [Helfer auf 0,02 gesetzt](https://github.com/pete1992/xtlua-Tu-154M/blob/351ba4aee6af981607b2209b605ce77de2161da4/XTLua/src/lua_helpers.cpp#L79).
Es ist keine verlässlich gemessene Zeitspanne des aktuellen Frames oder Workeraufrufs.
Ein SASL-Integrationsschritt darf deshalb nicht unverändert in jeden Workerzyklus kopiert werden.
Für jede Portierung sind Zeitbasis, Pause, Replay, Zeitbeschleunigung und Wiederanlauf ausdrücklich festzulegen.

Der Worker hat eine Mindestzyklusdauer von 20 ms; `before_physics` und `after_physics` laufen dort
im selben unabhängigen Durchlauf. Pause unterdrückt die regulären Worker-Callbacks, Replay dagegen nicht.
Ein Fehler in einem regulären Worker-Callback kann im geprüften Host die gesamte Worker-Schleife stoppen;
Module sind also keine vollständig isolierten Fehlerdomänen. Der Hauptthread wartet nicht pro Frame auf den
Worker, wohl aber bei Stop/Reload auf dessen Ruhepunkt. Lebenszyklus-Initialisierung muss idempotent sein:
`aircraft_load` kann über mehrere Ladeereignisse eintreffen.
Siehe [Worker-Schleife](https://github.com/pete1992/xtlua-Tu-154M/blob/351ba4aee6af981607b2209b605ce77de2161da4/XTLua/src/xlua.cpp#L552).

## 3. Bindings, Datenbesitz und Startbereitschaft

- DataRef-Bindings bleiben globale Namen des jeweiligen klassischen Modul-Namensraums; sie werden nicht zu lokalen Zahlenkopien.
- Deklarative `find_datarefs`-/gegebenenfalls `deferred_datarefs`-Tabellen bleiben Standard.
- Der tatsächliche klassische Loader benutzt einen eigenen Funktions-Namensraum über `setfenv`.
  Die Bindeschleife schreibt deshalb über `getfenv(1)` in genau diesen Namensraum, nicht blind in das geerbte `_G`.
- Die Module sind isoliert; gemeinsame Zustände anderer Systeme bleiben explizite DataRefs/Commands.
  Bestehende globale Namen werden nicht allein aufgrund einer lokalen Textsuche entfernt.
- Ein gefundener Worker-Proxy bedeutet noch nicht, dass sein externer SASL-DataRef aufgelöst wurde.
  Vor Initialisierung und Schreiben wird die Bereitschaft des gespeicherten Handles geprüft.
  `XTLuaGetDataRefType(handle) == "number"` ist für die skalaren Pilotmodule das relevante Kriterium.
- Ein Write auf einen noch unaufgelösten skalaren Worker-DataRef ist keine garantiert nachgelieferte Nachricht.
  Insbesondere die einmalige Zufallsinitialisierung der Uhr muss auf echte Bereitschaft warten.
- `flight_start` allein ist kein Beweis, dass sämtliche SASL-Creators bereits verfügbar sind.
- Ein Ausgang erhält genau einen aktiven Logikschreiber. Bestehende SASL-Creators bleiben zunächst Eigentümer
  der DataRef-Definitionen; die neuen Instrumentenmodule erzeugen keine konkurrierenden Definitionen.
- Asynchrone Writes sind nicht sofort im Simulator oder in SASL sichtbar. Rücklesen ersetzt keine Bestätigung
  eines fremden Providers. Für zusammenhängende Zustände sind Snapshot-/Übergabeverträge erforderlich.
- Ein Worker-Read liest den Cache und fordert dessen nächste Aktualisierung an, keinen synchronen SDK-Read.
  Eingaben eines Rechenschritts daher gemeinsam und nicht nur bedingt abfragen. Mehrere skalare Reads sind
  trotzdem keine atomare Mehrfeld-Transaktion. Versionierte Writes schützen vor veralteter Rückbestätigung,
  lösen aber keinen Konflikt zwischen zwei verschiedenen Produzenten.
- Die klassischen Array-Bulk-APIs sind vom generierten SDK-Pfad zu unterscheiden: X-Plane-Offsets sind
  nullbasiert, Lua-Nutzwerttabellen einsbasiert. Dynamische Länge und Teilbereiche ausdrücklich testen.
- Commands transportieren Phasen und dürfen nicht als flüchtiger Renderzustand modelliert werden.
  Synchrone Command-Filter gehören in den Main-Pfad. Timer besitzen eigene Runtime-/Modulzuordnung;
  ein Callback darf nicht gleichzeitig über Timer und `after_physics` doppelt aufgerufen werden.
- SmartCopilot-Master/Slave-Regeln und pro Instanz getrennte Zustände bleiben erhalten.

Referenzen: [klassischer Namensraum](https://github.com/pete1992/xtlua-Tu-154M/blob/351ba4aee6af981607b2209b605ce77de2161da4/deploy/xtlua/init.lua#L500),
[Worker-DataRef-Brücke](https://github.com/pete1992/xtlua-Tu-154M/blob/351ba4aee6af981607b2209b605ce77de2161da4/XTLua/src/xpmtdatarefs.cpp),
[Runtime-Vertrag](https://github.com/pete1992/xtlua-Tu-154M/blob/351ba4aee6af981607b2209b605ce77de2161da4/THREADING_README.md).

## 4. Neue Fähigkeiten und verbleibende Grenzen

Die frühere Pauschalaussage „xTlua kann keine Grafik“ gilt für diesen Quellstand nicht mehr.
Die [native Registrierung](https://github.com/pete1992/xtlua-Tu-154M/blob/351ba4aee6af981607b2209b605ce77de2161da4/SDK/XLua_glue/XLua_Register_glue.cpp)
enthält 333 Einträge einschließlich Strukturkonstruktoren und Host-Helfern. Das ist API-Abdeckung, keine vollständige SASL-Parität.

| Bereich | Tatsächlich vorhanden | Konsequenz |
| --- | --- | --- |
| PanelGraphics | Vektoren, Transformationen, Clipping/Stencil, Retained Drawing | Späterer Renderer-Port möglich; Zeichnen bleibt Hauptthreadarbeit |
| Bilder/Fonts | Texture-Atlas-Dateien, Sprites/Meshes, skalierte/gedrehte Bilder, native Fonts/TTF | SASL-Crops, Koordinaten, Alpha und Schriftmetriken einzeln vergleichen |
| ImGui | Mehrere Fenster mit eigenem Kontext; Hauptthread-Draw-Grenze; zusätzliche Widgets | Geeignet für spätere Werkzeugfenster, nicht automatisch für bestehende Cockpit-Komponenten |
| Native Avionik | Displays, Fenster, Touch, Map/SVT, Terrain-Probes, Wetter-/FMS-/Nav-APIs | Eigener Lifecycle und SDK-Kompatibilitätsnachweis erforderlich |
| Samples/Audio | Keine implementierte XPLMSound-Lua-Schnittstelle | SASL-Samplewiedergabe, Stoppen und Lautstärke vorerst behalten |

`imgui.Image`, `ImageButton` und DrawList-Image-Adapter fehlen wegen `ImTextureRef`.
Allgemeine `XPLMCreateTexture`-/DestroyTexture-/DrawCalls-Lua-Wrapper fehlen ebenfalls; die internen
ImGui-Texturen sind kein frei nutzbarer SASL-Texturersatz. Native Texture-Atlanten sind davon zu unterscheiden.
Die generierte [Sound-Datei](https://github.com/pete1992/xtlua-Tu-154M/blob/351ba4aee6af981607b2209b605ce77de2161da4/SDK/XLua_glue/XPLMSound_glue.cpp)
ist ein Gerüst ohne Wiedergabefunktionen. `XPLMSpeakString` ersetzt keine WAV-Samples.

Der Rendertransport [arbeitet mit drei Slots](https://github.com/pete1992/xtlua-Tu-154M/blob/351ba4aee6af981607b2209b605ce77de2161da4/XTLua/src/xtlua_render_bridge.cpp#L21):
32 Kanäle, 128 Felder je Frame, 4096 Zahlen je Feld-Array und insgesamt 64 KiB Stringinhalt je Frame.
Erlaubt sind endliche Zahlen, Boolesche Werte, Strings und dichte numerische Arrays, keine SDK-Handles,
Funktionen oder beliebig verschachtelten Tabellen. Konsistenz gilt je Kanal; der neueste komplette Frame gewinnt.
`XLuaGetRenderBuffer` erzeugt eine eigene Lua-Kopie. Ein allgemeiner Main→Worker-Eingabeereigniskanal fehlt.
Einzelne Tastendrücke, Encoderimpulse und Audioereignisse dürfen daher nicht im neuesten Renderzustand verloren gehen.

## 5. Native Risiken: Freigabeschranken für spätere Ports

Die folgenden Befunde stammen aus Quellcodeprüfung, nicht aus absichtlich ausgelösten Simulatorabstürzen.

1. **Arraylänge gegen Count:** [PanelGraphics `XLuaLines`](https://github.com/pete1992/xtlua-Tu-154M/blob/351ba4aee6af981607b2209b605ce77de2161da4/SDK/XLua_glue/XPLMPanelGraphics_glue.cpp#L237)
   allokiert anhand `min(Tabellenlänge, count) + 1`, reicht aber den ursprünglichen `count` weiter.
   Ein deutlich größerer Count kann einen nativen Lesezugriff außerhalb des Puffers verursachen.
   Dasselbe Muster findet sich bei [SetDatavi/SetDatavf](https://github.com/pete1992/xtlua-Tu-154M/blob/351ba4aee6af981607b2209b605ce77de2161da4/SDK/XLua_glue/XPLMDataAccess_glue.cpp#L436).
   Lua-Argumentfehler nach `new[]` können zudem den abschließenden `delete[]` überspringen.
2. **Nav-Region als String:** [GetNavAidInfo](https://github.com/pete1992/xtlua-Tu-154M/blob/351ba4aee6af981607b2209b605ce77de2161da4/SDK/XLua_glue/XPLMNavigation_glue.cpp#L148)
   verwendet `outReg[1]` und `lua_pushstring(outReg)`; laut SDK ist dies ein einzelnes 0/1-Byte, kein C-String.
   Bei gesetztem Flag fehlt ein garantierter Terminator. Vor Nutzung dieses neuen Bindings korrigieren und testen.
3. **Ressourcen:** Host-ImGui, Timer und Commands besitzen gezieltes Cleanup. Allgemeine Atlanten, Fonts,
   Probes und native Fenster müssen Skripte explizit freigeben. Die Callback-Quarantäne schützt einen bereits
   geschlossenen Lua-State, ersetzt aber keine vollständige native Ressourcenfreigabe.
4. **SDK/Build:** PanelGraphics ist durch `XPLM440` bedingt. Vor Nutzung neuer SDK-APIs installierte Exporte,
   passenden Build und tatsächliche Plugin-Ladung prüfen; kein automatisches Binärupdate in diesem Auftrag.

Diese Befunde rechtfertigen keinen Umbau der Upstream-Runtime innerhalb des Instrumentenports.
Für größere native Ports gilt: relevante Bindings absichern, reproduzierbare Tests ergänzen, Build prüfen,
danach Fehlerpfade, Reload, Disable/Enable, Flugzeugwechsel und Shutdown im Simulator abnehmen.

## 6. Reihenfolge der Flugzeugmodule

| Stufe | Kandidaten | Voraussetzung und Abgrenzung |
| --- | --- | --- |
| 1 – aktueller Pilot | `main_panel/clock24.lua`, `main_panel/termo.lua` | Bestehende Ausgabewege und Creator erhalten; Timing und Startinitialisierung vergleichen |
| 2 – kleine Instrumente | `eup53.lua`, `mach_meters.lua`, `mech_aneroid.lua`, danach `tks/km5.lua` | Numerischen Teil isolieren; Framefilter, Stromausfall, Achsen/Einheiten und Synchronisation prüfen |
| 3 – gekoppelte Instrumente | `svs.lua`, `rv5.lua`, `door_panel.lua`, `ins_test.lua`, `misc_fails.lua`, `tks/tks_fails.lua` | Abhängigkeiten und Ausgabeautorität vor Reihenfolge festlegen; Ton/UI gegebenenfalls SASL belassen; USVP bereits separat zusammengeführt |
| 4 – größere Systeme | Ausgewählte elektrische/Animations-/Umweltberechnungen | Mehrinstanzen, Verbraucherreihenfolge und Rückkopplung vollständig erfassen |
| 5 – Renderer-Pilot | Ein kleines nichtkritisches Instrument oder Diagnosefenster | Worker-Snapshot → `xlua2_main`; erst nach den nativen Freigabeschranken |
| 6 – zuletzt | ABSU, AT, ILS/KATET, Engine/Start, vollständiges TAWS/EGPWS | Eigene Regressionstests und Flugphasenabnahme; kein bloßer Übersetzungsauftrag |

**USVP-Zuständigkeit geklärt (26.09.2026):** `T154.usvp` ist jetzt der einzige aktive Schreiber von
`tu154/custom/gauges/speed/speed_mid_needle`; der frühere SASL-Hosteintrag ist deaktiviert.
Quellenauswahl, bisherige Euler-Dämpfung und Anlaufsperre liegen gemeinsam im klassischen Main-Modul.
Die DISS-Anlaufphase wurde aus `T154.systems` zum Messwertproduzenten `diss_logic.lua` verlegt:
Dieser veröffentlicht allein seine Werte und den tatsächlichen Modus. USVP erkennt die Anlaufphase
an `diss_cc > 0` zusammen mit `diss_mode == 0`. Keine zweite Uhr und kein zusätzlicher DataRef nötig.
Der DISS-Geländeprobe-/Messalgorithmus bleibt SASL; die Kabinendruck-Zuständigkeit in
`mech_aneroid.lua`/`T154.zmisc` wurde in diesem Schritt nicht verändert.
USVP-Abnahme: 16.690 Offline-Assertions sowie echter TAS/GS-, Anlauf-, Strom-, Pause-,
Replay- und Reload-Test; siehe [USVP-Testprotokoll](USVP_CONSOLIDATION_TEST_2026-09-26.md).
**Mehrinstanzen:** `rv5.lua` wird links/rechts mit abweichenden Bindings instanziiert; `battery_logic.lua`
hat getrennte Batterieparameter und internen Zustand. Ein gemeinsames Lua-Local darf diese Instanzen nicht zusammenlegen.
`nvu_logic.lua` ist kein Anlass, entfernte NVU-Navigation wieder einzuführen; GPS/FMS/VOR-Auswahl und bestehende Verbraucher erhalten.

## 7. Konkrete Entscheidung für clock24 und termo

Der reale Dateiname lautet **`termo.lua`**, nicht `thermo.lua`.
Die Originaldateien sind unverändert; `clock24.lua.bak` und `termo.lua.bak` sind bytegleiche, per SHA-256 geprüfte Sicherungen.
Nur ihre beiden aktiven Einträge im SASL-Host `main_panel.lua` wurden deaktiviert.
Neue isolierte xTlua-Module übernehmen die Logik, ohne SASL-Creators, OBJ-Anbindungen oder DataRef-Pfade umzubenennen.

- **clock24 → klassischer Worker:** Uhrzeiger aus vorhandener Simulationszeit ableiten; Zufallswert genau einmal
  je Modulladung und erst bei bereiten Ziel-DataRefs setzen. Kein erneutes Würfeln pro Frame oder bei `flight_start`.
  Der getrennte Lua-State erhält einmalig denselben `os.time()`-Seed-Ansatz wie bisher SASLs `main.lua`.
- **termo → klassischer Main-Pfad:** Ein Timer mit `run_at_interval(..., 0)` soll genau einen Schritt je Main-Frame
  ausführen. Den nativen Frame-Zeitschritt direkt lesen, auf 0…0,1 s begrenzen und bei Pause wie SASL auf null setzen.
  Die diskrete Euler-Glättung und der Startzustand −55 °C bleiben erhalten; kein Wechsel zur Exponentialglättung.
- Diese Timerwahl erhält bewusst den framegebundenen Ablauf einschließlich des zu prüfenden Replay-Verhaltens.
  Ein Worker mit eigener Frequenz würde die bestehende diskrete Glättung ohne zusätzliche Semantikänderung nicht exakt erhalten.
- **termo wird damit nicht in einen Hintergrundthread ausgelagert.** Das ist eine Zuständigkeitsmigration,
  kein behaupteter Performancegewinn. Eine spätere Workerumstellung braucht einen separat freigegebenen Zeitvertrag.

Der Nullintervall-Timer ist im [C++ ausdrücklich als einmal je Frame vorgesehen](https://github.com/pete1992/xtlua-Tu-154M/blob/351ba4aee6af981607b2209b605ce77de2161da4/XTLua/src/xptimers.cpp#L369).
Der Main-Timer läuft auch bei Pause und Replay; der explizite Pausefilter verhindert Temperaturintegration.
Die relative Reihenfolge gegenüber SASL-Stromberechnung bleibt pluginabhängig: gleiche Rekurrenz und
Framefrequenz bedeuten nicht exakt denselben Abtastzeitpunkt bei einem Schaltvorgang.
Die Worker-Uhr schreibt während Pause nicht weiter und übernimmt eine dann geänderte UTC beim Fortsetzen.
Ungültige UTC/NaN-Temperaturwerte werden nicht in die Anzeige übernommen.

## 8. Abnahme und Rückweg

Ausgeführt am 26.09.2026:

- LuaJIT-Syntaxprüfung der zwei neuen Module und des geänderten SASL-Hosts: bestanden.
- `tests/xtlua_instruments_test.lua`: **6806 Offline-Assertions bestanden**, mit den tatsächlich installierten
  Worker-/Main-Lua-Bootstraps, nachgebildeten nativen APIs und Ausführung der originalen `.bak`-Komponenten
  sowie `time_logic.lua` als Vergleichsbasis.
- Geprüft: Tagwechsel/Uhrzeit, verzögerte DataRef-Auflösung, RNG-Seed und einmalige Zufallsinitialisierung,
  Temperaturen/Stromwechsel, 20/30/60/120 FPS, Zeitschrittbegrenzung, ungültige Werte, Pause/Replay-Callback,
  neuer Flug, externe rote Zeigerstellung und deaktivierte alte SASL-Schreiber.
- Backup-Bytegleichheit, bestehende DataRef-Creators/-Typen und Diff-Whitespace geprüft.

Aufruf aus dem Flugzeugordner: `luajit tests/xtlua_instruments_test.lua`.
Mocktests prüfen Lua-Verhalten, nicht Threadrennen, Plugin-Binärkompatibilität oder echte Cockpitanzeigen.
Der Timer-Scheduler wurde im C++ geprüft, im Test jedoch nachgebildet, nicht als Plugin ausgeführt.
**Simulatorprüfung am 26.09.2026 nachgeholt:** Beide Ports wurden in der aktiven Installation auf `I:`
mit der vorhandenen Plugin-Binärdatei live geprüft. Vollständiger Aircraft-Reload, neue Flüge mit
Cold-and-dark/Engines-running, UTC-Sprünge einschließlich Mitternacht, Stromausfall/Wiederkehr,
Pause und laufendes Replay bestanden. Uhr und beide Temperaturanzeigen zusätzlich visuell kontrolliert.
Nach Reload blieb die gemessene Temperaturdämpfung praktisch unverändert; kein Hinweis auf einen doppelten Timer.
Keine zugehörigen Laufzeitfehler in X-Plane-/SASL-Logs. Messwerte, Ablauf und Aussagegrenzen stehen im
[Live-Testprotokoll](XTLUA_INSTRUMENTS_LIVE_TEST_2026-09-26.md).

Noch offen: kontrollierter SASL-/xTlua-Performancevergleich, SmartCopilot mit zweiter Instanz,
gezielter Zeitbeschleunigungs- und Langzeittest. Aus den Funktionstests wird kein FPS-Gewinn abgeleitet.
Die native Grafikstrecke wird in diesem Pilot nicht aktiviert und gilt dadurch nicht als abgenommen.

Rückweg bei Regression: Zuerst **beide neuen xTlua-Module aus ihren aktiven Loaderpfaden entfernen/deaktivieren**,
dann die beiden SASL-Hosteinträge wieder aktivieren und bei Bedarf die Originale aus den `.bak`-Dateien zurücknehmen.
Ein bloßes Zurückkopieren der SASL-Dateien würde den neuen Schreiber nicht stoppen. Abschließend vollständig neu laden
und prüfen, dass weder ein doppelter Timer noch zwei Ausgabeproduzenten aktiv sind.
