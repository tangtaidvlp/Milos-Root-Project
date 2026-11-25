#!/usr/bin/env bash
# Create an isolated worktree for one work item so it can run in parallel with others.
# Usage: new-worktree.sh <spec-dir-name> [base-ref]   e.g. new-worktree.sh F017-goal-sync
# Result: ../Projects.worktrees/<dir> on branch <feat|fix>/<dir> (root + ms/ui submodules),
#         draft folder moved in, .specify/feature.json set. Open a new Claude session there.
set -euo pipefail

DIR="${1:?usage: new-worktree.sh <spec-dir-name> [base-ref]}"
BASE="${2:-main}"
MAIN_ROOT="$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")"
WT_ROOT="$(dirname "$MAIN_ROOT")/$(basename "$MAIN_ROOT").worktrees"
WT="$WT_ROOT/$DIR"
case "$DIR" in B*|*-fix-*) PREFIX=fix ;; *) PREFIX=feat ;; esac
BRANCH="$PREFIX/$DIR"
CODE_SUBMODULES=(ms-personal-routine-manager ui-personal-routine-manager)

[[ -e "$WT" ]] && { echo "ERROR: $WT already exists" >&2; exit 1; }
git -C "$MAIN_ROOT" show-ref --verify --quiet "refs/heads/$BRANCH" \
  && { echo "ERROR: branch $BRANCH already exists (in use by another worktree?)" >&2; exit 1; }

mkdir -p "$WT_ROOT"
git -C "$MAIN_ROOT" worktree add -b "$BRANCH" "$WT" "$BASE"
git -C "$WT" submodule update --init

for sm in "${CODE_SUBMODULES[@]}"; do
  git -C "$WT/$sm" fetch -q origin
  git -C "$WT/$sm" switch -q --no-track -c "$BRANCH" "origin/$BASE"
done

# Move an untracked draft folder from the main checkout so it lives in one place only.
if [[ -d "$MAIN_ROOT/specs/$DIR" && ! -d "$WT/specs/$DIR" ]]; then
  mv "$MAIN_ROOT/specs/$DIR" "$WT/specs/$DIR"
fi
mkdir -p "$WT/specs/$DIR"
printf '{ "feature_directory": "specs/%s" }\n' "$DIR" > "$WT/.specify/feature.json"

echo "WORKTREE=$WT"
echo "BRANCH=$BRANCH"
