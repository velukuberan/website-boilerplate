#!/bin/sh

if [ ! -f .env ]; then
	cp .env.example .env
	echo "Environment file created from .env.example"
else
	echo ".env file already exists. Skipping."
fi
