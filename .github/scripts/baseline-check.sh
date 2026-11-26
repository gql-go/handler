#!/usr/bin/env bash
# Compares the exported API of the module at HEAD with the upstream release it
# promises compatibility with, and fails on any incompatible change other than
# the module path rename.
#
# Usage: .github/scripts/baseline-check.sh <module@version> <old-path=new-path>...
# Example: .github/scripts/baseline-check.sh github.com/graphql-go/graphql@v0.8.1 \
#            github.com/graphql-go/graphql=github.com/gql-go/graphql
set -euo pipefail

baseline=${1:?usage: baseline-check.sh <module@version> <old-path=new-path>...}
shift
gorelease_version=v0.0.0-20261124000051-d6646c509b6d

work=$(mktemp -d)
trap 'rm -rf "${work:?}"' EXIT

GOBIN="$work/bin" go install "golang.org/x/exp/cmd/gorelease@$gorelease_version"

# gorelease never fails on incompatible changes in a v0 module, so the report
# is parsed instead of relying on the exit status.
status=0
GOWORK=off GOOS=linux "$work/bin/gorelease" -base="$baseline" >"$work/report.txt" 2>&1 || status=$?
if [ "$status" -ne 0 ]; then
	cat "$work/report.txt"
	echo "::error::gorelease failed with status $status."
	exit 1
fi

rename() {
	local s=$1 pair
	for pair in "${mappings[@]}"; do
		s=${s//"${pair%%=*}"/"${pair#*=}"}
	done
	printf '%s' "$s"
}

mappings=("$@")
section=""
package=""
breaks=()
renamed=0
while IFS= read -r line; do
	case $line in
	"# "*) package=${line#"# "} ;;
	"## "*) section=${line#"## "} ;;
	"") ;;
	*)
		[ "$section" = "incompatible changes" ] || continue
		if [[ $line =~ ^(.*):\ changed\ from\ (.*)\ to\ (.*)$ ]] &&
			[ "$(rename "${BASH_REMATCH[2]}")" = "${BASH_REMATCH[3]}" ]; then
			renamed=$((renamed + 1))
			continue
		fi
		breaks+=("$(rename "$package"): $line")
		;;
	esac
done <"$work/report.txt"

echo "Compared with $baseline: ${#breaks[@]} incompatible changes, $renamed module path renames ignored."
if [ "${#breaks[@]}" -gt 0 ]; then
	printf '  %s\n' "${breaks[@]}"
	echo "::error::Incompatible changes against $baseline. See AGENTS.md, rule 1."
	exit 1
fi
