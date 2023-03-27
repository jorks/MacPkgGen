#!/bin/bash
# set -x

#########################################################################################
# Script Information
#########################################################################################
#
# James Corcoran 2023 | https://jorks.net/
#
# Name:     install_dependencies.sh
# Version:  0.0.1
#
# Source: https://github.com/jorks/MacPkgGen

#########################################################################################
# General Information
#########################################################################################
#
# install_dependencies after you clone a repository that 
# uses the Mac Package Generator template.
#
# MacPkgGen: https://github.com/jorks/MacPkgGen
#
# This script will:
#
# - Check for Xcode CLT and prompt to install if missing
# - Install munkipkg into the /tmp directory
# - Add a pre-commit git hook to the local project
# - Run a munkipkg BOM.txt sync


#########################################################################################
# Configuration
#########################################################################################

# Remote URL for the install_munkipkg script
  JORKS_MUNKI_INSTALL="https://raw.githubusercontent.com/jorks/MacPkgGen/main/helpers/install_munkipkg.sh"

# Remote URL for the pre-commit script
  JORKS_PRE_COMMIT="https://raw.githubusercontent.com/jorks/MacPkgGen/main/helpers/pre-commit"

# Munki PKG Install Directory
  MP_BIN_DIR="/tmp/munki-pkg"


#########################################################################################
# Testing and Logging
#########################################################################################
# Testing flag will enable the script logic to run without dependencies
  TESTING_MODE="false" # false (default) or true to speed things up and write more logs

# Enable logging to a file on disk and specify a directory
  ENABLE_LOGFILE="false" # false (default) or true to write the logs to a file
  LOGDIR="/var/tmp" # /var/tmp (default) or override by specifying a path


#########################################################################################
# Global Functions
#########################################################################################
# Logging:  info, warn, error, fatal (exits 1 or pass in an exit code after msg)
# Init:     sets up up logging and welcome text
# Cleanup:  trap function modity as reququred and finish text

  echoerr() { printf "%s\n" "$*" >&2 ; }
  echolog() { if [[ "${ENABLE_LOGFILE}" == "true" ]]; then printf "%s %s\n" "$(date +"%F %R:%S")" "$*" >>"${LOGFILE}"; fi }
  info()    { echoerr "[INFO ] $*" ; echolog "[INFO ]  $*" ; }
  warn()    { echoerr "[WARN ] $*" ; echolog "[WARN ]  $*" ; } 
  error()   { echoerr "[ERROR] $*" ; echolog "[ERROR]  $*" ; }
  fatal()   { echoerr "[FATAL] $*" ; echolog "[FATAL]  $*" ; exit "${2:-1}" ; }

  SCRIPT_NAME=$(basename ${0})
  _init () {
    # Setup log file if enabled
      if [[ "${ENABLE_LOGFILE}" == "true" ]]; then
        LOGFILE="${LOGDIR:-/var/tmp}/${SCRIPT_NAME}-$(date +"%F").log"
        [[ -n ${LOGDIR} && ! -d ${LOGDIR} ]] && mkdir -p "${LOGDIR}"
        [[ ! -f ${LOGFILE} ]] && touch "${LOGFILE}"
      fi

      info "## Script: ${SCRIPT_NAME}"
      info "## Start : $(date +"%F %R:%S")"
  }

  cleanup() {
    exitCode=$?

    # Do things here to clean up if required
    
    info "## Finish: $(date +"%F %R:%S")"
    info "## Exit Code: ${exitCode}"
  }

# Global Function Setup
  trap cleanup EXIT
  _init


#########################################################################################
# Script Functions
#########################################################################################

execute() {
    if ! "$@"; then
        fatal "Failed Running: $*"; exit 1;
    fi
}

execute_sudo() {
    local -a args=("$@")
    execute "/usr/bin/sudo" "${args[@]}"
}

function install_xcode_command_line_tools() {

    # Credit to the brew.sh team for this logic
    info "Searching online for the Command Line Tools"
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
    info "Installing ${INSTALL_LABEL}"
    # execute_sudo "/usr/sbin/softwareupdate" "-i" "${INSTALL_LABEL}"
    # execute_sudo "/usr/bin/xcode-select" "--switch" "/Library/Developer/CommandLineTools"
    fi
    /bin/rm "-f" "${XCODE_CLT_TOUCHFILE}"
}

function install_munkipkg_remote() {
    info "Running remote install_munkipkg script"
    /bin/bash -c "$(curl -fsSL ${JORKS_MUNKI_INSTALL})"
}

function check_munkipkg_with_python() {

    info "Checking we can run munki-pkg with python3 from PATH..."

    MP_VERSION=$( python3 ${MP_BIN_DIR}/munkipkg --version )
    if [[ -z "${MP_VERSION}" ]] ; then
        error "Can not execute munkipkg --version" 1>&2
        if [[ ! -f ${MP_BIN_DIR}/munkipkg ]]; then error "Can not find munki-pkg"; fi
        if ! command -v python3 &> /dev/null; then error "Can not find python3"; fi
        fatal "Unable to continue. Sorry."
    else
        info "Success: installed munki-pkg version: ${MP_VERSION}"    
    fi
}

function install_git_pre_commit_hook() {

    if [[ ! -e "${PROJECT_DIR}/.git/hooks/pre-commit" ]]; then
        info "Installing pre-commit hook"
        if [[ -e "${PROJECT_DIR}/helpers/pre-commit" ]]; then    
            info "Using the local copy in this repo"
            cat "${PROJECT_DIR}/helpers/pre-commit" >> "${PROJECT_DIR}/.git/hooks/pre-commit"
            chmod +x "${PROJECT_DIR}/.git/hooks/pre-commit"
        else
            info "No local copy found. Using the online copy"
            execute "curl" "-fsSL" "${JORKS_PRE_COMMIT}" "-o" "${PROJECT_DIR}/.git/hooks/pre-commit"
            chmod +x "${PROJECT_DIR}/.git/hooks/pre-commit"
        fi
    else
        info "Found existing pre-commit hook"
    fi

}

function run_munkipkg_bom_sync() {
    info "Running a BOM sync"
    python3 "${MP_BIN_DIR}/munkipkg" --sync "${PKG_PATH}"
    BOM_SYNC_RESULT=$?
    if [[ ${BOM_SYNC_RESULT} -ne "0" ]]; then
        error "BOM sync was not successful. Proceed with caution!"
     else
        info "BOM Sync was successful."
    fi
}

#########################################################################################
# Main Script
#########################################################################################

SCRIPT_DIR=$( realpath "${0}" )
BASE_DIR=$( dirname "${SCRIPT_DIR}" )
PROJECT_DIR=$( dirname "${BASE_DIR}" )

info "Project directory is: ${PROJECT_DIR}"

# Find the build-info file and set the package directory
BUILD_INFO_FILE="$( find "${PROJECT_DIR}" -name "build-info*" -print )"
if [[ -z "${BUILD_INFO_FILE}" ]]; then
    fatal "Error no build-info file found. Exiting."
else
    PKG_PATH="$( dirname "${BUILD_INFO_FILE}" )"
    info "Found package path: ${PKG_PATH}"
fi

install_xcode_command_line_tools
install_munkipkg_remote
check_munkipkg_with_python
install_git_pre_commit_hook
run_munkipkg_bom_sync
info "Successfully installed dependencies"