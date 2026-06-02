# © AngelaMos | 2026
# Justfile

image := "elixir:1.18-otp-27-alpine"
docker := "docker run --rm -u $(id -u):$(id -g) -e HOME=/work -e MIX_HOME=/work/.mix -e HEX_HOME=/work/.hex -v \"$PWD\":/work -w /work " + image

# Use local mix if installed, otherwise fall back to the official elixir Docker image.
# `eval` is required so $(id -u)/$PWD inside `docker` expand at recipe time, not before.
_runner := "if command -v mix >/dev/null 2>&1; then RUN=''; else RUN='" + docker + "'; fi"

default:
    @just --list

# One-command setup on a bare Debian/Ubuntu/Kali box (installs Elixir, deps, builds the binary).
install:
    ./install.sh

setup:
    #!/usr/bin/env bash
    set -euo pipefail
    {{_runner}}
    eval "$RUN sh -c 'mix local.hex --force && mix local.rebar --force && mix deps.get && mix compile'"

test:
    #!/usr/bin/env bash
    set -euo pipefail
    {{_runner}}
    eval "$RUN mix test"

fmt:
    #!/usr/bin/env bash
    set -euo pipefail
    {{_runner}}
    eval "$RUN mix format"

build:
    #!/usr/bin/env bash
    set -euo pipefail
    {{_runner}}
    eval "$RUN mix escript.build"

run *ARGS:
    #!/usr/bin/env bash
    set -euo pipefail
    {{_runner}}
    eval "$RUN mix run -e 'CertScout.CLI.main(System.argv())' -- {{ARGS}}"

demo:
    #!/usr/bin/env bash
    set -euo pipefail
    {{_runner}}
    eval "$RUN mix run -e 'CertScout.CLI.main([\"--sources\",\"greenhouse\"])'"

logos:
    #!/usr/bin/env bash
    set -euo pipefail
    {{_runner}}
    eval "$RUN mix run -e 'CertScout.Logos.download_all(CertScout.Certifications.default(), \"output/assets\", CertScout.Config.new([]))'"

clean:
    rm -rf _build deps output .mix .hex certscout
