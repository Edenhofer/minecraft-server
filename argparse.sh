#!/bin/bash

# shell script library to parse and validate command line arguments, and generate the --help text.

set -u

re_subcmd_vn='^[a-z0-9]+:[A-Za-z0-9_]+$'
COMMAND=

declare -A args args_help subcmds

add_arg() {
	local short="$1"
	local long="$2"
	local varname="$3"
	local help="$4"
	local required="${5:-false}"
    [ -v 6 ] && local default="$6"
	if [[ "$varname" =~ $re_subcmd_vn ]]; then
		local subc _vn
		IFS=":" read subc _vn <<< "$varname"
		[[ -n "${subcmds[$subc]}" ]]
	fi
	args[$varname]="$short $long $required"
	args_help[$varname]="$help"
	# init the global
	[[ -v default ]] && declare -g ${varname#*:}="${default}"
}

add_subcommand() {
	local subc="$1"
	local help="$2"

	subcmds[$subc]="$help"
}

usage() {
	# help function. generates usage instructions
	local short long required help
	local n_subcmds=${#subcmds[@]}
	local ofd=1
	[[ -v 1 ]] && ofd=2
	local cols=80
	[[ -t $ofd ]] && cols=$(tput cols)
	(
		if [[ -v 1 ]]; then
			echo "ERROR: $1"
			echo ""
		fi
		if [[ -v DESCRIPTION ]]; then
			echo -e "$DESCRIPTION"
			echo ""
		fi
		if [[ $n_subcmds < 1 ]]; then
			echo "Usage: $0 [options]"
			echo ""
			echo "Valid options are:"
		else
			echo "Usage: $0 [global options] COMMAND [command-specific options]"
			echo ""
			echo "Global options:"
		fi
		for varname in ${!args[@]}; do
			[[ $varname =~ $re_subcmd_vn ]] && continue
			IFS=" " read short long required <<< "${args[$varname]}"
			help="${args_help[$varname]}"
			printf "   -%s, --%-16s %s (required: %s)\n" "$short" "$long" "$help" "$required"
		done

		if [[ $n_subcmds > 0 ]]; then
			echo ""
			echo "Valid commands:"
			for subcmd in ${!subcmds[@]}; do
				printf "    %-12s %s\n" "$subcmd" "${subcmds[$subcmd]}"
			done

			for subcmd in ${!subcmds[@]}; do
				echo ""
				echo "Options for command \"$subcmd\":"
				local n=0
				for varname in ${!args[@]}; do
					[[ "${varname%:*}" == "$subcmd" ]] || continue
					((n++))
					IFS=" " read short long required <<< "${args[$varname]}"
					help="${args_help[$varname]}"
					printf "   -%s, --%-16s %s (required: %s)\n" "$short" "$long" "$help" "$required"
				done
				[[ $n == 0 ]] && echo "    (None)"
			done
			echo ""

			[[ -v COPYRIGHT ]] && echo -e "$COPYRIGHT"
		fi
	) | fold -w "$cols" -s >&$ofd
	exit 1
}

parse_args() {
	local short long required longprefix found
	local n_subcmds=${#subcmds[@]}
	declare -a bareargs reqargs
	while [[ -v 1 ]]; do
		case "$1" in
			--help|-h)
				usage ;;
			-*)
				# parse as named option
				found=false
				for varname in ${!args[@]}; do
					IFS=" " read short long required <<< "${args[$varname]}"
					if [[ $varname =~ $re_subcmd_vn ]]; then
						# subcommand option
						local vsubc _vn
						IFS=":" read vsubc _vn <<< "$varname"
						[[ "$vsubc" = "$COMMAND" ]] || continue
						varname=$_vn
					fi
					longprefix="--$long="
					case "$1" in
						-$short|--$long)
							[[ -v 2 ]] || usage "value for argument $1 may not be omitted"
							declare -g $varname="$2"
							found=true
							shift
							;;
						$longprefix*)
							found=true
							declare -g $varname=${1:${#longprefix}}
							;;
					esac
				done
				[[ "$found" == "true" ]] || usage "Unknown option: $1"
				;;
			*)
				if [[ $n_subcmds > 0 && $COMMAND == "" ]]; then
					COMMAND="$1"
					[[ -v subcmds[$COMMAND] ]] || usage "Undefined command: $COMMAND"
				else
					bareargs+=("$1")
				fi
				;;
		esac
		shift
	done

	[[ $n_subcmds > 0 && $COMMAND == "" ]] && usage "No command was given."

	# build list of missing required args
	for varname in ${!args[@]}; do
		IFS=" " read short long required <<< "${args[$varname]}"
		[[ "$required" == "true" ]] || continue
		if [[ $varname =~ $re_subcmd_vn ]]; then
			# subcommand option
			local vsubc _vn
			IFS=":" read vsubc _vn <<< "$varname"
			[[ "$vsubc" = "$COMMAND" ]] || continue
			[[ -v $_vn ]] && continue
			reqargs+=("$varname")
		else
			[[ -v $varname ]] && continue
			reqargs+=("$varname")
		fi
	done
	# process bareword args
	while [[ -v bareargs[0] && -v reqargs[0] ]]; do
		declare -g ${reqargs[0]#*:}="${bareargs[0]}"
		bareargs=("${bareargs[@]:1}")
		reqargs=("${reqargs[@]:1}")
	done

	# if there's any bareword arguments left, we are out of ideas for what to do with them, so fail.
	[[ -v bareargs[0] ]] && usage "Unknown argument: ${bareargs[0]}"

	# enforce required args
	for varname in ${!args[@]}; do
		IFS=" " read short long required <<< "${args[$varname]}"
		[[ "$required" == "true" ]] || continue
		if [[ $varname =~ $re_subcmd_vn ]]; then
			# subcommand arg
			local vsubc _vn
			IFS=":" read vsubc _vn <<< "$varname"
			[[ "$vsubc" == "$COMMAND" ]] || continue
			[[ ! -v $_vn ]] && usage "Option is required for command $vsubc but not set: $long"
		else
			# global arg
			[[ ! -v $varname ]] && usage "Required option or positional argument not set: $long"
		fi
	done
}
