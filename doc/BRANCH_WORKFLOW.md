# Branch-Workflow: main, PR1, PR2, maintained-main

Letzte Aktualisierung: 2025-08-22

Ziele
- Lokal und im Fork reproduzierbar arbeiten.
- Upstream (Original-Repo) regelmäßig einpflegen.
- Zwei saubere, upstream-freundliche PR-Branches pflegen (ohne Scope-Leaks).
- Einen Integrations-Branch maintained-main für die eigene Nutzung aktuell halten.

Begriffe und Rollen
- upstream/main
  - Kanonischer Upstream-Stand (Original-Repo).
- main (lokal)
  - Soll immer upstream/main folgen (keine eigenen Commits).
  - Dient als neutrale Basis; wird regelmäßig auf upstream/main zurückgesetzt.
- PR1-clean: feature/global-shortcuts-toggle-wayland-clean
  - Scope: Wayland-Toggle für globale Shortcuts.
  - Betroffene Dateien:
    - src/main/shortcuts.ts
    - src/settings/SettingsShortcuts.vue
    - src/types/config.ts
  - Keine weiteren Dateiänderungen, keine package.json-Änderungen.
- PR2-clean: feature/minimal-http-server-clean
  - Scope: Minimaler lokaler HTTP-Trigger (opt-in).
  - Betroffene Dateien:
    - src/main/httpServer.ts
    - src/main.ts
    - src/settings/SettingsAdvanced.vue
    - src/types/config.ts
  - Wichtig: Keine Doku-Datei im PR (doc/IMPLEMENTATION_WAYLAND_MINIMAL_HTTP.md bleibt außerhalb des PRs).
- maintained-main
  - Integrations-Branch (lokal + Fork), enthält upstream/main + PR1-clean + PR2-clean.
  - Wird über Skript tools/sync_main_with_prs.sh regelmäßig neu aufgebaut.
  - Kann im Fork gepusht werden (Backup, Demo, Diskussion).

Clone-/Links (für Diskussionen)
- Branch-Seite maintained-main:
  - https://github.com/tisDDM/witsy/tree/maintained-main
- Direkt klonen (HTTPS):
  - git clone --branch maintained-main --single-branch https://github.com/tisDDM/witsy.git
- Shallow Clone (schnell):
  - git clone --branch maintained-main --single-branch --depth 1 https://github.com/tisDDM/witsy.git
- ZIP-Download:
  - https://github.com/tisDDM/witsy/archive/refs/heads/maintained-main.zip

Skript: tools/sync_main_with_prs.sh
- Zweck: Ziel-Branch (z. B. maintained-main) auf upstream/main neu aufsetzen und anschließend PR1-clean + PR2-clean mergen.
- Wichtige Umgebungsvariablen:
  - UPSTREAM_REMOTE (Standard: upstream)
  - FORK_REMOTE (Standard: origin)
  - TARGET_BRANCH (z. B. maintained-main, Standard: main)
  - PR1_BRANCH (z. B. feature/global-shortcuts-toggle-wayland-clean)
  - PR2_BRANCH (z. B. feature/minimal-http-server-clean)
  - ALLOW_UNTRACKED=true erlaubt unversionierte Dateien (keine Modifikationen!)
  - DRY_RUN=true zeigt den Plan ohne Änderungen
  - PREFER_PR2=true bevorzugt PR2 bei Merge-Konflikten (-X theirs)
  - RESOLVE_OURS="pfad1,pfad2" setzt bei Konflikt definierte Pfade auf Upstream/Zielbranch
    - Empfehlung: build/build_number.txt
  - RESOLVE_THEIRS="pfad1,..." setzt definierte Pfade auf eingehenden PR
  - PUSH=true pusht den Ziel-Branch nach dem Merge
- No-Op-Check:
  - Das Skript überspringt PR2, wenn er gegenüber dem aktuellen HEAD keine zusätzlichen Änderungen einbringt.

Empfohlener regelmäßiger Update-Flow
1) Vorbereiten
   - Unversionierte Dateien sind ok (ALLOW_UNTRACKED=true). Modifikationen/Deletions vorher committen oder staschen.

2) main auf Upstream setzen (lokal sauber halten)
   - git fetch --all --prune
   - git switch main
   - Optional: Backup
     - git branch -f backup/main-$(date +%Y%m%d-%H%M%S) main
   - Hart auf Upstream setzen:
     - git reset --hard upstream/main

3) PR1-clean neu aufsetzen (nur die 3 Toggle-Dateien)
   - git switch -c feature/global-shortcuts-toggle-wayland-clean upstream/main || (git switch feature/global-shortcuts-toggle-wayland-clean && git reset --hard upstream/main)
   - git checkout origin/feature/global-shortcuts-toggle-wayland -- \
     src/main/shortcuts.ts src/settings/SettingsShortcuts.vue src/types/config.ts
   - git add -A
   - git commit -m "feat(shortcuts): Wayland-aware toggle (default off on Wayland) + UI checkbox [clean]"
   - Optional push:
     - git push -u origin feature/global-shortcuts-toggle-wayland-clean

4) PR2-clean neu aufsetzen (nur HTTP-Trigger-Dateien – ohne Doku)
   - git switch -c feature/minimal-http-server-clean upstream/main || (git switch feature/minimal-http-server-clean && git reset --hard upstream/main)
   - git checkout origin/feature/minimal-http-server -- \
     src/main/httpServer.ts src/main.ts src/settings/SettingsAdvanced.vue src/types/config.ts
   - Sicherstellen: doc/IMPLEMENTATION_WAYLAND_MINIMAL_HTTP.md NICHT im Commit.
   - git add src/main/httpServer.ts src/main.ts src/settings/SettingsAdvanced.vue src/types/config.ts
   - git commit -m "feat(http): minimal local HTTP trigger (opt-in) [clean]"
   - Optional push:
     - git push -u origin feature/minimal-http-server-clean

5) maintained-main neu bauen
   - Trockenlauf (Plan):
     - UPSTREAM_REMOTE=upstream FORK_REMOTE=origin TARGET_BRANCH=maintained-main \
       PR1_BRANCH=feature/global-shortcuts-toggle-wayland-clean PR2_BRANCH=feature/minimal-http-server-clean \
       ALLOW_UNTRACKED=true DRY_RUN=true bash tools/sync_main_with_prs.sh
   - Ausführen (mit Auto-Resolve für build_number):
     - UPSTREAM_REMOTE=upstream FORK_REMOTE=origin TARGET_BRANCH=maintained-main \
       PR1_BRANCH=feature/global-shortcuts-toggle-wayland-clean PR2_BRANCH=feature/minimal-http-server-clean \
       RESOLVE_OURS="build/build_number.txt" \
       ALLOW_UNTRACKED=true bash tools/sync_main_with_prs.sh
   - Optional push (Backup/Sharing):
     - ... PUSH=true bash tools/sync_main_with_prs.sh

6) Verifizieren
   - maintained-main enthält:
     - PR1-clean Dateien (Shortcuts-Toggle und UI)
     - PR2-clean Dateien (HTTP-Trigger, ohne Doku)
   - Prüf-Kommandos:
     - git log --oneline -n 5 maintained-main
     - git diff --name-status upstream/main..maintained-main
     - git ls-tree -r --name-only maintained-main | grep -E '^src/main/httpServer.ts$|^src/main/shortcuts.ts$'

Häufige Stolpersteine und Lösungen
- Non-fast-forward beim Push auf origin/maintained-main:
  - Ursache: maintained-main wurde lokal neu aufgebaut; Remote enthält alte Spitze.
  - Lösung:
    - Tracking setzen: git branch --set-upstream-to=origin/maintained-main maintained-main
    - Push mit Lease: git push --force-with-lease origin maintained-main
- Unversionierte Dateien stören:
  - Lösung A: ALLOW_UNTRACKED=true verwenden.
  - Lösung B: git stash push -u -m "pre-sync" und nachher git stash pop.
- build/build_number.txt Konflikte:
  - RESOLVE_OURS in Skript auf build/build_number.txt setzen (Upstream-Version bevorzugen).
- „Add/Add“-Konflikte bei Fremddateien:
  - Kommt in den -clean Branches idR nicht mehr vor (Scope klein halten).
  - Ansonsten gezielt via RESOLVE_OURS/RESOLVE_THEIRS steuern.

PR-Erstellung (später)
- PR1: feature/global-shortcuts-toggle-wayland-clean → upstream
- PR2: feature/minimal-http-server-clean → upstream
- maintained-main nicht als PR (nur als integrativer Downstream-Branch).

Datei-Notizen
- Diese Dokumentation nicht in PR2 aufnehmen.
- Falls du die Doku lokal behalten, aber nie committen willst:
  - echo 'doc/BRANCH_WORKFLOW.md' >> .git/info/exclude
