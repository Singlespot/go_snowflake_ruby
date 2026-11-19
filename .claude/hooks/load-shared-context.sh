#!/bin/sh
# Claude Code SessionStart hook: load one shared context index into the
# session, or warn that its repository is not cloned.
#
# Context is a chain: project -> ecosystem context (kura-context,
# atlas-context) -> tech-context; a project with no ecosystem context links to
# tech-context directly. Each repository runs this hook once per link of its
# chain, and the hook hands Claude that link's CONTEXT.md.
#
# Why a hook and not `@../<name>/CONTEXT.md` in CLAUDE.md: Claude Code loads a
# CLAUDE.md import from outside the project only once the person has approved
# external imports for that project, and skips it without a word otherwise —
# also when the repository is not cloned, and from a worktree under
# .claude/worktrees/, which has no siblings. Measured 2026-11-19: kura and
# atlas-tracking-api never loaded their ecosystem index, clone present.
#
# CANONICAL COPY: Singlespot/tech-context, scripts/load-shared-context.sh.
# Every repository carries its own copy in .claude/hooks/, because the hook
# has to run precisely when tech-context is absent. Edit the canonical copy,
# then propagate it (README.md, "Wiring a repository").
#
# Usage, one hook command per link, in the project's .claude/settings.json:
#   sh "$CLAUDE_PROJECT_DIR/.claude/hooks/load-shared-context.sh" tech-context
#
# One link per command because Claude Code caps a hook's additionalContext at
# 10,000 characters: past that, Claude gets a 2 KB preview and a file path
# instead. The cap is per command (measured), so each index gets its own; an
# index too long for what the cap leaves after this hook's own header is
# loaded in whole lines up to it, with the path to read the rest. Hook
# commands run in parallel: links arrive in no guaranteed order.
#
# Prints Claude Code hook JSON. Always exits 0: loading context must never get
# in the way of a session.

name=$1
[ -n "$name" ] || exit 0
project=${CLAUDE_PROJECT_DIR:-$PWD}
cap=9800 # characters per hook string, under Claude Code's 10,000 with a margin

# Siblings are looked for next to the main clone, not next to this checkout:
# a worktree under .claude/worktrees/ has no siblings of its own.
common=$(git -C "$project" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
case $common in
  */.git) base=$(dirname "$(dirname "$common")") ;;
  *) base=$(dirname "$project") ;;
esac
base=$(cd "$base" 2>/dev/null && pwd -P) || exit 0
dir=${base%/}/$name
index=$dir/CONTEXT.md

# JSON string body from stdin: drop control characters other than tab and
# newline (carriage returns included), escape backslashes, quotes and tabs,
# join lines with \n. Portable to BSD and GNU tr/sed/awk.
tab=$(printf '\t')
json() {
  LC_ALL=C tr -d '\000-\010\013-\037' |
    sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e "s/$tab/\\\\t/g" |
    awk '{ printf "%s%s", sep, $0; sep = "\\n" }'
}

emit() { # $1 systemMessage (may be empty), $2 additionalContext, both raw text
  printf '{'
  [ -n "$1" ] && printf '"systemMessage":"%s",' "$(printf '%s\n' "$1" | json)"
  printf '"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' \
    "$(printf '%s\n' "$2" | json)"
  exit 0
}

# What Claude is told when a link is unusable: generic, because the same
# script serves every link and only the index knows what its repo covers.
unusable="so its index is not loaded and Claude does not know the conventions and decisions it carries. Before relying on Singlespot-wide or ecosystem conventions, or when the user asks about them, first tell the user that this context is missing and give them the command:"

clone="git clone git@github.com:Singlespot/$name.git \"$dir\""
if [ ! -d "$dir" ]; then
  emit "Shared context not cloned: $name. Claude is working without the conventions it carries. Clone it next to this repository:
  $clone" \
    "The shared context repository $name is not cloned at $dir, $unusable $clone"
fi

if [ "$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null)" != "$(cd "$dir" && pwd -P)" ]; then
  emit "Shared context unusable: git does not see $dir as a clone of $name (not a clone, or refused by safe.directory). If it is not a clone, move it aside, then clone:
  $clone" \
    "git does not see $dir as a clone of $name (not a clone, or refused by safe.directory), $unusable $clone"
fi

if [ ! -f "$index" ]; then
  pull="git -C \"$dir\" pull --ff-only"
  emit "Shared context out of date: $name has no CONTEXT.md yet. Update it:
  $pull" \
    "The shared context repository $name is cloned at $dir but too old to have a CONTEXT.md, $unusable $pull"
fi

header="Shared context index of $name, loaded by a SessionStart hook from $index. Relative links in it resolve against $dir/. It is a separate repository: if a decision depends on it, check the checkout is current (git -C \"$dir\" pull --ff-only)."

# A copy of this hook that no longer matches the canonical one is out of date
# (or the canonical clone is): said once per session, with the tech-context link.
canonical=${base%/}/tech-context/scripts/load-shared-context.sh
if [ "$name" = tech-context ] && [ -f "$canonical" ] && ! cmp -s "$0" "$canonical"; then
  header="$header This repository's copy of the hook, $0, differs from the canonical $canonical: one of the two is out of date. Mention it to the user if they work on this repository's Claude Code setup."
fi

note="[Index truncated: $name/CONTEXT.md is over the inline limit. Read the whole of $index before relying on it.]"
# Room left for the index: the cap, minus the header, the note and the blank
# lines between them. Everything is counted in bytes (LC_ALL=C): a character
# never takes more UTF-16 code units, the unit Claude Code measures the cap
# in, than it takes UTF-8 bytes, so a byte count never undercounts.
bytes() { printf '%s' "$1" | wc -c | tr -d ' '; }
room=$((cap - $(bytes "$header") - $(bytes "$note") - 4))
size=$(wc -c < "$index" | tr -d ' ')
if [ "$size" -le "$room" ]; then
  emit '' "$header

$(cat "$index")"
fi

# Over the room: load whole lines up to it, and say where the rest is.
emit '' "$header

$(LC_ALL=C awk -v room="$room" '{ n += length($0) + 1; if (n > room) exit; print }' "$index")

$note"
