#!/bin/bash
set -e

# ── Start Ollama ──────────────────────────────────────────────────────────────
echo "Starting Ollama …"
mkdir -p /root/.ollama
ollama serve &
OLLAMA_PID=$!

# Wait for Ollama to accept connections (GET / returns "Ollama is running").
# /api/tags can return 500 on a fresh empty volume, so we avoid it here.
WAIT=0
until curl -sf http://localhost:11434/ > /dev/null 2>&1; do
    sleep 1
    WAIT=$((WAIT + 1))
    if [ "$WAIT" -ge 60 ]; then
        echo "ERROR: Ollama did not become ready within 60 seconds." >&2
        kill "$OLLAMA_PID" 2>/dev/null || true
        exit 1
    fi
done
echo "Ollama ready."

# ── Pull model ────────────────────────────────────────────────────────────────
MODEL="${OLLAMA_MODEL:-llama3.2:3b}"
echo "Pulling model: $MODEL"
ollama pull "$MODEL" || echo "Warning: could not pull $MODEL (may already be cached)"

# ── Launch app ────────────────────────────────────────────────────────────────
echo "Launching AI Video Pipeline …"
exec python main.py "$@"
