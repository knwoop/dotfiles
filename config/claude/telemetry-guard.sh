#!/usr/bin/env bash
# SessionStart hook: warn when a session outside kauche-app could send
# telemetry to kauche's project. kauche-app's own hook keeps its telemetry env
# in the user settings, so it applies in every repository; two things keep it
# from leaving elsewhere, and this checks both:
#   - no otelHeadersHelper in the user settings: without one, exports go
#     unauthenticated and are rejected;
#   - the claude wrapper (config/scripts/wrap/claude) closing the endpoints,
#     which a claude started some other way (an IDE, a full path) skips.
# Prints nothing when all is well, and never blocks the session.

trap 'exit 0' EXIT
cwd="$(jq -r '.cwd // empty' 2>/dev/null)"
[ -n "$cwd" ] || cwd="$PWD"

case "$(git -C "$cwd" config --get remote.origin.url 2>/dev/null)" in
*[:/]x-asia/kauche-app | *[:/]x-asia/kauche-app.git) exit 0 ;;
esac
[ "${CLAUDE_CODE_ENABLE_TELEMETRY:-}" = 1 ] || exit 0

problems=()
if jq -e '.otelHeadersHelper // empty' "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json" >/dev/null 2>&1; then
    problems+=("the user settings have an otelHeadersHelper, so exports can authenticate")
fi
if [ -z "${CLAUDE_TELEMETRY_GUARD:-}" ]; then
    problems+=("claude was started without the wrapper, so the endpoints are not closed")
fi
[ "${#problems[@]}" -gt 0 ] || exit 0

message="Telemetry guard: this session is outside kauche-app but may send telemetry to kauche's project: $(
    IFS=';'
    printf '%s' "${problems[*]}" | sed 's/;/; /g'
)."
jq -n --arg m "$message" '{systemMessage: $m}'
