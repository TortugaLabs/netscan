#!/bin/sh
#
# Used by logrotate to reload processes
#
while [ $# -gt 0 ]
do
  case "$1" in
  --quiet) exec >/dev/null 2>&1 ;;
  *) break ;;
  esac
  shift
done

supervisorctl "$2" "$1"
