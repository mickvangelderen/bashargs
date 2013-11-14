#!/bin/bash

# initialize global scope
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

for arg in "${simplified_arguments[@]}"; do
  # loop through all possible flags and check them
  # did only help for simplicity
  # reset this boolean
  match=false
  for flag in "${flags[@]}"; do
    # retrieve properties of current flag
    eval flag_long=\"\$${flag}_long\"
    eval flag_short=\"\$${flag}_short\"
    eval flag_scope=\"\$${flag}_scope\"
    if ([ -n "$flag_long" ] && [[ "${arg}" = "--$flag_long" ]]) ||
       ([ -n "$flag_short" ] && [[ "${arg}" = "-$flag_short" ]]); then
      match=true
      if [[ "$flag_scope" = "*" ]] || [ "$flag_scope" -gt 0 ]; then
        # the flag expects arguments, utilize scope
        scope_name="$flag"
        scope_count="$flag_scope"
        # do not reset value, allow app -f file1 -f file2
        if [[ ! -v $scope_name ]]; then
          # at least set the variable so that we know this flag occured even if no arguments followed
          eval $scope_name=\(\)
        fi
      else
        # this flag does not expect an argument
        eval $flag=\"true\"
      fi
      break
    fi
  done
  # if none of the possible flags matched, treat as an argument
  if [[ $match == false ]]; then
    if [[ ! "$scope_count" = "*" ]]; then
      if [ "$scope_count" -gt 0 ]; then
        scope_count=$(($scope_count - 1)) # decrement scope count, $scope_count is an integer from now on
      else
        scope_name="arguments" # back to global scope
        scope_count="*" # with infinite argument limit
      fi
    fi
    eval $scope_name=\(\"\${$scope_name[@]}\" \"$arg\"\) # append $arg
  fi
done

is_truthy() {
  [[ "$1" = "true" ]] ||
  [[ "$1" = "on" ]] ||
  [[ "$1" = "enabled" ]] ||
  [[ "$1" = "yes" ]] ||
  [[ "$1" = "1" ]]
}

print_parsed_argument_variables() {
  echo arguments = "${arguments[@]}"
  for flag in "${flags[@]}"; do
    eval echo \"\$flag\" = \"\${$flag[@]}\"
  done
  return 0
}

