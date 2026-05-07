#!/usr/bin/env bash
# Claude Code status line: model · effort · 5h limit · 7d limit · context

set -u
input=$(cat)

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

parts=("$model" "effort:$effort")

if [[ "$h5_pct" != "-" ]]; then
  eta=$(fmt_eta "$h5_reset")
  parts+=("5h:${h5_pct}%${eta:+ (${eta})}")
fi

if [[ "$d7_pct" != "-" ]]; then
  eta=$(fmt_eta "$d7_reset")
  parts+=("7d:${d7_pct}%${eta:+ (${eta})}")
fi

parts+=("ctx:${ctx_pct}%")

sep=" · "
out="${parts[0]}"
for ((i=1; i<${#parts[@]}; i++)); do out+="${sep}${parts[i]}"; done
echo "$out"
