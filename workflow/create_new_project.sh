#!/bin/bash
# set -x
# This script can be used to spawn your own repo.

# Will need to set the exicutble bit on scripts in the workflows dir

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