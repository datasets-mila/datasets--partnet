#!/bin/bash

source scripts/utils.sh echo -n

# Saner programming env: these switches turn some bugs into errors
set -o errexit -o pipefail

# This script is meant to be used with the command 'datalad run'

test_enhanced_getopt

PARSED=$(enhanced_getopt --options "h" --longoptions "curl-options:,refresh-token-data:,help" --name "$0" -- "$@")
eval set -- "${PARSED}"

REFRESH_TOKEN_DATA=$(git config --file scripts/nuscenes_config --get aws.refresh-token-data || echo "")

while [[ $# -gt 0 ]]
do
	arg="$1"; shift
	case "${arg}" in
		--curl-options) CURL_OPTIONS="$1"; shift
		echo "curl-options = [${CURL_OPTIONS}]"
		;;
		-h | --help)
		>&2 echo "Options for $(basename "$0") are:"
		>&2 echo "--curl-options OPTIONS"
		exit 1
		;;
		--) break ;;
		*) >&2 echo "Unknown argument [${arg}]"; exit 3 ;;
	esac
done

files_url=(
	"https://www.dropbox.com/sh/el63rv14d01mk89/AAAbHCL2UIIJH6LZX_Dxa9kta/Bag.zip Bag.zip"
	"https://www.dropbox.com/sh/el63rv14d01mk89/AAAbGcjG-XpVfDMgMAHie_06a/Bed.zip Bed.zip"
	"https://www.dropbox.com/sh/el63rv14d01mk89/AABF_HV9xK9YVCt39iyEOYj_a/Bottle.zip Bottle.zip"
	"https://www.dropbox.com/sh/el63rv14d01mk89/AABIz0rQnnv52LO0BgWQ34uza/Bowl.zip Bowl.zip"
	"https://www.dropbox.com/sh/el63rv14d01mk89/AADwM_IrJ6nKpTq8nECu78xba/Chair.7z Chair.7z"
	"https://www.dropbox.com/sh/el63rv14d01mk89/AADYeOCLq7nCEiK0oB0dlciBa/Clock.zip Clock.zip"
	"https://www.dropbox.com/sh/el63rv14d01mk89/AAB_MDBDlTgb1zibBmFLIq9la/Dishwasher.zip Dishwasher.zip"
	"https://www.dropbox.com/sh/el63rv14d01mk89/AAB-Pb8MDvtT7vgmHv_YAA6Ta/Display.zip Display.zip"
	"https://www.dropbox.com/sh/el63rv14d01mk89/AABge5kRqDYS4U3e2OQs5dpua/Door.zip Door.zip"
	"https://www.dropbox.com/sh/el63rv14d01mk89/AAA3MvBEGu1iloQqP5Dj9RxVa/Earphone.zip Earphone.zip"
	"https://www.dropbox.com/sh/el63rv14d01mk89/AABAWTyhK06Qm10VUB_yW7Ira/Faucet.zip Faucet.zip"
	"https://www.dropbox.com/sh/el63rv14d01mk89/AADx2zyH_aWTRdo78KGfLleja/Hat.zip Hat.zip"
	"https://www.dropbox.com/sh/el63rv14d01mk89/AABTpaHEr1-XTmKHYOP9B6w0a/Keyboard.zip Keyboard.zip"
	"https://www.dropbox.com/sh/el63rv14d01mk89/AABz5dRUNJOBPcrqKqDXKP-6a/Knife.zip Knife.zip"
	"https://www.dropbox.com/sh/el63rv14d01mk89/AAAFrN2iAaI1aGnhfgbI5gA9a/Lamp.zip Lamp.zip"
	"https://www.dropbox.com/sh/el63rv14d01mk89/AABU8htEQ9e3CYaaW-5K5O8Ba/Laptop.zip Laptop.zip"
	"https://www.dropbox.com/sh/el63rv14d01mk89/AAD16e7KfctsVeDKOxmFR_5Aa/Microwave.zip Microwave.zip"
	"https://www.dropbox.com/sh/el63rv14d01mk89/AADukMqOMUGBaJeVTHyDk0fza/Mug.zip Mug.zip"
	"https://www.dropbox.com/sh/el63rv14d01mk89/AABmx4JyHwbl0DerCFyoQCqJa/Refrigerator.zip Refrigerator.zip"
	"https://www.dropbox.com/sh/el63rv14d01mk89/AAC3575NbmxpkAX8E_cXOlhWa/Scissors.zip Scissors.zip"
	"https://www.dropbox.com/sh/el63rv14d01mk89/AABOScH0U88vAEmBJhFXW3v4a/Storage.zip Storage.zip"
	"https://www.dropbox.com/sh/el63rv14d01mk89/AAAjknXvalE7aJn7ZBrcZaGJa/Table.zip Table.zip"
	"https://www.dropbox.com/sh/el63rv14d01mk89/AABMWig48NVEN57-cZVoH8gXa/TrashCan.zip TrashCan.zip"
	"https://www.dropbox.com/sh/el63rv14d01mk89/AAAq2ZU-NL-p01zYiGdlq4Bpa/Vase.zip Vase.zip")

# There seams to be a filter on user agent which causes the git-annex user
# agent to be blocked
_curl_version=$(curl --version | grep -o "curl [0-9]*\.[0-9]**\.[0-9]*")
_curl_version=curl/${_curl_version#curl }

# These urls require login cookies to download the file
git-annex addurl -c annex.largefiles=anything --raw --batch --with-files \
	 -J8 -c annex.security.allowed-ip-addresses=all -c annex.web-options="${CURL_OPTIONS} --user-agent ${_curl_version}" <<EOF
$(for file_url in "${files_url[@]}" ; do echo "${file_url}" ; done)
EOF
git-annex get --fast \
	-J8 -c annex.security.allowed-ip-addresses=all -c annex.web-options="${CURL_OPTIONS} --user-agent ${_curl_version}"
git-annex migrate --fast -c annex.largefiles=anything *

md5sum *.zip *.7z > md5sums
