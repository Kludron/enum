#!/bin/bash

help="usage: $0 [-o | --output <outputfile>, -p | --ports <ports>] -t <target>"

while [[ "$#" -gt 0 ]]; do
	case $1 in
		-h|--help) 
			echo $help; # Print help
			shift 
			shift
			;;
		-t|--target) 
			target="$2"; 
			shift 
			shift
			;;
		-o|--output) 
			output="$2"; 
			shift 
			shift
			;;
		-p|--ports) 
			ports="$2"; 
			shift 
			shift
			;;
		-s|--scanner)
			scanner="$2";
			shift
			shift
			;;
	*)	#Unknown option
		POSITIONAL+=("$1") # Save it in an array for later
		shift
		;;
	esac
done

if [ -z "$target" ]; then
	echo "Please specify a target [-t <target>]"
	echo $help
else
	
	# Parse the target to get an ip address
	if [ ! "$target" == "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" ]; then
		resolvedip=$(dig +short $target)
		if [ -z "$resolvedip" ]; then
			>&2 echo "Unable to resolve the target"
			exit
		else
			target="$resolvedip"
		fi
	fi

	# Set the default ports
	if [ -z "$ports" ]; then
		ports="1-65535"
	fi

	# Check if a scanner was specified
	if [ -z "$scanner" ]; then
		scanner="nmap"
	fi

	# Check which scanner to use
	if [ "$scanner" == "nmap" ]; then
		scan=$(sudo nmap $target -p$ports --open -T4)
		result=$(grep ^[0-9] <<< $scan | awk -F "/" '{print $1}' | tr '\n' ',' | awk '{print substr($0, 1, length($0)-1)}')
	elif [ "$scanner" == "masscan" ]; then
		scan=$(sudo masscan $target -p$ports --open-only --rate 100)
		result=$(awk '{print $4}' <<< $scan | awk -F "/" '{print $1}' | tr '\n' ',' | awk '{print substr($0, 1, length($0)-1)}')
	fi

	# List unknown arguments
	if [ ! -z "$POSITIONAL" ]; then
		>&2 echo "Unknown options [$POSITIONAL]"
	fi

	# Print the resulting ports
	if [ -z "$result" ]; then
		>&2 echo "No open ports found"
	else
		if [ -z "$output" ]; then
			echo "$result"
		else
			printf "$result" > $output
		fi
	fi
	
fi
