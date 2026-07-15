#!/usr/bin/env bash
# verify/verify.sh — CertiCoach verification harness. Run from repo root.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 2
fail=0
pass(){ printf '  PASS  %s\n' "$1"; }
bad(){ printf '  FAIL  %s\n' "$1"; fail=1; }

echo "== required files exist and are non-empty =="
while IFS= read -r f; do
  [ -z "$f" ] && continue; case "$f" in \#*) continue;; esac
  if [ -s "$f" ]; then pass "$f"; else bad "missing/empty: $f"; fi
done < verify/required-files.txt

echo "== required sections present =="
while IFS=$'\t' read -r file heading; do
  [ -z "${file:-}" ] && continue; case "$file" in \#*) continue;; esac
  if [ -f "$file" ] && grep -qF "$heading" "$file"; then pass "$file :: $heading";
  else bad "missing section in $file: $heading"; fi
done < verify/required-sections.tsv

echo "== forbidden patterns absent (repo-wide, excluding .git and verify/) =="
while IFS=$'\t' read -r pat reason; do
  [ -z "${pat:-}" ] && continue; case "$pat" in \#*) continue;; esac
  if grep -rIl --exclude-dir=.git --exclude-dir=verify --exclude-dir=docs --exclude-dir=.claude --exclude-dir=.superpowers -- "$pat" . >/dev/null 2>&1; then
    bad "found forbidden pattern '$pat' ($reason)";
  else pass "absent: $pat"; fi
done < verify/forbidden-patterns.tsv

echo "== forbidden encoded patterns absent (literal never stored; scans whole repo) =="
_b64d(){ base64 -d 2>/dev/null <<<"$1" || base64 -D 2>/dev/null <<<"$1"; }
while IFS= read -r enc; do
  [ -z "${enc:-}" ] && continue; case "$enc" in \#*) continue;; esac
  dec="$(_b64d "$enc")"
  if grep -rIl --exclude-dir=.git --exclude-dir=.claude --exclude-dir=.superpowers -- "$dec" . >/dev/null 2>&1; then
    bad "found forbidden (encoded) pattern";
  else pass "absent (encoded): $enc"; fi
done < verify/forbidden-encoded.txt

echo "== cross-references resolve to real files =="
while IFS=$'\t' read -r src token; do
  [ -z "${src:-}" ] && continue; case "$src" in \#*) continue;; esac
  if find references -type f -name "*${token}*" | grep -q .; then pass "$src -> $token";
  else bad "$src references missing file token: $token"; fi
done < verify/crossref.tsv

echo "== spec coverage: every mapped requirement has an implementing file =="
while IFS=$'\t' read -r sid impl label; do
  [ -z "${sid:-}" ] && continue; case "$sid" in \#*) continue;; esac
  if [ -s "$impl" ]; then pass "$sid ($label) -> $impl";
  else bad "$sid ($label) not implemented: $impl"; fi
done < verify/spec-coverage.tsv

echo; if [ "$fail" -eq 0 ]; then echo "ALL CHECKS PASSED"; else echo "CHECKS FAILED"; fi
exit "$fail"
