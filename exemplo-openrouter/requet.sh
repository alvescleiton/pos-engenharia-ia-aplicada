#!/usr/bin/env sh
set -eu

if [ -f .env ]; then
    . ./.env
fi

API_URL="${API_URL:-https://openrouter.ai/api/v1/chat/completions}"
OPENROUTER_SITE_URL="${OPENROUTER_SITE_URL:-https://localhost:3000}"
OPENROUTER_SITE_NAME="${OPENROUTER_SITE_NAME:-My Example}"
NLP_MODEL="${NLP_MODEL:-meta-llama/llama-3.3-70b-instruct:free}"
NLP_FALLBACK_MODEL="${NLP_FALLBACK_MODEL:-}"
MAX_RETRIES="${MAX_RETRIES:-3}"

if [ -z "${OPENROUTER_API_KEY:-}" ]; then
    echo "OPENROUTER_API_KEY is missing. Define it in .env or environment variables." >&2
    exit 1
fi

request_model() {
    model="$1"

    payload=$(cat <<EOF
{
    "model": "$model",
    "messages": [
        {
            "role": "user",
            "content": "Me conte uma curiosidade sobre LLM"
        }
    ],
    "temperature": 0.3,
    "max_tokens": 1000
}
EOF
)

    body_file=$(mktemp)
    http_code=$(curl --silent -X POST "$API_URL" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENROUTER_API_KEY" \
        -H "HTTP-Referer: $OPENROUTER_SITE_URL" \
        -H "X-Title: $OPENROUTER_SITE_NAME" \
        -d "$payload" \
        -o "$body_file" \
        -w "%{http_code}" || true)

    body=$(cat "$body_file")
    rm -f "$body_file"

    if [ "$http_code" = "200" ]; then
        echo "$body"
        return 0
    fi

    echo "Request failed for model '$model' (HTTP $http_code): $body" >&2

    if [ "$http_code" = "429" ]; then
        return 29
    fi

    return 1
}

attempt_with_retry() {
    model="$1"
    attempt=1

    while [ "$attempt" -le "$MAX_RETRIES" ]; do
        if request_model "$model"; then
            return 0
        fi
        status=$?

        if [ "$status" -eq 29 ] && [ "$attempt" -lt "$MAX_RETRIES" ]; then
            wait_seconds=$((attempt * 2))
            echo "Rate limited on '$model'. Retrying in ${wait_seconds}s..." >&2
            sleep "$wait_seconds"
            attempt=$((attempt + 1))
            continue
        fi

        return 1
    done

    return 1
}

if attempt_with_retry "$NLP_MODEL"; then
    exit 0
fi

if [ -n "$NLP_FALLBACK_MODEL" ] && [ "$NLP_FALLBACK_MODEL" != "$NLP_MODEL" ]; then
    echo "Trying fallback model: $NLP_FALLBACK_MODEL" >&2
    if attempt_with_retry "$NLP_FALLBACK_MODEL"; then
        exit 0
    fi
fi

echo "All attempts failed. If this is a free-model rate limit, retry later or use BYOK at https://openrouter.ai/settings/integrations" >&2
exit 1
