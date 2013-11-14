#!/bin/bash

# scope
# argc
# name
# long
# short

help_scope=1
help_long="help"
help_short="h"

scope_name="arguments"
scope_count="*"

# pre parse -xaf to -x -a -f, makes the rest easier
simplified_arguments=()
for arg in "$@"; do
  if [[ "$arg" =~ ^-[a-zA-Z]{2,}$ ]]; then
    arg="${arg:1}" # trim the dash
    while [ -n "$arg" ]; do
      simplified_arguments=("${simplified_arguments[@]}" "-${arg:0:1}")
      arg="${arg:1}" # trim the first character
    done
  else
    simplified_arguments=("${simplified_arguments[@]}" "${arg}")
  fi
done

for i in "${simplified_arguments[@]}"; do
  echo processing:
  echo -e \\targument: "$i"
  echo -e \\tscope_name: "$scope_name"
  echo -e \\tscope_count: "$scope_count"
  # loop through all possible flags and check them
  # did only help for simplicity
  # reset this boolean
  match=false
  if [[ ${i#--} = $help_long ]] ||
     [[ ${i#-} = $help_short ]]; then
    match=true
    if [[ $help_scope = "*" ]] || [ $help_scope -gt 0 ]; then
      scope_name="help"
      scope_count=$help_scope
    fi
  fi
  # if none of the possible flags matched, treat as an argument
  if [[ $match == false ]]; then
    if [[ ! $scope_count = "*" ]]; then
      if [ $scope_count -gt 0 ]; then
        scope_count=$(($scope_count - 1)) # decrement scope count
      else
        scope_name=arguments # back to global scope
        scope_count="*" # with infinite argument limit
      fi
    fi
    eval $scope_name=\(\"\${$scope_name[@]}\" \"$i\"\) # append $i
  fi
done

is_truthy() {
  [[ "$1" = "true" ]] ||
  [[ "$1" = "on" ]] ||
  [[ "$1" = "enabled" ]] ||
  [[ "$1" = "yes" ]] ||
  [[ "$1" = "1" ]]
}

echo "arguments = \"${arguments[@]}\""
echo "help = \"${help[@]}\""

exit 0
