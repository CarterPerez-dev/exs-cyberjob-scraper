#!/usr/bin/env bash
# © AngelaMos | 2026
# install.sh
#
# Zero-to-scanning setup for CertScout on a fresh Debian / Ubuntu / Kali box.
# Installs everything it needs (Erlang + Elixir via mise), pulls deps, compiles,
# builds the standalone ./certscout binary, and tells you what to run next.

set -euo pipefail
cd "$(dirname "$0")"

BLUE='\033[0;34m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BOLD='\033[1m'; NC='\033[0m'

banner() {
  printf '%b' "$BLUE"
  cat <<'ART'
   ____          _   ____                  _
  / ___|___ _ __| |_/ ___|  ___ ___  _   _| |_
 | |   / _ \ '__| __\___ \ / __/ _ \| | | | __|
 | |__|  __/ |  | |_ ___) | (_| (_) | |_| | |_
  \____\___|_|   \__|____/ \___\___/ \__,_|\__|
ART
  printf '%b' "$NC"
  printf "   ${BOLD}cybersecurity certification demand scanner${NC}\n\n"
}

say()  { printf "${GREEN}==>${NC} %s\n" "$1"; }
warn() { printf "${YELLOW}==>${NC} %s\n" "$1"; }
die()  { printf "${RED}!! %s${NC}\n" "$1" >&2; exit 1; }

banner

# --- privilege helper: root needs no sudo ---
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  if command -v sudo >/dev/null 2>&1; then SUDO="sudo"; else die "not root and sudo not found — re-run as root"; fi
fi

# --- detect the user's login shell so mise activates in the RIGHT rc file ---
# (the ./certscout escript needs `escript` on PATH at runtime, which mise provides)
USER_SHELL=$(basename "${SHELL:-bash}")
case "$USER_SHELL" in
  zsh)  SHELL_RC="$HOME/.zshrc";  MISE_ACT="zsh"  ;;
  fish) SHELL_RC="$HOME/.config/fish/config.fish"; MISE_ACT="fish" ;;
  *)    SHELL_RC="$HOME/.bashrc"; MISE_ACT="bash" ;;
esac

# --- this installer speaks apt (Debian / Ubuntu / Kali) ---
command -v apt-get >/dev/null 2>&1 || \
  die "non-apt distro detected. Install Elixir 1.18+ yourself, then run: mix deps.get && mix compile && mix escript.build"

# --- skip the toolchain if a good Elixir is already here ---
have_elixir=0
if command -v mix >/dev/null 2>&1 && command -v elixir >/dev/null 2>&1; then
  v=$(elixir --version 2>/dev/null | sed -n 's/^Elixir \([0-9][0-9]*\)\.\([0-9][0-9]*\).*/\1 \2/p')
  maj=${v%% *}; min=${v##* }
  if [ "${maj:-0}" -gt 1 ] 2>/dev/null || { [ "${maj:-0}" -eq 1 ] && [ "${min:-0}" -ge 18 ]; } 2>/dev/null; then
    have_elixir=1
    say "Found Elixir ${maj}.${min} — using it, skipping toolchain install."
  else
    warn "Found Elixir ${maj}.${min}, but CertScout needs 1.18+. Installing a newer one alongside it."
  fi
fi

if [ "$have_elixir" -eq 0 ]; then
  say "Installing system build dependencies (one-time)…"
  export DEBIAN_FRONTEND=noninteractive

  # Don't let a broken UNRELATED third-party repo (dead PPA, SHA1-signed key, etc.)
  # abort the install — refresh what we can and carry on with existing indexes.
  $SUDO apt-get update -y || warn "apt-get update reported errors (usually broken third-party repos unrelated to CertScout) — continuing with cached package lists."

  if ! $SUDO apt-get install -y --no-install-recommends \
    curl git build-essential automake autoconf m4 \
    libncurses-dev libssl-dev libssh-dev unixodbc-dev libgmp-dev ca-certificates; then
    die "Could not install build dependencies. Check that the main Debian/Ubuntu repos work (try: sudo apt-get update), then re-run ./install.sh"
  fi

  # mise — the current (2026) way to manage Erlang/Elixir versions
  if ! command -v mise >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/mise" ]; then
    say "Installing mise (version manager)…"
    curl -fsSL https://mise.run | sh
  fi
  export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"

  say "Installing Erlang/OTP 27 (compiles from source — ~5-10 min, grab a coffee)…"
  mise use -g erlang@27

  # Elixir ships separate builds per OTP generation (…-otp-27, …-otp-28). A bare
  # 'elixir@1.18' lets mise pick the otp-28 build, which then refuses to run on the
  # OTP 27 we just installed. Pin the matching otp-27 build explicitly.
  say "Selecting a matching Elixir 1.18 (OTP 27 build)…"
  elixir_ver=$(mise ls-remote elixir 2>/dev/null | grep -E '^1\.18\.[0-9]+-otp-27$' | tail -1)
  [ -n "$elixir_ver" ] || elixir_ver=$(mise ls-remote elixir 2>/dev/null | grep -E -- '-otp-27$' | tail -1)
  [ -n "$elixir_ver" ] || die "no OTP-27 Elixir build found via mise. Run 'mise ls-remote elixir', pick a *-otp-27 version, then: mise use -g elixir@<version>"
  say "  -> elixir $elixir_ver"
  mise use -g "elixir@$elixir_ver"
  hash -r

  command -v mix >/dev/null 2>&1 || \
    die "Elixir still not on PATH. Open a new shell and re-run, or add to $SHELL_RC:  eval \"\$(~/.local/bin/mise activate $MISE_ACT)\""

  # make 'mix' and 'escript' available in future interactive shells (mise shims on PATH)
  if ! grep -qs 'mise activate' "$SHELL_RC" 2>/dev/null; then
    mkdir -p "$(dirname "$SHELL_RC")"
    if [ "$MISE_ACT" = "fish" ]; then
      printf '\n# CertScout / mise\n%s/.local/bin/mise activate fish | source\n' "$HOME" >> "$SHELL_RC"
    else
      printf '\n# CertScout / mise\neval "$(%s/.local/bin/mise activate %s)"\n' "$HOME" "$MISE_ACT" >> "$SHELL_RC"
    fi
    warn "Added mise to $SHELL_RC — new terminals will have mix/escript on PATH automatically."
  fi
fi

# --- project setup ---
say "Installing Hex + Rebar…"
mix local.hex --force >/dev/null
mix local.rebar --force >/dev/null

say "Fetching dependencies…"
mix deps.get

say "Compiling CertScout…"
mix compile

say "Building the standalone ./certscout binary…"
mix escript.build >/dev/null

printf "\n${GREEN}${BOLD}CertScout is ready.${NC}\n\n"

# The ./certscout escript needs `escript` (Erlang) on PATH. If this shell doesn't
# have mise active yet, point the user at the one command that fixes it.
if ! command -v escript >/dev/null 2>&1; then
  printf "%bFirst, load Erlang/Elixir into your current shell:%b\n\n" "$YELLOW" "$NC"
  printf "    eval \"\$(~/.local/bin/mise activate %s)\"\n" "$MISE_ACT"
  printf "  (already added to %s, so new terminals do this automatically.)\n\n" "$SHELL_RC"
fi

cat <<'NEXT'
Run a quick scan (no API keys, ~1 minute):

    ./certscout --sources greenhouse

See every option:

    ./certscout --help

Results land in ./output — open output/REPORT.md, or read the raw data in output/data/.
NEXT
