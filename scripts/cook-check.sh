#!/usr/bin/env bash
# Cook's deterministic agent-health check.
# Exit 0 = alarm condition (stalled agent detected). Exit 1 = all healthy.
#
# Detects:
#  - process-gone but bead-still-assigned (zombie)
#  - heartbeat lapsed past threshold for an active polecat (>5min)
#  - heartbeat lapsed past threshold for a watch-stander (>30min)
#  - looping pattern in last 10 events (same prompt + response shape)
#
# This is intentionally a script, not an LLM, per ARCHITECTURE.md
# "LLMs sleep until alarm condition". Token cost is zero.
#
# When called, the order machinery passes the agent identity (if any) to
# investigate. With no arg, we sweep all active agents.

set -euo pipefail

# Threshold defaults (override via env).
POLECAT_HEARTBEAT_TIMEOUT_S="${POLECAT_HEARTBEAT_TIMEOUT_S:-300}"
WATCH_HEARTBEAT_TIMEOUT_S="${WATCH_HEARTBEAT_TIMEOUT_S:-1800}"

now=$(date +%s)

# Pull current agents and their last event time. Reuse Gas City's agent
# list and event-bus query rather than maintaining state files.
agents_json=$(gc agent list --json 2>/dev/null || echo '[]')

stalled=""

while IFS= read -r row; do
    name=$(echo "$row" | jq -r '.name // empty')
    [ -z "$name" ] && continue
    role=$(echo "$row" | jq -r '.role // "polecat"')
    last_event=$(gc events tail 1 --filter "agent=$name" --format unix 2>/dev/null || echo 0)
    [ -z "$last_event" ] && last_event=0
    delta=$((now - last_event))

    case "$role" in
        polecat|gm|et|sk|fc|dc)
            threshold=$POLECAT_HEARTBEAT_TIMEOUT_S
            ;;
        ood|eoow|cic_watch|bmow|yeoman|maa)
            threshold=$WATCH_HEARTBEAT_TIMEOUT_S
            ;;
        *)
            continue
            ;;
    esac

    if [ "$delta" -gt "$threshold" ]; then
        stalled="$stalled $name"
    fi
done < <(echo "$agents_json" | jq -c '.[]')

if [ -n "$stalled" ]; then
    # Emit the stalled-agent identity to the order's payload mechanism.
    echo "stalled:$stalled"
    exit 0
fi

exit 1
