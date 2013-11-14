#!/bin/bash

is_truthy() {
  [[ "$1" = "true" ]] ||
  [[ "$1" = "on" ]] ||
  [[ "$1" = "enabled" ]] ||
  [[ "$1" = "yes" ]] ||
  [[ "$1" = "1" ]]
}

is_truthy $@
exit $?
