#!/bin/bash
set -e

TEMPLATE="scripts/templates/wp-config.php.stub"
DEST="web/wp-config.php"

if [ -f "$DEST" ]; then
	echo "🟡 wp-config.php already exists. Skipping."
	exit 0
fi

cp "$TEMPLATE" "$DEST"
echo "✅ wp-config.php generated at $DEST"
