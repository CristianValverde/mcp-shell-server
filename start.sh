#!/bin/bash
# start.sh — Starts your app and the MCP Shell Server in parallel.
# Adapt the "your app" section to match your project's main process.
set -e

echo "[start.sh] Starting MCP Shell Server on port 8765..."
python /app/mcp_server.py &
MCP_PID=$!

echo "[start.sh] Starting your app..."
# ── Replace the lines below with your app's start command ──────────────────
# Example: Jupyter Lab
jupyter lab \
    --ip=0.0.0.0 \
    --port=8888 \
    --no-browser \
    --allow-root \
    --ServerApp.token= \
    --ServerApp.password= \
    --ServerApp.disable_check_xsrf=True &
# Example: a plain Python service
# python /app/main.py &
# ───────────────────────────────────────────────────────────────────────────
APP_PID=$!

echo "[start.sh] Both services running. MCP PID=$MCP_PID | App PID=$APP_PID"

# If either process dies, shut down the other
wait -n $MCP_PID $APP_PID
echo "[start.sh] A process exited. Shutting down both..."
kill $MCP_PID $APP_PID 2>/dev/null || true
