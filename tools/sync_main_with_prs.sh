#!/usr/bin/env bash
#
# sync_main_with_prs.sh
#
# Zweck:
# - Upstream-Änderungen holen (upstream/main)
# - Lokalen Ziel-Branch (standard: main) neu auf upstream/main aufsetzen
# - Dann PR1 und PR2 der eigenen Fork (origin) in definierter Reihenfolge mergen
# - Optional pushen
#
# Standard-PR-Branches (aus deiner Doku):
#   PR1: feature/global-shortcuts-toggle-wayland
#   PR2: feature/minimal-http-server
#
# Nutzung (Beispiele):
#   bash tools/sync_main_with_prs.sh
#   PUSH=true bash tools/sync_main_with_prs.sh
#   PREFER_PR2=true bash tools/sync_main_with_prs.sh
#
# Konfiguration via Umgebungsvariablen:
#   UPSTREAM_REMOTE   Standard: upstream
#   FORK_REMOTE       Standard: origin
#   TARGET_BRANCH     Standard: main
#   PR1_BRANCH        Standard: feature/global-shortcuts-toggle-wayland
#   PR2_BRANCH        Standard: feature/minimal-http-server
#   PUSH              Standard: false  (true, um nach origin zu pushen)
#   PREFER_PR2        Standard: false  (true = Merge-Konflikte zugunsten PR2 auflösen: -X theirs)
#   DRY_RUN           Standard: false  (true = nur anzeigen, was passieren würde)
#   ALLOW_UNTRACKED   Standard: false  (true = unversionierte Dateien erlauben; Änderungen müssen trotzdem 0 sein)
#   RESOLVE_OURS      Standard: leer   (Komma-separierte Pfade, die bei Konflikten auf Upstream/ours gesetzt werden, z. B.: "build/build_number.txt,src/components/MessageItemArtifactBlock.vue")
#   RESOLVE_THEIRS    Standard: leer   (Komma-separierte Pfade, die bei Konflikten auf eingehenden PR/theirs gesetzt werden)
#
# Voraussetzungen:
# - Dieses Repo hat remotes "origin" (dein Fork) und "upstream" (Original).
# - Arbeitsverzeichnis ist sauber (keine uncommitted Änderungen).
# - Branchnamen existieren auf dem FORK_REMOTE (origin) oder lokal.
#
set -euo pipefail

UPSTREAM_REMOTE="${UPSTREAM_REMOTE:-upstream}"
FORK_REMOTE="${FORK_REMOTE:-origin}"
TARGET_BRANCH="${TARGET_BRANCH:-main}"

PR1_BRANCH="${PR1_BRANCH:-feature/global-shortcuts-toggle-wayland}"
PR2_BRANCH="${PR2_BRANCH:-feature/minimal-http-server}"

PUSH="${PUSH:-false}"
PREFER_PR2="${PREFER_PR2:-false}"
DRY_RUN="${DRY_RUN:-false}"
RESOLVE_OURS="${RESOLVE_OURS:-}"
RESOLVE_THEIRS="${RESOLVE_THEIRS:-}"

info() { printf "[INFO] %s\n" "$*" >&2; }
warn() { printf "[WARN] %s\n" "$*" >&2; }
err()  { printf "[ERR ] %s\n" "$*" >&2; }
die()  { err "$*"; exit 1; }

require_git_repo() {
  git rev-parse --is-inside-work-tree &>/dev/null || die "Kein Git-Repository."
}

require_clean_worktree() {
  # Bei DRY_RUN Worktree-Prüfung überspringen (wir zeigen nur den Plan)
  if [ "${DRY_RUN:-false}" = "true" ]; then
    return 0
  fi

  local s
  if [ "${ALLOW_UNTRACKED:-false}" = "true" ]; then
    # Unversionierte Dateien ignorieren (Zeilen, die mit "?? " beginnen)
    # Bleibt etwas anderes übrig, ist die Worktree NICHT sauber.
    s="$(git status --porcelain | grep -v '^[?][?] ' || true)"
  else
    s="$(git status --porcelain)"
  fi

  if [ -n "$s" ]; then
    if [ "${ALLOW_UNTRACKED:-false}" = "true" ]; then
      die "Arbeitsverzeichnis hat Änderungen (abgesehen von unversionierten Dateien). Bitte committe/stashe diese und starte erneut."
    else
      die "Arbeitsverzeichnis ist nicht sauber. Bitte committe/stashe deine Änderungen und starte erneut."
    fi
  fi
}

check_remote_exists() {
  local remote="$1"
  git remote get-url "$remote" &>/dev/null || die "Remote '$remote' ist nicht konfiguriert."
}

check_remote_branch_exists() {
  local remote="$1"
  local branch="$2"
  local out
  out="$(git ls-remote --heads "$remote" "$branch" 2>/dev/null)" || die "Fehler bei 'git ls-remote' für $remote/$branch."
  if [ -z "$out" ]; then
    die "Branch '$branch' existiert nicht auf Remote '$remote'."
  fi
}

print_plan() {
  cat >&2 <<EOF
Plan:
- Fetch von '$UPSTREAM_REMOTE' und '$FORK_REMOTE'
- Checkout/Reset '$TARGET_BRANCH' auf '$UPSTREAM_REMOTE/main'
- Merge PR1: ${PR1_REF:-$FORK_REMOTE/$PR1_BRANCH} (--no-ff --no-edit)
- Merge PR2: ${PR2_REF:-$FORK_REMOTE/$PR2_BRANCH} (--no-ff --no-edit$([ "$PREFER_PR2" = "true" ] && printf " -X theirs"))
$([ "$PUSH" = "true" ] && printf "- Push nach %s %s\n" "$FORK_REMOTE" "$TARGET_BRANCH")
EOF
}

# Merge-Helfer mit Auto-Resolve für definierte Pfade
merge_branch() {
  local ref="$1"
  local prefer_theirs="${2:-false}"
  local opts=(--no-ff --no-edit)
  if [ "$prefer_theirs" = "true" ]; then
    opts+=(-X theirs)
  fi

  if git merge "${opts[@]}" "$ref"; then
    info "Merge von $ref erfolgreich."
    return 0
  fi

  warn "Konflikte beim Merge von $ref. Versuche Auto-Resolve..."
  # Auf ours (Upstream/Zielbranch) setzen
  if [ -n "$RESOLVE_OURS" ]; then
    IFS=',' read -ra _OURS <<< "$RESOLVE_OURS"
    for p in "${_OURS[@]}"; do
      [ -n "$p" ] || continue
      git checkout --ours -- "$p" 2>/dev/null || true
      git add -f -- "$p" 2>/dev/null || true
    done
  fi
  # Auf theirs (eingehender PR) setzen
  if [ -n "$RESOLVE_THEIRS" ]; then
    IFS=',' read -ra _THEIRS <<< "$RESOLVE_THEIRS"
    for p in "${_THEIRS[@]}"; do
      [ -n "$p" ] || continue
      git checkout --theirs -- "$p" 2>/dev/null || true
      git add -f -- "$p" 2>/dev/null || true
    done
  fi

  # Prüfen, ob noch ungemergte Dateien existieren
  if git diff --name-only --diff-filter=U | grep -q .; then
    err "Konflikte verbleiben nach Auto-Resolve. Bitte manuell lösen oder 'git merge --abort'."
    return 1
  fi

  git commit -m "Merge $ref (auto-resolved)"
  info "Merge von $ref mit Auto-Resolve abgeschlossen."
  return 0
}

main() {
  require_git_repo
  # Worktree-Prüfung berücksichtigt DRY_RUN/ALLOW_UNTRACKED
  require_clean_worktree
  check_remote_exists "$UPSTREAM_REMOTE"
  check_remote_exists "$FORK_REMOTE"

  check_remote_branch_exists "$UPSTREAM_REMOTE" "main"

  # PR-Quellen auflösen: bevorzugt Remote-Refs ($FORK_REMOTE), sonst lokale Branches
  PR1_REF="$FORK_REMOTE/$PR1_BRANCH"
  if ! git ls-remote --heads "$FORK_REMOTE" "$PR1_BRANCH" >/dev/null 2>&1 || [ -z "$(git ls-remote --heads "$FORK_REMOTE" "$PR1_BRANCH")" ]; then
    if git show-ref --verify --quiet "refs/heads/$PR1_BRANCH"; then
      PR1_REF="$PR1_BRANCH"
    else
      die "PR1-Branch '$PR1_BRANCH' weder auf Remote '$FORK_REMOTE' noch lokal gefunden."
    fi
  fi

  PR2_REF="$FORK_REMOTE/$PR2_BRANCH"
  if ! git ls-remote --heads "$FORK_REMOTE" "$PR2_BRANCH" >/dev/null 2>&1 || [ -z "$(git ls-remote --heads "$FORK_REMOTE" "$PR2_BRANCH")" ]; then
    if git show-ref --verify --quiet "refs/heads/$PR2_BRANCH"; then
      PR2_REF="$PR2_BRANCH"
    else
      die "PR2-Branch '$PR2_BRANCH' weder auf Remote '$FORK_REMOTE' noch lokal gefunden."
    fi
  fi

  info "UPSTREAM_REMOTE=$UPSTREAM_REMOTE"
  info "FORK_REMOTE=$FORK_REMOTE"
  info "TARGET_BRANCH=$TARGET_BRANCH"
  info "PR1_BRANCH=$PR1_BRANCH"
  info "PR2_BRANCH=$PR2_BRANCH"
  info "PREFER_PR2=$PREFER_PR2"
  info "PUSH=$PUSH"
  print_plan

  if [ "$DRY_RUN" = "true" ]; then
    info "DRY_RUN=true → es werden keine Änderungen durchgeführt."
    exit 0
  fi

  info "Fetch --all --prune"
  git fetch --all --prune

  # Sicherungs-Branch anlegen (optional, falls TARGET_BRANCH existiert)
  if git rev-parse --verify "$TARGET_BRANCH" &>/dev/null; then
    local backup="backup/${TARGET_BRANCH}-$(date +%Y%m%d-%H%M%S)"
    info "Erzeuge Backup-Branch: $backup"
    git branch -f "$backup" "$TARGET_BRANCH" || true
  fi

  info "Setze '$TARGET_BRANCH' auf '$UPSTREAM_REMOTE/main'"
  git checkout -B "$TARGET_BRANCH" "$UPSTREAM_REMOTE/main"

  # Hilfreich, falls Konflikte einmal manuell gelöst wurden:
  git config rerere.enabled true || true

  info "Merge PR1: $PR1_REF"
  merge_branch "$PR1_REF" "false" || {
    err "Konflikte beim Merge von PR1. Bitte 'git status' prüfen und Konflikte lösen (oder 'git merge --abort')."
    exit 1
  }

  info "Prüfe, ob PR2 gegenüber aktuellem Stand zusätzliche Änderungen einbringt..."
  if git diff --quiet --no-ext-diff HEAD.."$PR2_REF"; then
    info "PR2 bringt keine Änderungen (No-Op) – überspringe Merge."
  else
    info "Merge PR2: $PR2_REF"
    if [ "$PREFER_PR2" = "true" ]; then
      merge_branch "$PR2_REF" "true" || {
        err "Konflikte beim Merge von PR2 trotz -X theirs. Bitte manuell lösen oder 'git merge --abort'."
        exit 1
      }
    else
      merge_branch "$PR2_REF" "false" || {
        err "Konflikte beim Merge von PR2. Tipp: Erneut starten mit PREFER_PR2=true, wenn PR2 bevorzugt werden soll."
        err "Oder Konflikte manuell lösen und committen."
        exit 1
      }
    fi
  fi

  info "Integration erfolgreich gemerged in '$TARGET_BRANCH'."
  git log --oneline -n 10 | sed 's/^/[LOG ] /' >&2

  if [ "$PUSH" = "true" ]; then
    info "Pushe '$TARGET_BRANCH' nach '$FORK_REMOTE'..."
    git push "$FORK_REMOTE" "$TARGET_BRANCH"
    info "Push abgeschlossen."
  else
    info "Kein Push durchgeführt. Setze PUSH=true, um automatisch zu pushen."
  fi

  info "Fertig."
}

main "$@"
