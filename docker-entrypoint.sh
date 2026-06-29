#!/bin/bash
set -e

echo "Launching AI Video Pipeline …"
exec python main.py "$@"
