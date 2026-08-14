#!/bin/sh
project=$(watson projects | dmenu -p "Start project:" -l 5)
[ -n "$project" ] && watson start "$project"
