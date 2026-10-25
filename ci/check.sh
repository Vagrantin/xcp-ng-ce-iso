#!/usr/bin/env bash
# What "checked" means for this repo (xcp-hl#148). Jenkins dev/xcp-ng-ce-iso runs it on every PR; run it locally too.
# Contract: exit 0 when clean; results under $CI_RESULTS; on failure $CI_RESULTS/current-step names the failed check.
# The ISO itself is built by build-iso.yml and tested installed by Test's iso-smoke-test (xcp-hl#149).
set -euo pipefail
cd "$(dirname "$0")/.."

OUT="${CI_RESULTS:-ci-results}"
mkdir -p "$OUT"
step() { echo "==> $1"; echo "$1" > "$OUT/current-step"; }

step "shellcheck release scripts (warnings and errors)"
git ls-files -z '*.sh' ':!:debug/' | xargs -0 -r shellcheck -S warning

# debug/ holds local helper tools: errors fail now; their warnings are a follow-up on xcp-hl#148.
step "shellcheck debug tools (errors)"
git ls-files -z 'debug/*.sh' | xargs -0 -r shellcheck -S error

rm -f "$OUT/current-step"
echo "all checks passed"
