#!/bin/bash
# set -x

MP_SHA="71c57fcfdf43692adcd41fa7305be08f66bae3e5"
MP_ZIP="/tmp/munki-pkg.zip"
MP_BIN_DIR="${1:-/tmp/munki-pkg}"

# Echo the install directory if one was supplied
[[ -n "${1}" ]] && echo "Setting MP_BIN_DIR to ${1}"

# Check if there are remnants of munki-pkg and remove them

remove_file() { # Accepts a path as input
    if [[ -d "/Users/runner" ]]; then
        echo "We are running on a GitHub runner"
        /usr/bin/sudo /bin/rm -rf "${1}"
    else
        /bin/rm -rf "${1}"
    fi
}

if [ -f "${MP_ZIP}" ]; then
    echo "Found Existing ${MP_ZIP}, removing.."
    remove_file ${MP_ZIP}
fi

if [ -d "${MP_BIN_DIR}" ]; then
    echo "Found Existing ${MP_BIN_DIR}, removing.."
    remove_file ${MP_BIN_DIR}
fi

# Download a specific version of munki-pkg
echo "Downloading munki-pkg tool from GitHub..."

CURL_STATUS=$( /usr/bin/curl \
    --url https://github.com/munki/munki-pkg/archive/${MP_SHA}.zip \
    --output ${MP_ZIP} \
    --location \
    --write-out %{http_code}
)
    
if [[ "${CURL_STATUS}" -ne 200 ]] ; then
    echo "Error downloading munki-pkg tool with status: ${CURL_STATUS}" 1>&2
    exit 1
fi

# Unzip munki-pkg
echo "Downloading munki-pkg tool from GitHub..."

/usr/bin/unzip -j ${MP_ZIP} "munki-pkg-${MP_SHA}/munkipkg" -d "${MP_BIN_DIR}"
INSTALL_RESULT="$?"
if [ "${INSTALL_RESULT}" != "0" ]; then
    echo "Error unpacking munki-pkg archive: ${INSTALL_RESULT}" 1>&2
    exit 1
fi

# Running execution test
echo "Checking we can run munki-pkg with python3 from PATH..."

MP_VERSION=$( python3 "${MP_BIN_DIR}"/munkipkg --version )
if [[ -z "${MP_VERSION}" ]] ; then
    echo "Error executing munkipkg --version" 1>&2
    exit 1
else
    echo "Success: installed munki-pkg version: ${MP_VERSION}"
    exit 0
fi