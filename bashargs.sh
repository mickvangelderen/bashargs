#!/bin/bash

# -----
# config
# 
# The config section contains default values for necessary variables. These can be changed simply by overwriting 
# them in your implementation before calling any of the bashargs functions. 
#
# bashargs_simplify: boolean - runs bashargs_simplify before parsing arguments
bashargs_simplify=true
# bashargs_unbound_var: identifier - decides the name of the variable in which arguments with no space will be put
bashargs_unbound_var="arguments"
#
# end of config
# -----

# print all defined basharg global variables
bashargs_debug() {
	echo "# bashargs global variables"
	# collect all variables containing bashargs
	for x in $(compgen -A variable | grep bashargs); do
		# print the value taking arrays in account
		eval echo "$x = \${$x[@]}"
	done

	echo "# parsing results"
	# print the global and user defined spaces
	eval echo "$bashargs_unbound_var = \${$bashargs_unbound_var[@]}"
	for name in "${bashargs_options[@]}"; do
		eval local varname=\"\$bashargs_data_${name}_var\"
		eval echo "$varname = \${$varname[@]}"
	done
}

# print an error message with stack trace and exit
bashargs_error() {
	# print error message
	echo "bashargs error: $@"
	# print basic stack trace
	echo "stack trace:"
	local frame=0
	while caller $frame; do ((frame++)); done
	exit 1
}

# A bashargs option consists of a name, description, argument type, variable name and one or more signals. Every option expecting one or more arguments uses its own 'space'. Arguments supplied while in this space that are not signals will be inserted into the current space. The initial space is called the unbound space because its not tied to any of the options. 
# name - Supplied as the first parameter, must be an identifier because it is used for saving the properties of this option. 
# description - For a generated help section. 
# arguments - Either, "none", "single", "multiple" or an exact number. The arguments are a maximum, none single and multiple are resp. 0, 1 and infinity. 
# var - The name that will be used to store the arguments that were recieved in the space of this option. So values can be retrieved with $the_name if you pas --var "the_name". 
# signals - One or more flags that designate either the presence of an option (in case --arguments "none") or the start of this options space. The space will revert to the global unbound space after the maximum number of arguments have passed. 
# Example:
# bashargs_option "help" \
# 	--description "displays help" \
# 	--arguments "single" \
# 	--var "opt_help" \
# 	--signals "--help" "--help-me" "-h" "?"
bashargs_option() {
	if [[ ! "$1" =~ ^[a-zA-Z_][a-zA-Z_0-9]*$ ]]; then
		bashargs_error "invalid option name ($1), must be an identifier"
	fi
	
	local name="$1"; shift

	if [[ ! "--description" = "$1" ]]; then
		bashargs_error "expected --description for bashargs_option $name"
	fi

	local description="$2"; shift 2

	if [[ ! "--arguments" = "$1" ]]; then
		bashargs_error "expected --arguments after --description for bashargs_option $name"
	fi

	local arguments="$2"; shift 2
	
	if [[ "$arguments" = "none" ]]; then arguments="0"
	elif [[ "$arguments" = "single" ]]; then arguments="1"
	elif [[ "$arguments" =~ ^[0-9]+$ ]] || 
		[[ "$arguments" = "multiple" ]]; then arguments="$arguments"
	else
		bashargs_error "invalid --arguments value ($arguments) for bashargs_option $name"
	fi

	if [[ ! "--var" = "$1" ]]; then
		bashargs_error "expected --var after --arguments for bashargs_option $name"
	fi

	local varname="$2"; shift 2

	if [[ ! "$varname" =~ ^[a-zA-Z_][a-zA-Z_0-9]*$ ]]; then
		bashargs_error "invalid variable name ($varname) for bashargs_option $name"
	fi

	if [[ ! "--signals" = "$1" ]]; then
		bashargs_error "expected --signals after --var for bashargs_option $name"
	fi

	shift

	local signals=()
	while (( $# )); do
		signals=("${signals[@]}" "$1")
		shift
	done

	# export locals to long-named globals
	eval bashargs_data_${name}_description=\"$description\"
	eval bashargs_data_${name}_arguments=\"$arguments\"
	eval bashargs_data_${name}_var=\"$varname\"
	eval bashargs_data_${name}_signals=\(\"\${signals[@]}\"\)

	# register option
	bashargs_options=("${bashargs_options[@]}" "$name")
}

# pre parse -xaf to -x -a -f, makes the rest easier
bashargs_simplify() {
	local simplified # array containing simplified arguments

	for arg in "$@"; do
		# if the word is a dash with multiple letters after it
		if [[ "$arg" =~ ^-[a-zA-Z]{2,}$ ]]; then
			arg="${arg:1}" # trim the dash
			while [ -n "$arg" ]; do # while arg is not empty
				# add a new argument consisting of a dash and the first character in arg
				simplified=("${simplified[@]}" "-${arg:0:1}")
				arg="${arg:1}" # trim the first character
			done
		else
			# the word is not a dash with multiple letters, transfer it to the simplified
			# arguments without modification
			simplified=("${simplified[@]}" "${arg}")
		fi
	done

	bashargs_arguments=("${simplified[@]}")	# export the simplified arguments

	return 0
}

# reset space to global, private
_bashargs_reset_space() {
	bashargs_count="multiple"
	bashargs_var="$bashargs_unbound_var"
}; _bashargs_reset_space

# Parse the passed array. The results are placed for each option in variables named through the --var option for 
# bashargs_option. Overwrites bashargs_arguments depending on simplify setting. 
bashargs_parse() {
	if $bashargs_simplify; then
		# sets bashargs_arguments
		bashargs_simplify "$@"
	else
		bashargs_arguments=("$@")
	fi

	for arg in "${bashargs_arguments[@]}"; do
		local _match=false
		for name in "${bashargs_options[@]}"; do # loop through all possible options and check them
			# retrieve properties of current option
			eval local _arguments=\"\$bashargs_data_${name}_arguments\"
			eval local _varname=\"\$bashargs_data_${name}_var\"
			eval local _signals=\(\"\${bashargs_data_${name}_signals[@]}\"\)
			for signal in "${_signals[@]}"; do
				if [[ "$arg" = "$signal" ]]; then
					_match=true
					break
				fi
			done
			if $_match ; then
				if [[ "$_arguments" = "multiple" ]] || [ "$_arguments" -gt 0 ]; then
					# the flag expects arguments, utilize space
					bashargs_space="$name"
					bashargs_count="$_arguments"
					bashargs_var="$_varname"
					# check if the variable that varname designates is already defined
					if [[ ! -v "$_varname" ]]; then
						# set the variable to an empty array so that we know this flag occured even if no arguments followed
						eval $_varname=\(\)
					fi
				else
					# this flag does not expect an argument, set it to the string "true"
					eval $_varname=true
				fi
				break
			fi
		done
		# if none of the possible signals matched, treat as an argument
		if ! $_match; then
			# if the current signal space does not request infinite arguments
			if [[ ! "$bashargs_count" = "multiple" ]]; then
				# check if there are arguments left to be passed to the active option
				if [ "$bashargs_count" -gt 0 ]; then
					((bashargs_count--)) # decrement scope count
				else
					_bashargs_reset_space # reset space to global
				fi
			fi
			# actually add the argument current space
			eval $bashargs_var=\(\"\${$bashargs_var[@]}\" \"$arg\"\) # append $arg
		fi
	done
	return 0
}

# utility function for you
# case insensitive match for true, on, enabled, yes, y or 1. 
bashargs_is_truthy() {
	[[ "$1" =~ ^\ *([tT][rR][uU][eE]|[oO][nN]|[eE][nN][aA][bB][lL][eE][dD]|[yY](|[eE][sS])|1)\ *$ ]]
}

bashargs_is_set() {
	[[ -v "$1" ]]
}

bashargs_is_enabled() {
	( bashargs_is_set "$1" && [[ -z "\$$1" ]] ) || bashargs_is_truthy "\$$1"
}

bashargs_is_empty() {
	eval [[ \${#$1[@]} -eq 0 ]]
}

bashargs_is_single() {
	eval [[ \${#$1[@]} -eq 1 ]]
}

bashargs_is_multiple() {
	eval [[ \${#$1[@]} -gt 1 ]]
}