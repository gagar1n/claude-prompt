#!/usr/bin/env bash
# Claude Code status line: model · effort · 5h limit · 7d limit · context

set -u
input=$(cat)

# Colors (disabled when NO_COLOR is set, per https://no-color.org/)
if [[ -z "${NO_COLOR:-}" ]]; then
  R=$'\033[0m'; B=$'\033[1m'; D=$'\033[2m'
  RED=$'\033[31m'; GRN=$'\033[32m'; YLW=$'\033[33m'
  CYN=$'\033[36m'; MAG=$'\033[35m'; GREY=$'\033[90m'
else
  R= B= D= RED= GRN= YLW= CYN= MAG= GREY=
fi

color_pct() {
  local pct=$1
  if   (( pct >= 80 )); then echo "$RED"
  elif (( pct >= 50 )); then echo "$YLW"
  else                       echo "$GRN"
  fi
}

color_effort() {
  case "$1" in
    low)            echo "$GRN" ;;
    medium)         echo "$YLW" ;;
    high|xhigh|max) echo "$MAG" ;;
    *)              echo "$D" ;;
  esac
}

fmt_eta() {
  local target=$1
  [[ -z "$target" || "$target" == "null" || "$target" == "-" ]] && { echo ""; return; }
  local now remaining d h m
  now=$(date +%s)
  remaining=$(( target - now ))
  (( remaining <= 0 )) && { echo "now"; return; }
  d=$(( remaining / 86400 ))
  h=$(( (remaining % 86400) / 3600 ))
  m=$(( (remaining % 3600) / 60 ))
  if (( d > 0 )); then printf '%dd%dh' "$d" "$h"
  elif (( h > 0 )); then printf '%dh%dm' "$h" "$m"
  else printf '%dm' "$m"
  fi
}

IFS=$'\t' read -r model effort ctx_pct h5_pct h5_reset d7_pct d7_reset < <(
  echo "$input" | jq -r '
    [
      (.model.display_name // "?"),
      (.effort.level // "-"),
      (.context_window.used_percentage // 0 | floor | tostring),
      (.rate_limits.five_hour.used_percentage // "-" | if type == "number" then floor | tostring else . end),
      (.rate_limits.five_hour.resets_at // "-" | tostring),
      (.rate_limits.seven_day.used_percentage // "-" | if type == "number" then floor | tostring else . end),
      (.rate_limits.seven_day.resets_at // "-" | tostring)
    ] | @tsv
  '
)

parts=()
parts+=("${B}${CYN}${model}${R}")

ec=$(color_effort "$effort")
parts+=("${D}effort:${R}${ec}${effort}${R}")

if [[ "$h5_pct" != "-" ]]; then
  c=$(color_pct "$h5_pct")
  eta=$(fmt_eta "$h5_reset")
  parts+=("${D}5h:${R}${c}${h5_pct}%${R}${eta:+ ${D}(${eta})${R}}")
fi

if [[ "$d7_pct" != "-" ]]; then
  c=$(color_pct "$d7_pct")
  eta=$(fmt_eta "$d7_reset")
  parts+=("${D}7d:${R}${c}${d7_pct}%${R}${eta:+ ${D}(${eta})${R}}")
fi

cc=$(color_pct "$ctx_pct")
parts+=("${D}ctx:${R}${cc}${ctx_pct}%${R}")

sep="${GREY} · ${R}"
out="${parts[0]}"
for ((i=1; i<${#parts[@]}; i++)); do out+="${sep}${parts[i]}"; done
echo "$out"
