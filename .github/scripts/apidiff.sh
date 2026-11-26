#!/usr/bin/env bash
# Compares the exported API of the module at HEAD with a base git revision and
# fails if any change is incompatible.
#
# Usage: .github/scripts/apidiff.sh <base-revision>
set -euo pipefail

base=${1:?usage: apidiff.sh <base-revision>}
apidiff_version=v0.0.0-20261124000051-d6646c509b6d

module=$(go list -m)
work=$(mktemp -d)
cleanup() {
	git worktree remove --force "$work/base" >/dev/null 2>&1 || true
	rm -rf "${work:?}"
}
trap cleanup EXIT

GOBIN="$work/bin" go install "golang.org/x/exp/cmd/apidiff@$apidiff_version"
apidiff="$work/bin/apidiff"

git worktree add --quiet --detach "$work/base" "$base"

# Type-check for Linux so the result does not depend on the host OS.
export GOWORK=off GOOS=linux
(cd "$work/base" && "$apidiff" -m -w "$work/base.export" "$module")
"$apidiff" -m -w "$work/head.export" "$module"

report=$("$apidiff" -m "$work/base.export" "$work/head.export")
incompatible=$("$apidiff" -m -incompatible "$work/base.export" "$work/head.export")

summary="## Exported API changes against $(git rev-parse --short=12 "$base")"$'\n\n'
if [ -n "$report" ]; then
	summary+='```'$'\n'"$report"$'\n''```'
else
	summary+="No changes to the exported API."
fi
echo "$summary"
if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
	echo "$summary" >>"$GITHUB_STEP_SUMMARY"
fi

if [ -n "$incompatible" ]; then
	echo "::error::Incompatible changes to the exported API. Changes must be additive; see AGENTS.md, rule 1."
	exit 1
fi
