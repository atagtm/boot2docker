#!/bin/sh
#set -e

# Cross-platform `sed -i`
GNU=$(sed --version > /dev/null 2>&1 && echo 1 || echo 0)
#echo "GNU=$GNU"
sed_inplace() {
    [ "$GNU" == "1" ] && sed -i "$1" "$2" || sed -i '' "$1" "$2"
}

# Allow override from ENV
: "${SCRIPT:=Dockerfile}"

# Create backup
NOW=$(date +%Y%m%d-%H%M%S)
cp $SCRIPT $SCRIPT.$NOW

# Update ENV in file
update_env() {
  local var="$1"
  local val="$2"
  [ "$val" == "" ] && { echo "$var is empty, exiting!"; restore_and_exit; }
  sed_inplace 's|^ENV '"$var"'="[^"]*"|ENV '"$var"'="'"$val"'"|' "$SCRIPT.$NOW" && \
      echo "Updating $1 to \"$2\"... Success!" || \
      restore_and_exit
}

restore_and_exit() {
    mv $SCRIPT.$NOW $SCRIPT.err
    echo "An error has occurred, check '$SCRIPT.err' and find out what is going on."
    echo "The file '$SCRIPT' has NOT been modified!!!"
    exit 1
}

version=$(wget -qO - "http://tinycorelinux.net/latest-x86_64")
major=${version%%\.*}.x

mirrors="http://repo.tinycorelinux.net http://distro.ibiblio.org/tinycorelinux"
update_env TCL_MIRRORS "$mirrors"
update_env TCL_MAJOR "$major"
update_env TCL_VERSION "$version"

# https://www.kernel.org/
kernelBase='6.12'
# https://github.com/boot2docker/boot2docker/issues/1398

# avoid issues with slow Git HTTP interactions (*cough* sourceforge *cough*)
export GIT_HTTP_LOW_SPEED_LIMIT='100'
export GIT_HTTP_LOW_SPEED_TIME='2'
# ... or servers being down
wget() { command wget --timeout=2 "$@" -o /dev/null; }

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"



fetch() {
	local file
	for file; do
		local mirror
        eval "set -- $mirrors"
		for mirror in "$@"; do
			if wget -qO- "$mirror/$major/$file"; then
				return 0
			fi
		done
	done
	return 1
}

arch='x86_64'
rootfs='rootfs64.gz'

rootfsMd5="$(
# 9.x doesn't seem to use ".../archive/X.Y.Z/..." in the same way as 8.x :(
	fetch \
		"$arch/archive/$version/distribution_files/$rootfs.md5.txt" \
		"$arch/release/distribution_files/$rootfs.md5.txt"
)"
rootfsMd5="${rootfsMd5%% *}"
update_env TCL_ROOTFS "$rootfs"
update_env TCL_ROOTFS_MD5 "$rootfsMd5"

# Squashfs
squashFsVersion=$(
    wget -qO- "https://api.github.com/repos/plougher/squashfs-tools/releases/latest" \
        | grep tag_name \
        | cut -d '"' -f 4
)
update_env SQUASHFS_VERSION "$squashFsVersion"

kernelVersion="$(
	wget -qO- 'https://www.kernel.org/releases.json' \
		| jq -r --arg base "$kernelBase" '.releases[] | .version | select(startswith($base + "."))'
)"
update_env LINUX_VERSION "$kernelVersion"

# https://download.virtualbox.org/virtualbox/
vboxBase='7'

vboxVersion="$(wget -qO- 'https://download.virtualbox.org/virtualbox/LATEST-STABLE.TXT')"
vboxVersion="$(
	wget -qO- 'https://download.virtualbox.org/virtualbox/' \
		| grep -oE 'href="[0-9.]+/?"' \
		| cut -d'"' -f2 | cut -d/ -f1 \
		| grep -E "^$vboxBase[.]" \
		| tail -1
)"
vboxSha256="$(
	{
		wget -qO- "https://download.virtualbox.org/virtualbox/$vboxVersion/SHA256SUMS" \
		|| wget -qO- "https://www.virtualbox.org/download/hashes/$vboxVersion/SHA256SUMS"
	} | awk '$2 ~ /^[*]?VBoxGuestAdditions_.*[.]iso$/ { print $1 }'
)"
update_env VBOX_VERSION "$vboxVersion"
update_env VBOX_SHA256 "$vboxSha256"

dockerVersion="$(
	wget -qO- "https://api.github.com/repos/moby/moby/releases/latest" |
	grep '"tag_name":' |
	sed -E 's/.*"docker-v([^"]+)".*/\1/'                
)"
update_env DOCKER_VERSION "$dockerVersion"

# Save the updated file
mv $SCRIPT $SCRIPT.tmp
mv $SCRIPT.$NOW $SCRIPT
mv $SCRIPT.tmp $SCRIPT.$NOW
echo "All done :)"
