#!/bin/zsh

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title vibe
# @raycast.mode silent
# @raycast.argument1 { "type": "text", "placeholder": "最初の指示を入力" }

# Optional parameters:
# @raycast.icon 🚀
# @raycast.packageName Dev

ruby ~/bin/newproj.rb "$1"