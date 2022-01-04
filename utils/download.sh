#!/usr/bin/env bash

# usage: download.sh url
#   downloads resource at  url  to the current working directory.

function log_error() {
	echo "ERROR:" "$@" >&2
}

function log_info() {
	echo "INFO:" "$@"
}

url="$1"
out_file="$2"

if [ -z "$url" ]; then
	log_error "must specify source url"
	exit 1
elif [ -z "$out_file" ]; then
	log_error "must specify output file location"
	exit 1
fi


# We default to wget because it seems like a better choice for this sort of work -
# doesn't overwrite files by default, better progress bar, downloads resources that
# don't have a name e.g. https://example.com/.
if [ -n "$DOWNLOAD_BACKEND" ]; then
	download_backend="$DOWNLOAD_BACKEND"
elif command -v wget >& /dev/null; then
	log_info "using wget backend"
	download_backend="wget"
elif command -v curl >& /dev/null; then
	log_info "using curl backend"
	download_backend="curl"
else
	log_error "either wget or curl must be installed on this system"
	exit 1
fi

log_info "fetching remote resource at '$1'"

progress_text="Downloading '${out_file##*/}'"

log_info "downloading '$url' to '$out_file'"

case "$download_backend" in
	"wget")
		wget "$url" --progress=dot --no-verbose --show-progress -O "$out_file" 2>&1 \
			| grep --line-buffered --color=never -oE '[0-9]+%' \
			| zenity --progress --auto-kill --auto-close --text="$progress_text"
		;;

	"curl")
		redirected_url=$(curl -ILs -o /dev/null -w '%{url_effective}' "$url")

		curl "$redirected_url" -o "$out_file" -# 2>&1 \
			| tr '\r' '\n' \
			| grep --line-buffered --color=never -oE '[0-9]+\.[0-9]+%' \
			| zenity --progress --auto-kill --auto-close --text="$progress_text"
		;;
esac

if [ "$?" != "0" ]; then
	log_error "could not fetch '$url'"
	exit 1
fi

