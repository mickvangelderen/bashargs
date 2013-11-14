#!/bin/bash

display_version_scope="0"
display_version_long="version"
display_version_short="v"

display_help_scope="1"
display_help_long="help"
display_help_short="h"

do_echo_scope="*"
do_echo_long="echo"
do_echo_short="e"

do_cat_scope="*"
do_cat_long="cat"

flags=("display_version" "display_help" "do_echo" "do_cat")

# Does all the argument parsing based on the above statements
source "bashargs.sh"

# For demonstration
print_parsed_argument_variables

if [ ${#arguments[@]} -gt 0 ]; then
  echo Meh I\'m not going to do anything with these arguments: "${arguments[@]}"
fi

if [ $display_version ]; then
  echo version 1.0.0
fi

if [[ -v display_help ]]; then 
  if [[ ${#display_help[@]} -gt 1 ]]; then
    echo I do not support multiple help items
  elif [[ ${#display_help[@]} -eq 1 ]]; then
    echo I cannot share the details of item "$display_help" with you
  else
    echo Help requested!
  fi
fi

echo ${do_echo[@]}

for item in "${do_echo[@]}"; do
  echo -e "$item"
done

for item in "${do_cat[@]}"; do
  cat "$item"
done

exit 0
