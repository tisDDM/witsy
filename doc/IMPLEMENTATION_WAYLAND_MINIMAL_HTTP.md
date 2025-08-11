# Witsy – Wayland-Kompatibilität (PR1) und Minimaler HTTP-Trigger (PR2)

Dieser Leitfaden dokumentiert Ziele, Entscheidungen, Implementierung, Beispiele und PR-Skizzen für:
- PR1: Minimal-invasiver Toggle für globale Shortcuts + Wayland-Erkennung
- PR2: Minimaler, optionaler lokaler HTTP-Trigger-Server (GET/POST)

Zielsetzung
- Minimal-invasiv, hohe Akzeptanz upstream.
- Keine Änderungen am Verhalten auf Nicht-Wayland.
- Keine neuen Dependencies, keine package.json-Änderungen.
- Für Dich downstream dauerhaft pflegbar.

---

## PR1: Wayland – Toggle für globale Shortcuts

Problem
- Electron `globalShortcut` funktioniert unter Wayland oft nicht zuverlässig und kann systemweite Copy/Paste-Probleme verursachen.

Design
- Runtime-Erkennung Wayland.
- Globale Shortcuts unter Wayland per Default deaktivieren.
- Ein einfacher Toggle im UI ermöglicht bewusstes Aktivieren.

Implementierung
- Guard (Wayland/Toggle) in `src/main/shortcuts.ts`:
  - Erkennung:
    - Linux + (`XDG_SESSION_TYPE == 'wayland'` oder `WAYLAND_DISPLAY` gesetzt)
  - Effektive Logik:
    - Wenn `config.shortcuts.enableGlobalShortcuts` explizit gesetzt → Wert verwenden.
    - Sonst: Default `!isWayland` (unter Wayland „aus“, sonst „an“).
  - Bei „aus“: `unregisterShortcuts()` und `return` (keine Registrierungen).

- UI in `src/settings/SettingsShortcuts.vue`:
  - Checkbox: „Enable global shortcuts“
  - Bindung: `store.config.shortcuts.enableGlobalShortcuts`
  - OnChange: `store.saveSettings()` + `window.api.shortcuts.register()` (der Guard übernimmt Logik)

- Typen in `src/types/config.ts`:
  - `ShortcutsConfig` → `enableGlobalShortcuts?: boolean`

Dateiänderungen (PR1)
- src/main/shortcuts.ts
- src/settings/SettingsShortcuts.vue
- src/types/config.ts

Verhalten
- Wayland:
  - Default-Effekt: globale Shortcuts aus (solange kein expliziter Wert gespeichert).
  - Checkbox kann aktiviert werden → Registrierung aktiv.
- Nicht-Wayland:
  - Unverändert (Default bleibt effektiv „an“).
- Keine Migrationslogik in `defaults/settings.json` nötig (Laufzeit-Default reicht).

Test-Hinweise
1) Unter Wayland starten → Shortcuts sollten aus sein.
2) Einstellungen → Shortcuts → Checkbox an → Shortcuts sofort aktiv.
3) Checkbox wieder aus → `unregisterAll()` greift.

Branch/Commit (Fork)
- Branch: `feature/global-shortcuts-toggle-wayland`
- Beispiel-Commit: `feat(shortcuts): Wayland-aware toggle for global shortcuts (default off on Wayland) + UI checkbox; no package changes`

---

## PR2: Minimaler lokaler HTTP-Trigger (opt-in)

Ziel
- Externen Clients (z. B. Wayland-Bridge) eine minimalistische API bereitstellen, um Witsy-Aktionen auszulösen.
- Ohne neue Dependencies (reines Node `http`), standardmäßig deaktiviert.

Design
- Server bindet an `127.0.0.1`.
- API:
  - `GET /health` → `{ ok: true }`
  - `GET /trigger?cmd=...&text=...`
  - `POST /trigger` mit JSON `{ "cmd": "...", "text": "..." }`
- Unterstützte `cmd`-Werte:
  - `prompt | chat | scratchpad | command | readaloud | transcribe | realtime | studio | forge`
- Textübergabe:
  - Für `command` und `prompt` kann `text` mitgegeben werden.
  - Text wird via `putCachedText(text)` im Main-Prozess gecached und an die jeweiligen Fenster/Flows übergeben:
    - `prompt`: öffnet Prompt Anywhere ggf. mit `promptId`
    - `command`: öffnet Command Picker mit `textId` + (optional) `sourceApp`

Implementierung
- `src/main/httpServer.ts`
  - Kleiner Node-HTTP-Server (localhost).
  - Akzeptiert GET/POST, parse Query/JSON, ruft Handler `(cmd, { text })`.
- `src/main.ts` – Integration
  - Start/Stop basierend auf Settings.
  - Handler-Mapping:
    - `prompt`:
      - mit `text` → `promptId = putCachedText(text)` und `window.openPromptAnywhere({ promptId })`
      - ohne `text` → `PromptAnywhere.open()`
    - `chat` → `window.openMainWindow({ view: 'chat' })`
    - `scratchpad` → `window.openScratchPad()`
    - `command`:
      - mit `text` → `textId = putCachedText(text)`; `sourceApp = await automator.getForemostApp()`; `window.openCommandPicker({ textId, sourceApp, startTime: Date.now() })`
      - ohne `text` → `Commander.initCommand(app)`
    - `readaloud` → `ReadAloud.read(app)`
    - `transcribe` → `Transcriber.initTranscription()`
    - `realtime` → `window.openRealtimeChatWindow()`
    - `studio` → `window.openDesignStudioWindow()`
    - `forge` → `window.openAgentForgeWindow()`

- UI-Toggle (opt-in) in `src/settings/SettingsAdvanced.vue`:
  - Checkbox: „Enable local HTTP trigger“
  - Bindung an `store.config.httpServerEnabled`

- Typen in `src/types/config.ts`:
  - `httpServerEnabled?: boolean`
  - `httpServerPort?: number` (Default 18081, optional via settings.json setzbar)

Dateiänderungen (PR2)
- src/main/httpServer.ts (NEU)
- src/main.ts (Import, Handler, Start/Stop, Reconfigure)
- src/settings/SettingsAdvanced.vue (Checkbox)
- src/types/config.ts (optionale Felder)

Sicherheit/Scope
- Nur `127.0.0.1` (localhost).
- Keine Auth by design (bewusst minimal).
- Kein express / keine externen Pakete.

Aktivierung
- Einstellungen → Advanced → „Enable local HTTP trigger“ aktivieren.
- Alternativ direkt in `settings.json`:
  ```json
  {
    "httpServerEnabled": true,
    "httpServerPort": 18081
  }
  ```

Beispiele (curl)
- Health:
  ```bash
  curl "http://127.0.0.1:18081/health"
  ```
- prompt:
  ```bash
  # GET (robust ohne jq; URL-Encodierung per --data-urlencode)
  curl --get "http://127.0.0.1:18081/trigger" --data-urlencode "cmd=prompt" --data-urlencode "text=Hallo Welt"

  # POST (empfohlen für längere/mehrzeilige Texte)
  curl -X POST "http://127.0.0.1:18081/trigger" -H "Content-Type: application/json" -d '{"cmd":"prompt","text":"Hallo Welt"}'
  ```
- command:
  ```bash
  # GET (robust ohne jq; URL-Encodierung per --data-urlencode)
  curl --get "http://127.0.0.1:18081/trigger" --data-urlencode "cmd=command" --data-urlencode "text=Erkläre diesen Code:"

  # POST
  curl -X POST "http://127.0.0.1:18081/trigger" -H "Content-Type: application/json" -d '{"cmd":"command","text":"Erkläre diesen Code:"}'
  ```
- chat/scratchpad/readaloud/transcribe/realtime/studio/forge (GET-Beispiele):
  ```bash
  curl "http://127.0.0.1:18081/trigger?cmd=chat"
  curl "http://127.0.0.1:18081/trigger?cmd=scratchpad"
  curl "http://127.0.0.1:18081/trigger?cmd=readaloud"
  curl "http://127.0.0.1:18081/trigger?cmd=transcribe"
  curl "http://127.0.0.1:18081/trigger?cmd=realtime"
  curl "http://127.0.0.1:18081/trigger?cmd=studio"
  curl "http://127.0.0.1:18081/trigger?cmd=forge"
  ```

Hinweise
- Setze die komplette URL in Anführungszeichen, damit die Shell das `&` in Query-Strings nicht als Steuerzeichen interpretiert.
- Falls `jq` nicht installiert ist, nutze die gezeigten `--data-urlencode` Beispiele für GET oder POST/JSON für beliebig lange Texte.

Debug-Logging
- Der Server schreibt pro Request eine Zeile ins Log (siehe App-Logdatei/DevTools-Konsole), z. B.:
  - `[http-trigger] GET /trigger cmd=command textLen=18`
  - `[http-trigger] POST /trigger cmd=prompt textLen=10`
- Pfad der Logdatei wird beim Start geloggt, z. B.: `Log file: /.../logs/main.log`

Hinweise zur Bridge-Integration
- Die Bridge kann Texte direkt per HTTP an Witsy senden:
  - `GET /trigger?cmd=command&text=...` oder
  - `POST /trigger` mit `{ "cmd": "command", "text": "..." }`
- Für `prompt` analog.
- Intern nutzt Witsy `putCachedText(text)` und übergibt IDs (`textId`, `promptId`) an Fenster/Flows (keine großen Text-IPC).

### Bridge implementation notes (English, minimal)
- Startup/health:
  - Ping `GET /health` on startup and periodically; cache the base URL (e.g., http://127.0.0.1:18081).
- Triggering:
  - Short text: `curl --get ... --data-urlencode "cmd=..." --data-urlencode "text=..."`.
  - Long/multi-line text: `POST /trigger` with JSON `{ "cmd": "...", "text": "..." }`.
  - `cmd` values: `prompt | command | chat | scratchpad | readaloud | transcribe | realtime | studio | forge`.
  - For `prompt`/`command`, include `text` to pre-fill Witsy UI; user still selects the specific AI command in the picker (no action parameter in PR2).
- Reliability:
  - Add simple retry/backoff on non-200 responses or connection errors (e.g., wait 300–500ms, retry a few times).
  - Throttle rapid consecutive triggers to avoid overlapping UI (100–200ms gaps).
- Error handling:
  - HTTP 200 → success; HTTP 400 → invalid/missing cmd or bad payload; surface a small toast/log in the bridge.
- Logging:
  - Witsy logs each request (see `[http-trigger] ...` lines and main log path printed on app start).
- Security:
  - Server binds to `127.0.0.1` and has no auth (by design for PR2). If stricter control is needed, implement in the bridge (e.g., local allowlist, UI confirmations).

---

## Branch-/PR-Übersicht (Fork → Upstream)

PR1 – Wayland Toggle
- Fork-Branch: `feature/global-shortcuts-toggle-wayland`
- Kurzbeschreibung:
  - Wayland-Erkennung (Linux: `XDG_SESSION_TYPE == 'wayland'` oder `WAYLAND_DISPLAY`)
  - Optionales `shortcuts.enableGlobalShortcuts`
  - Default: Unter Wayland aus; sonst unverändert
  - UI-Checkbox „Enable global shortcuts“
  - Keine `package.json`-Änderungen

PR2 – Minimaler HTTP-Trigger
- Fork-Branch: `feature/minimal-http-server`
- Kurzbeschreibung:
  - Lokaler HTTP-Trigger (127.0.0.1), opt-in via `httpServerEnabled`
  - API: `GET/POST /trigger` (cmd, text, action), `GET /health`
  - `prompt`/`command` akzeptieren `text`
  - Keine `package.json`-Änderungen

Empfohlene PR-Texte
- Motivation (Wayland, Copy/Paste-Probleme, Wunsch nach Automation)
- Minimalinvasiver Ansatz, keine externen Abhängigkeiten, opt-in, Backwards-kompatibel
- Kurze Testhinweise (wie oben)

---

## Risiken und Edge Cases

- PR1:
  - Wenn Nutzer explizit `enableGlobalShortcuts: true` setzt, sind Shortcuts auch unter Wayland aktiv (bewusst).
- PR2:
  - Port-Kollision → Server startet nicht; es wird geloggt, Rest der App läuft normal.
  - Keine Auth (bewusst minimal); Bind an `127.0.0.1` reduziert Risiko.

---

## Status

- PR1 und PR2 im Fork umgesetzt (getrennte Branches), lokal testbar und bereit für PRs gegen das Original-Repo.
- Keine Abhängigkeiten oder package.json-Änderungen.
