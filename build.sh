#!/usr/bin/env bash
# build.sh — build the shared Docker image used by all acts
#
# Run this once before running any act. The image is cached by Docker;
# subsequent builds are instant unless the Dockerfile changes.
#
# Usage: bash build.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

build_image && echo "" && echo "Image '${DEMO_IMAGE}' is ready. You can now run any act."
