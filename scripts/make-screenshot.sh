#!/bin/bash
set -e

IMAGE_NAME="${IMAGE_NAME:-coder-dev}"
CONTAINER_NAME="${CONTAINER_NAME:-coder-dev}"
PORT="${PORT:-8080}"
TARGET_URL="${TARGET_URL:-http://localhost:8080/}"
OUTPUT_PATH="${OUTPUT_PATH:-screenshots/desktop.png}"
WAIT_SECONDS="${WAIT_SECONDS:-30}"

# Build the image if it does not exist yet.
if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
  DOCKER_BUILDKIT=1 docker build -t "$IMAGE_NAME" .
fi

# Remove any existing container with the same name.
docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true

# Start the web RDP container.
docker run --rm -d \
  -p "$PORT":8080 \
  -v "$(pwd)":/home/developer/workspace \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$HOME/.claude":/home/developer/.claude \
  -v "$HOME/.config/opencode":/home/developer/.config/opencode \
  -v "$HOME/.config/codex":/home/developer/.config/codex \
  --name "$CONTAINER_NAME" \
  "$IMAGE_NAME"

# Stop the container when the script exits.
cleanup() {
  docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
}
trap cleanup EXIT

# Wait for the web desktop to respond.
for _ in $(seq 1 "$WAIT_SECONDS"); do
  if curl -fsS "$TARGET_URL" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

# Fail fast if the web desktop is not reachable.
if ! curl -fsS "$TARGET_URL" >/dev/null 2>&1; then
  echo "Timed out waiting for $TARGET_URL" >&2
  exit 1
fi

# Ensure the output directory exists.
mkdir -p "$(dirname "$OUTPUT_PATH")"

# Install Playwright's Chromium browser.
npx -y playwright@latest install chromium

# Capture the screenshot after the page has loaded.
npx -y playwright@latest screenshot --wait-for-timeout 10000 "$TARGET_URL" "$OUTPUT_PATH"
