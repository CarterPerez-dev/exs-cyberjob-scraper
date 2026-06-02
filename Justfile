# © AngelaMos | 2026
# Justfile

image := "elixir:1.18-otp-27-alpine"
docker := "docker run --rm -u $(id -u):$(id -g) -e HOME=/work -e MIX_HOME=/work/.mix -e HEX_HOME=/work/.hex -v \"$PWD\":/work -w /work " + image

_runner := "if command -v mix >/dev/null 2>&1; then RUN=\"\"; else RUN='" + docker + "'; fi"

default:
    @just --list

setup:
    #!/usr/bin/env bash
    set -euo pipefail
    {{_runner}}
    $RUN sh -c "mix local.hex --force && mix local.rebar --force && mix deps.get && mix compile"

test:
    #!/usr/bin/env bash
    set -euo pipefail
    {{_runner}}
    $RUN mix test

fmt:
    #!/usr/bin/env bash
    set -euo pipefail
    {{_runner}}
    $RUN mix format

build:
    #!/usr/bin/env bash
    set -euo pipefail
    {{_runner}}
    $RUN mix escript.build

run *ARGS:
    #!/usr/bin/env bash
    set -euo pipefail
    {{_runner}}
    $RUN mix run -e "CertScout.CLI.main(System.argv())" -- {{ARGS}}

demo:
    #!/usr/bin/env bash
    set -euo pipefail
    {{_runner}}
    $RUN mix run -e "CertScout.CLI.main([\"--sources\",\"greenhouse\"])"

logos:
    #!/usr/bin/env bash
    set -euo pipefail
    {{_runner}}
    $RUN mix run -e "CertScout.Logos.download_all(CertScout.Certifications.default(), \"output/assets\", CertScout.Config.new([]))"

clean:
    rm -rf _build deps output .mix .hex certscout
