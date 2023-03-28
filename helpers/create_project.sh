#!/bin/bash
# set -x
# This script can be used to spawn your own repo.

# Will need to set the executable bit on scripts in the helpers dir

JORKS_TEMPLATE_REPO="https://github.com/jorks/MacPkgGen.git"
JORKS_MUNKI_INSTALL="https://raw.githubusercontent.com/jorks/MacPkgGen/main/helpers/install_munkipkg.sh"

function prompt_for_inputs() {

	cat << EOF

==== WELCOME ====
This script will create a new GitHub repo to source control a macOS package.
It uses GitHub Workflows to build and release packages that are signed and notarized.
Hope you enjoy!

EOF

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
				NEW_REPO_NAME=${GIT_REMOTE_ORIGIN##*/}
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
		[[ "${PUSH_TO_GITHUB}" == "true" ]]  && echo "Repo Name:    ${NEW_REPO_NAME/%.git}"
		[[ "${PUSH_TO_GITHUB}" == "true" ]]  && echo "Remote URL:   ${GIT_REMOTE_ORIGIN}"
		[[ "${PUSH_TO_GITHUB}" == "false" ]] && echo "Repo Name:    ${NEW_PACKAGE_NAME// /-} (Assumed)"
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

}

execute() {
  if ! "$@"; then
    echo "Failed Running: $*" 1>&2; exit 1;
  fi
}

execute_sudo() {
  local -a args=("$@")
  execute "/usr/bin/sudo" "${args[@]}"
}

function install_xcode_command_line_tools() {

	# Credit to the brew.sh team for this logic
	echo "Searching online for the Command Line Tools"
	# This temporary file prompts the 'softwareupdate' utility to list the Command Line Tools
	XCODE_CLT_TOUCHFILE="/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"
	touch "${XCODE_CLT_TOUCHFILE}"

	GET_LABEL="/usr/sbin/softwareupdate -l |
	                  grep -B 1 -E 'Command Line Tools' |
	                  awk -F'*' '/^ *\\*/ {print \$2}' |
	                  sed -e 's/^ *Label: //' -e 's/^ *//' |
	                  sort -V |
	                  tail -n1"

	INSTALL_LABEL="$(printf "%s" "$(/bin/bash -c "${GET_LABEL}")")"

	if [[ -n "${INSTALL_LABEL}" ]]; then
	echo "Installing ${INSTALL_LABEL}"
	execute_sudo "/usr/sbin/softwareupdate" "-i" "${INSTALL_LABEL}"
	execute_sudo "/usr/bin/xcode-select" "--switch" "/Library/Developer/CommandLineTools"
	fi
	/bin/rm "-f" "${XCODE_CLT_TOUCHFILE}"

}

function install_munkipkg_remote() {

	/bin/bash -c "$(curl -fsSL ${JORKS_MUNKI_INSTALL})"
}

function git_clone_template_and_reinitialise() {

	if [[ -z "${JORKS_TEMPLATE_REPO}" && -z "${NEW_PACKAGE_NAME}" ]]; then
		echo "Error: Missing input to create new project." 1>&2
		exit 1
	fi

	case "${PUSH_TO_GITHUB}" in
		true )
			NEW_LOCAL_REPO="${NEW_REPO_NAME/%.git}"
			;;
		false )
			NEW_LOCAL_REPO="${NEW_PACKAGE_NAME// /-}"
			;;
	esac

	echo "Cloning Template: ${JORKS_TEMPLATE_REPO}"
	echo "Creating Project: ${NEW_LOCAL_REPO}"

	execute "git" "clone" "${JORKS_TEMPLATE_REPO}" "${NEW_LOCAL_REPO}"
	execute "cd" "${NEW_LOCAL_REPO}"
	execute "rm" "-rf" ".git"
	execute "git" "init"
	execute "git" "add" "--all"
	execute "git" "commit" "--no-verify" "-m" "New package created: ${NEW_PACKAGE_NAME}"
	execute "git" "branch" "-M" "main"
	[[ "${PUSH_TO_GITHUB}" == "true" ]] && execute "git" "remote" "add" "origin" "${GIT_REMOTE_ORIGIN}"
}

function git_create_readme() {
	if mv -f "README.md" "INSTRUCTIONS.md"; then
		echo "Creating INSTRUCTIONS.md and README.md"
		new_readme_content
	fi 
}

function new_readme_content() {

cat << EOF > README.md
# ${NEW_PACKAGE_NAME}

This package is source controlled and managed with git and GitHub Workflows.

### Package Notes

This package includes..

### Change History

More Info..

### Workflow Credit

Workflow and scripts by [James Corcoran](https://jorks.net).</br>
[https://github.com/jorks/MacPkgGen](https://github.com/jorks/MacPkgGen)
EOF

}


function git_add_commit() {

	echo "Running: git add commit"
	execute "git" "add" "--all"
	execute "git" "commit" "--no-verify" "-m" "New package created: ${NEW_PACKAGE_NAME}"
}

function git_push() {

	echo "Running: git push (if enabled)"
	execute "git" "push" "-u" "origin" "main"
}

function install_git_pre-commit_hook() {

	if [[ -e "helpers/pre-commit" ]]; then	
		echo "Installing a pre-commit git hook"
		cat "helpers/pre-commit" >> ".git/hooks/pre-commit"
		chmod +x ".git/hooks/pre-commit"
		# execute "cat" "helpers/pre-commit" ">>" ".git/hooks/pre-commit"
		# execute "chmod" "+x" ".git/hooks/pre-commit"
	fi
}

function message_error_pre-commit_hook() {

cat << EOF

==== WARNING ====
There was an issue installing the pre-commit git hook.
This git hook is required to create a BOM file used to 
track permissions and empty folders. This is going to cause 
issues when you attempt to build packages with GitHub Actions.

You can fix this manually by copying the file:
    helpers/pre-commit
Into this hidden directory:
	.git/hooks/pre-commit

=================

EOF
}


# Main

# Start the script by prompting for required inputs
prompt_for_inputs

# Check for Xcode Command Line Tools or prompt to install
if [[ ! -e "/Library/Developer/CommandLineTools/usr/bin/git" ]]; then
	echo "Notice: XCode Command Line Tools are required."
	echo "Attempting to install.."
	install_xcode_command_line_tools
fi

# Create a new Git project from the template
git_clone_template_and_reinitialise
git_create_readme

# Install Munki PKG using remote script
if install_munkipkg_remote; then
	echo "Success: Installing and running Munki PKG"
else
	echo "Error: Something went wrong installing MunkiPKG or using python3" 1>&2
	echo "Will still attempt to move forward. You may need to rm and start again sorry."
fi

echo "Running: Blank Package Creation with name: ${NEW_PACKAGE_NAME}"
if python3 /tmp/munki-pkg/munkipkg --json --create "${NEW_PACKAGE_NAME}"; then
	echo "Success: New package structure created"
	
	if install_git_pre-commit_hook; then
		echo "Success: Added a pre-commit hook to this git project"
	else
		message_error_pre-commit_hook
	fi

	git_add_commit
	if [[ "${PUSH_TO_GITHUB}" == "true" ]]; then git_push; fi
else
	echo "Error: something went wrong. Please try again." 1>&2
	exit 1
fi

cat << EOF

==== SUCCESS ====
The project "${NEW_PACKAGE_NAME}" has been successfully created.

EOF
