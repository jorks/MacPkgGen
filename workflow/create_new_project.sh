#!/bin/bash
# set -x
# This script can be used to spawn your own repo.

# Will need to set the exicutble bit on scripts in the workflows dir


# This is the GIT BITS

NEW_PACKAGE_NAME="my_new_package2"
NEW_PACKAGE_REMOTE="https://github.com/jorks/my_new_package2.git"

JORKS_TEMPLATE_REPO="https://github.com/jorks/Jamf-Prestage-Assets.git"

git clone "${JORKS_TEMPLATE_REPO}" "${NEW_PACKAGE_NAME}" && cd "${NEW_PACKAGE_NAME}" || exit
rm -rf .git
git init
git add .
git commit -m "New package created: ${NEW_PACKAGE_NAME}"
git remote add origin "${NEW_PACKAGE_REMOTE}"
git branch -M main
git push -u origin main


# This is the Python / Xcode Command Line Tools Bits

chomp() {
  printf "%s" "${1/"$'\n'"/}"
}

# Credit to the brew.sh team for this logic
if [[ ! -e "/Library/Developer/CommandLineTools/usr/bin/git" ]]; then
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

  INSTALL_LABEL="$(chomp "$(/bin/bash -c "${GET_LABEL}")")"

  if [[ -n "${INSTALL_LABEL}" ]]; then
    echo "Installing ${INSTALL_LABEL}"
    # /usr/bin/sudo "/usr/sbin/softwareupdate" "-i" "${INSTALL_LABEL}"
    # /usr/bin/sudo "/usr/bin/xcode-select" "--switch" "/Library/Developer/CommandLineTools"
  fi
  /bin/rm "-f" "${XCODE_CLT_TOUCHFILE}"
fi

# Install Munki PKG using remote script
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/jorks/Jamf-Prestage-Assets/HEAD/workflow/install_munkipkg.sh)"
MUNKIPKG_RESULT=$?

if [[ "${MUNKIPKG_RESULT}" -ne 0 ]]; then
	echo "Warning: Something went wrong installing MunkiPKG or using python3"
else
	echo "Success: Installing and running Munki PKG"
fi