source "bashargs.sh"

bashargs_option "help" \
  --description "Displays the help" \
  --arguments "single" \
  --var "display_help" \
  --signals "--help" "--help-me" "-h" "?"

bashargs_option "silent" \
  --description "Makes you cry blood" \
  --arguments "none" \
  --var "be_silent" \
  --signals "--silent" "-s"

bashargs_parse "$@"

if bashargs_is_multiple "display_help"; then
	echo "We do not support multiple help items"
elif bashargs_is_single "display_help"; then
	echo "Displaying help for item ${display_help}"
elif bashargs_is_set "display_help"; then
	echo "Displaying general help info"
fi
