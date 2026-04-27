#!/usr/bin/env bash
# Provider-credit alarm check.
#
# Called by orders/provider_credit_low.toml on a 10-minute cron. Exit
# 0 = alarm (fire replenish_credits evolution); exit 1 = all providers
# have headroom.
#
# Reads bluewater.provider.credit_balance events. If any provider has
# crossed 80% of its per-day cap, alarm.
#
# Same telemetry-plumbing caveat as the other check scripts. See
# docs/install.mdx "Telemetry plumbing".

set -euo pipefail

CAP_FRACTION="${BLUEWATER_CREDIT_CAP_FRACTION:-0.80}"

# Pull most recent credit-balance event per provider.
events_json=$(gc events --type bluewater.provider.credit_balance --since 1h --json 2>/dev/null || echo '[]')

event_count=$(echo "$events_json" | jq 'length' 2>/dev/null || echo 0)
if [ "$event_count" -eq 0 ]; then
    exit 1
fi

# Find any provider where fraction_of_per_day_cap > threshold.
exhausted=$(echo "$events_json" | jq -r --argjson t "$CAP_FRACTION" '
    .[].payload
    | select((.fraction_of_per_day_cap // 0) > $t)
    | .provider
' | head -1)

if [ -n "$exhausted" ]; then
    echo "{\"exhausted_provider\": \"$exhausted\"}"
    exit 0
fi

exit 1
