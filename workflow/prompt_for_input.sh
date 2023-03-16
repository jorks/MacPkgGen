#!/bin/bash
# set -x

while [[ -z "${NEW_PACKAGE_NAME}" ]]; do
	echo "What is the Package Name: "
	echo -n ": "
	read -r NEW_PACKAGE_NAME
done

cat << EOF

==== IMPORTANT ====
The script will create a new local git repository.
In order to push code to GitHub some additional configuration is required.

This script can automatically:
 -  Add a remote origin GitHub repository URL
 -  Push the initial commit into GitHub

This requires two important prerequisites:
 1. You can authenticate to GitHub via the command line
 2. You have already created an empty repository via the GitHub website

EOF

while [[ -z "${PUSH_TO_GITHUB}" ]]; do

	echo "Would you like the script to configure this?"
	echo -n "Yes/No: "
	read -r PUSH_TO_GITHUB_RESPONSE

	case ${PUSH_TO_GITHUB_RESPONSE} in
		Yes|yes|Y|y )
			PUSH_TO_GITHUB="true"
			while [[ -z "${GIT_REMOTE_ORIGIN}" ]]; do
				echo ""
				echo "Cool! You have made the right choice."
				echo "What is the URL of the GitHub repository:"
				echo "EG: (https://github.com/username/some-empty-repository.git)"
				echo -n ": "
				read -r GIT_REMOTE_ORIGIN
			done
			;;
		No|no|N|n )
			PUSH_TO_GITHUB="false"
			echo ""
			echo "NOTE: You will need perform some steps after this script."
			echo "This can be with the following commands:"
			echo "   git remote add origin <url>"
			echo "   git push origin main"
			echo ""
			;;
		* )
			echo "Sorry I don't understand your response."
			;;
	esac

done


while [[ -z "${PROCEED}" ]]; do
	echo ""
	echo "==== PLEASE CONFIRM ===="
	echo "Package Name: ${NEW_PACKAGE_NAME}"
	[[ "${PUSH_TO_GITHUB}" == "true" ]] && echo "Remote URL:   ${GIT_REMOTE_ORIGIN}"
	[[ "${PUSH_TO_GITHUB}" == "false" ]] && echo "No Remote URL will be set."
	echo -n "All good? Yes/No: "
	read -r CONFIRMATION

	case ${CONFIRMATION} in
		Yes|yes|Y|y )
			PROCEED="Yes"
			echo "Nice."
			;;
		No|no|N|n )
			echo "Typos happen. Please re-run the script :)"
			exit 0
			;;
		* )
			echo "Sorry I don't understand your response."
			;;
	esac

done


