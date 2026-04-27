#!/usr/bin/env bash
# Burn-rate alarm check.
#
# Called by orders/burn_rate_exceeded.toml on a 5-minute cron. Exit 0
# = alarm condition met (fire `flooding` casualty); exit 1 = healthy.
#
# Reads bluewater.burn_rate.minute events from the last hour and
# computes the fraction of the configured per-hour cap consumed. If
# the fraction is >= 0.95, alarm.
#
# **The events this script reads are not yet emitted natively by Gas
# City.** Two paths to make this real:
#
#   1. An OTEL bridge that translates Gas City's existing token-cost
#      telemetry into bluewater.burn_rate.minute events on the event
#      bus. Recommended for v0.2.
#   2. A pack-level emitter (scripts/emit-stub-telemetry.sh) that you
#      configure on a 1-minute cron to compute burn rate from
#      whatever signal is available in your environment. Suitable for
#      bring-up.
#
# By default this script returns "no alarm" when the events are
# absent, so the alarm chain is structurally correct but quiet until
# real signal flows. See docs/install.mdx "Telemetry plumbing" for
# the bring-up walkthrough.

set -euo pipefail

# Per-hour cap in tokens — override via env or via [bluewater.eng]
# in city.toml (the latter is canonical; this is a bring-up default).
PER_HOUR_CAP="${BLUEWATER_PER_HOUR_CAP:-10000000}"
ALARM_FRACTION="${BLUEWATER_ALARM_FRACTION:-0.95}"

# Pull the last hour of burn-rate events.
events_json=$(gc events --type bluewater.burn_rate.minute --since 1h --json 2>/dev/null || echo '[]')

# If no events, no alarm. (We don't crash on missing telemetry.)
event_count=$(echo "$events_json" | jq 'length' 2>/dev/null || echo 0)
if [ "$event_count" -eq 0 ]; then
    exit 1
fi

# Sum the per-minute token counts. Each event's payload is expected
# to contain `.tokens` (integer) — the tokens consumed in that
# minute. Schema is documented at scripts/emit-stub-telemetry.sh.
total_tokens=$(echo "$events_json" \
    | jq '[.[].payload.tokens // 0] | add' 2>/dev/null \
    || echo 0)

# Compute fraction; bash can't do floats, use awk.
fraction=$(awk -v t="$total_tokens" -v c="$PER_HOUR_CAP" \
    'BEGIN { printf "%.4f", t / c }')
threshold_breached=$(awk -v f="$fraction" -v a="$ALARM_FRACTION" \
    'BEGIN { print (f >= a) ? 1 : 0 }')

if [ "$threshold_breached" = "1" ]; then
    # Alarm: emit a structured payload the formula can read.
    echo "{\"fraction_of_per_hour_cap\": $fraction, \"total_tokens\": $total_tokens, \"cap\": $PER_HOUR_CAP}"
    exit 0
fi

exit 1
