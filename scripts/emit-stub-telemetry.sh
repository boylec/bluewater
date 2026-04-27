#!/usr/bin/env bash
# Stub telemetry emitter — bridges Gas City's native telemetry into
# the bluewater.* event types the alarm-check scripts read.
#
# This is a bring-up tool. It runs on a 1-minute cron and emits the
# three event types the check scripts consume:
#   - bluewater.burn_rate.minute  (payload: {tokens: int})
#   - bluewater.provider.error    (payload: {provider: string, kind: string})
#   - bluewater.provider.credit_balance (payload: {provider: string, fraction_of_per_day_cap: float})
#
# The default behavior is **no-op** — emit nothing. This makes the
# alarm chain structurally correct but quiet until real telemetry
# flows. To wire real signal:
#
#  1. Replace the no-op blocks below with calls into your real
#     telemetry source (Gas City OTEL trace files, billing API,
#     provider health-check endpoints, etc.).
#  2. Use `gc event emit <type> --payload '<json>'` to publish the
#     event; the check scripts will pick it up on next run.
#
# Schema for each event payload is documented above each emit block.

set -euo pipefail

now_unix=$(date +%s)

# ---------------------------------------------------------------
# bluewater.burn_rate.minute
# Payload: {tokens: int} — total tokens consumed in the last minute
# across all agents.
# ---------------------------------------------------------------
# Replace this block to compute real burn rate and emit:
#
# tokens=$(your-burn-rate-computation-here)
# gc event emit bluewater.burn_rate.minute \
#   --payload "{\"tokens\": $tokens, \"ts\": $now_unix}"

# ---------------------------------------------------------------
# bluewater.provider.error
# Payload: {provider: string, kind: string}
# Emit one event per provider error in the last minute.
# ---------------------------------------------------------------
# for provider in claude codex gemini; do
#     errors=$(your-error-count-for-this-provider)
#     for ((i=0; i<errors; i++)); do
#         gc event emit bluewater.provider.error \
#           --payload "{\"provider\": \"$provider\", \"kind\": \"timeout\", \"ts\": $now_unix}"
#     done
# done

# ---------------------------------------------------------------
# bluewater.provider.credit_balance
# Payload: {provider: string, fraction_of_per_day_cap: float}
# Emit once per provider per minute.
# ---------------------------------------------------------------
# for provider in claude codex gemini; do
#     fraction=$(your-credit-balance-call --provider "$provider")
#     gc event emit bluewater.provider.credit_balance \
#       --payload "{\"provider\": \"$provider\", \"fraction_of_per_day_cap\": $fraction, \"ts\": $now_unix}"
# done

exit 0
