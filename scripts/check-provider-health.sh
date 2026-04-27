#!/usr/bin/env bash
# Provider-health alarm check.
#
# Called by orders/provider_outage.toml on a 2-minute cron. Exit 0 =
# alarm (fire loss_of_propulsion casualty); exit 1 = all providers
# healthy.
#
# Reads bluewater.provider.error events from the last 5 minutes. If
# any provider has an error rate above the configured threshold, that
# provider is unhealthy; alarm.
#
# Same telemetry-plumbing caveat as check-burn-rate.sh — the events
# this reads need to be emitted by either an OTEL bridge or the pack
# stub emitter. See docs/install.mdx "Telemetry plumbing".

set -euo pipefail

ERROR_RATE_THRESHOLD="${BLUEWATER_PROVIDER_ERROR_RATE:-0.5}"

# Pull recent error events.
events_json=$(gc events --type bluewater.provider.error --since 5m --json 2>/dev/null || echo '[]')

event_count=$(echo "$events_json" | jq 'length' 2>/dev/null || echo 0)
if [ "$event_count" -eq 0 ]; then
    exit 1
fi

# Group by provider name; if any provider has > threshold fraction of
# error events, alarm. Schema: payload.provider = "claude"|"codex"|...
unhealthy=$(echo "$events_json" | jq -r --arg t "$ERROR_RATE_THRESHOLD" '
    [.[].payload.provider]
    | group_by(.)
    | map({provider: .[0], count: length})
    | map(select(.count >= 5))
    | .[0].provider // empty
')

if [ -n "$unhealthy" ]; then
    echo "{\"unhealthy_provider\": \"$unhealthy\"}"
    exit 0
fi

exit 1
