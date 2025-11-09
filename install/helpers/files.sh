#!/usr/bin/env bash
# File helpers for omarchy installer
# - safe atomic writes
# - append, prepend, insert after specific line or pattern
# - search for pattern in file
# - replace (simple)
# - backup before modifying
# Usage: source this file from scripts that need file helpers

# Create a backup of a file before modifying it
# Arguments: <path>
# Returns: path to backup file
file_backup() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    return 0
  fi
  local ts
n  ts=$(date +%Y%m%d%H%M%S)
  local bak="${file}.${ts}.bak"
  cp -- "$file" "$bak"
  echo "$bak"
}

# Atomic write: write content from stdin to a temp file then move into place
# Arguments: <path>
file_atomic_write() {
  local dest="$1"
  local tmp
  tmp="${dest}.tmp.$$"
  cat >"$tmp"
  mv -f -- "$tmp" "$dest"
}

# Append text to a file (creates file if missing)
# Arguments: <file> <text>
file_append() {
  local file="$1" text="$2"
  mkdir -p "$(dirname "$file")"
  printf "%s\n" "$text" >>"$file"
}

# Prepend text to a file (creates file if missing)
# Arguments: <file> <text>
file_prepend() {
  local file="$1" text="$2"
  mkdir -p "$(dirname "$file")"
  if [[ -f "$file" ]]; then
    local tmp
    tmp="${file}.prep.$$"
    printf "%s\n" "$text" >"$tmp"
    cat -- "$file" >>"$tmp"
    mv -f -- "$tmp" "$file"
  else
    printf "%s\n" "$text" >"$file"
  fi
}

# Insert text after the first line that matches a pattern
# Arguments: <file> <pattern> <text>
file_insert_after_line() {
  local file="$1" pattern="$2" text="$3"
  if [[ ! -f "$file" ]]; then
    echo "" >"$file"
  fi
  awk -v pat="$pattern" -v add="$text" 'BEGIN{added=0} {print} !added && $0 ~ pat {print add; added=1}' "$file" >"${file}.awk.$$" && mv -f -- "${file}.awk.$$" "$file"
}

# Insert text after the last character of the matched string on the first matching line
# Arguments: <file> <pattern> <text>
file_insert_after_match_end() {
  local file="$1" pattern="$2" text="$3"
  if [[ ! -f "$file" ]]; then
    echo "" >"$file"
  fi
  perl -0777 -pe 'if(!$ENV{_done} && /($ENV{PATTERN})/m){$ENV{_done}=1; s/($ENV{PATTERN})/$1.ENV{ADD}/s }' -- -e '' \
    PATTERN="$pattern" ADD="$text" "$file" >"${file}.perl.$$" && mv -f -- "${file}.perl.$$" "$file"
}

# Search for a pattern in a file. Returns 0 if found, 1 otherwise
# Arguments: <file> <pattern>
file_search() {
  local file="$1" pattern="$2"
  if [[ ! -f "$file" ]]; then
    return 1
  fi
  if grep -q -- "$pattern" "$file"; then
    return 0
  fi
  return 1
}

# Search for a pattern and return the line number of the first match (or -1 if not found)
# Arguments: <file> <pattern>
# Output: prints the line number or -1
file_search_line() {
  local file="$1" pattern="$2"
  if [[ ! -f "$file" ]]; then
    echo -1
    return 0
  fi
  local ln
  ln=$(grep -n -- "$pattern" "$file" | head -n1 | cut -d: -f1 || true)
  if [[ -z "$ln" ]]; then
    echo -1
  else
    echo "$ln"
  fi
}

# Simple replace: replace first occurrence of pattern with replacement
# Arguments: <file> <pattern> <replacement>
file_replace_first() {
  local file="$1" pattern="$2" replacement="$3"
  if [[ ! -f "$file" ]]; then
    return 1
  fi
  sed -e "0,/${pattern}/s//${replacement}/" -i -- "$file"
}

# Replace all occurrences of pattern with replacement
# Arguments: <file> <pattern> <replacement>
file_replace_all() {
  local file="$1" pattern="$2" replacement="$3"
  if [[ ! -f "$file" ]]; then
    return 1
  fi
  sed -i "s|${pattern}|${replacement}|g" -- "$file"
}

# Replace the last occurrence of pattern in the file with replacement
# Arguments: <file> <pattern> <replacement>
file_replace_last() {
  local file="$1" pattern="$2" replacement="$3"
  if [[ ! -f "$file" ]]; then
    return 1
  fi
  local ln
  ln=$(grep -n -- "$pattern" "$file" | tail -n1 | cut -d: -f1 || true)
  if [[ -z "$ln" ]]; then
    return 1
  fi
  # replace first occurrence on the found line (which corresponds to the last match in the file)
  sed -e "${ln}{s|${pattern}|${replacement}|}" -i -- "$file"
}

# Exported: list functions
file_helpers_list() {
  declare -F | awk '{print $3}' | grep -E '^file_'
}

