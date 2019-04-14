#!/bin/bash
# Update all the segment file names
for f in *oldValue; do mv "$f" "$(echo "$f" | sed s/oldValue/escapeMe\//)"; done
# Update all the manifests
find . -name "*.m3u8" -exec sed -i "s/oldValue/escapeMe\//g" '{}' \;
