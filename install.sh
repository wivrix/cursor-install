#!/usr/bin/env bash
# Install the Cursor CLI and match a CLI-only machine:
#   - `cursor` starts the agent (no IDE required)
#   - approval mode is Run Everything (unrestricted)
#   - ~/.local/bin is on PATH in the shell startup files
#
# Safe to run more than once.
set -euo pipefail

CURSOR_BIN_DIR="${HOME}/.local/bin"
CURSOR_CONFIG_DIR="${HOME}/.cursor"
AGENT_BIN="${CURSOR_BIN_DIR}/agent"
LAUNCHER="${CURSOR_BIN_DIR}/cursor"

BEGIN_MARK="# >>> cursor-install >>>"
END_MARK="# <<< cursor-install <<<"

log() {
  printf '==> %s\n' "$*"
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"
}

shell_block() {
  cat <<EOF
${BEGIN_MARK}
# Cursor CLI. \`cursor\` starts the agent.
export PATH="\$HOME/.local/bin:\$PATH"
${END_MARK}
EOF
}

# Insert the PATH block once. Skip when the file already puts .local/bin on PATH.
configure_rc() {
  local file="$1"
  local create="${2:-no}"

  if [ ! -f "$file" ]; then
    if [ "$create" != "yes" ]; then
      return 0
    fi
    mkdir -p "$(dirname "$file")"
    shell_block >"$file"
    log "created ${file}"
    return 0
  fi

  if grep -qF "$BEGIN_MARK" "$file"; then
    log "shell config already present in ${file}"
    return 0
  fi

  if grep -q '\.local/bin' "$file"; then
    log "PATH already includes .local/bin in ${file}"
    return 0
  fi

  printf '\n' >>"$file"
  shell_block >>"$file"
  log "updated ${file}"
}

configure_shells() {
  case "$(uname -s)" in
    Darwin)
      configure_rc "${HOME}/.zshrc" yes
      if [ -f "${HOME}/.bashrc" ]; then
        configure_rc "${HOME}/.bashrc" no
      fi
      ;;
    *)
      configure_rc "${HOME}/.bashrc" yes
      configure_rc "${HOME}/.profile" yes
      if [ -f "${HOME}/.zshrc" ] || [[ "${SHELL:-}" == */zsh ]]; then
        configure_rc "${HOME}/.zshrc" yes
      fi
      ;;
  esac

  # Do not create ~/.bash_profile. On bash, that file shadows ~/.profile.
  if [ -f "${HOME}/.bash_profile" ]; then
    configure_rc "${HOME}/.bash_profile" no
  fi
}

install_cli() {
  need_cmd curl
  log "installing Cursor CLI"
  curl https://cursor.com/install -fsS | bash
  [ -x "$AGENT_BIN" ] || die "Cursor agent was not installed at ${AGENT_BIN}"
}

# Bare `cursor` starts the agent. `cursor agent ...` does the same.
# If a Cursor IDE binary exists elsewhere on PATH, other subcommands still reach it.
write_launcher() {
  mkdir -p "$CURSOR_BIN_DIR"
  cat >"$LAUNCHER" <<'EOF'
#!/bin/sh
# Start command is the Cursor agent. Installed by cursor-install.
set -eu

AGENT="${HOME}/.local/bin/agent"

find_ide_cursor() {
  old_IFS=$IFS
  IFS=:
  for dir in $PATH; do
    [ -n "$dir" ] || continue
    cursor_path="$dir/cursor"
    if [ "$cursor_path" != "$HOME/.local/bin/cursor" ] && [ -x "$cursor_path" ]; then
      IFS=$old_IFS
      printf '%s\n' "$cursor_path"
      return 0
    fi
  done
  IFS=$old_IFS
  return 1
}

if [ ! -x "$AGENT" ]; then
  echo "Cursor agent is not installed at $AGENT" >&2
  exit 1
fi

if [ "$#" -eq 0 ] || [ "${1:-}" = "agent" ]; then
  if [ "${1:-}" = "agent" ]; then
    shift
  fi
  exec "$AGENT" "$@"
fi

if IDE=$(find_ide_cursor); then
  exec "$IDE" "$@"
fi

exec "$AGENT" "$@"
EOF
  chmod 755 "$LAUNCHER"
  log "set start command: cursor -> agent"
}

# Run Everything, same as this machine's approvalMode "unrestricted".
configure_cli() {
  need_cmd python3
  mkdir -p "$CURSOR_CONFIG_DIR"
  python3 - "$CURSOR_CONFIG_DIR/cli-config.json" <<'PY'
import json
import os
import sys

path = sys.argv[1]
cfg = {}
if os.path.exists(path):
    try:
        with open(path, encoding="utf-8") as fh:
            loaded = json.load(fh)
        if isinstance(loaded, dict):
            cfg = loaded
    except json.JSONDecodeError:
        backup = path + ".bad"
        os.replace(path, backup)
        print(f"backed up invalid config to {backup}", file=sys.stderr)

cfg["version"] = cfg.get("version", 1) or 1

editor = cfg.get("editor")
if not isinstance(editor, dict):
    editor = {}
editor.setdefault("vimMode", False)
editor["defaultBehavior"] = "agent"
cfg["editor"] = editor

permissions = cfg.get("permissions")
if not isinstance(permissions, dict):
    permissions = {}
allow = permissions.get("allow")
if not isinstance(allow, list):
    allow = []
if "Shell(.*)" not in allow:
    allow.append("Shell(.*)")
deny = permissions.get("deny")
if not isinstance(deny, list):
    deny = []
permissions["allow"] = allow
permissions["deny"] = deny
cfg["permissions"] = permissions

# Run Everything. Auto-approves tool calls (--force / --yolo).
cfg["approvalMode"] = "unrestricted"

sandbox = cfg.get("sandbox")
if not isinstance(sandbox, dict):
    sandbox = {}
sandbox["mode"] = "disabled"
sandbox.setdefault("networkAccess", "user_config_with_defaults")
cfg["sandbox"] = sandbox

network = cfg.get("network")
if not isinstance(network, dict):
    network = {}
network.setdefault("useHttp1ForAgent", False)
cfg["network"] = network

attribution = cfg.get("attribution")
if not isinstance(attribution, dict):
    attribution = {}
attribution.setdefault("attributeCommitsToAgent", True)
attribution.setdefault("attributePRsToAgent", True)
cfg["attribution"] = attribution

with open(path, "w", encoding="utf-8") as fh:
    json.dump(cfg, fh, indent=2)
    fh.write("\n")
PY
  log "approval mode: Run Everything (unrestricted)"
}

main() {
  need_cmd curl
  install_cli
  write_launcher
  configure_shells
  configure_cli

  export PATH="${CURSOR_BIN_DIR}:${PATH}"
  log "installed: $("${AGENT_BIN}" --version)"
  cat <<EOF

Cursor is installed.
  cursor              start the agent
  agent               same agent binary
  approval mode       Run Everything (unrestricted)

Open a new shell so PATH is picked up, then sign in once:

  agent login

EOF
}

main "$@"
