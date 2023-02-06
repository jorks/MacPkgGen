#!/bin/bash
# set -x

MP_SHA="71c57fcfdf43692adcd41fa7305be08f66bae3e5"
MP_ZIP="/tmp/munki-pkg.zip"
MP_BINDIR="/tmp/munki-pkg"


# Check if there are remnants of munki-pkg and remove them

if [ -f "${MP_ZIP}" ]; then
    echo "Found Existing ${MP_ZIP}, removing.."
    /usr/bin/sudo /bin/rm -rf ${MP_ZIP}
fi

if [ -d "${MP_BINDIR}" ]; then
    echo "Found Existing ${MP_BINDIR}, removing.."
    /usr/bin/sudo /bin/rm -rf ${MP_BINDIR}
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

/usr/bin/unzip -j ${MP_ZIP} "munki-pkg-${MP_SHA}/munkipkg" -d "${MP_BINDIR}"
INSTALL_RESULT="$?"
if [ "${INSTALL_RESULT}" != "0" ]; then
    echo "Error unpacking munki-pkg archive: ${INSTALL_RESULT}" 1>&2
    exit 1
fi


# Running execution test
echo "Checking we can run munki-pkg with python3 from PATH..."

MP_VERSION=$( python3 ${MP_BINDIR}/munkipkg --version )
if [[ -z "${MP_VERSION}" ]] ; then
    echo "Error executing munkipkg --version" 1>&2
    exit 1
else
    echo "Success: installed munki-pkg version: ${MP_VERSION}"
    exit 0
fi