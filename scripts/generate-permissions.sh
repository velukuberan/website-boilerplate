#!/bin/sh

# Set permissions for the web directory
if [ -d "web" ]; then
	chmod 0755 web
	echo "Permissions set for web directory"
else
	echo "Directory 'web' does not exist. Skipping permission setting."
fi
