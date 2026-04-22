#!/bin/sh
# Configure git to use the project's shared hooks in .githooks/.
# Run once after cloning: sh tool/setup_hooks.sh
set -e
git config core.hooksPath .githooks
echo "Git hooks configured to use .githooks/"
