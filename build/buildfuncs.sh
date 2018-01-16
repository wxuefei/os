#!/bin/bash

TARGET=x86_64-elf
SYSTEM=`uname -s`
if [ "$SYSTEM" = Darwin ]; then
    NPROC=`sysctl -n hw.activecpu`
else
    NPROC=`nproc`
fi
MAKE="make -j$NPROC"

die() {
    echo >&2 "$@"
    exit 1
}

GET() {
	wget -nc -c "$1/$2"
	gpg --verify ../${2}.sig $2
	sha256sum -c <<<"$3  $2"
}

unpack() {
	if [ ! -d "$1" ]; then
		echo "Unpacking $1..."
		for ext in xz bz2 gz; do
			if [ -f "${1}.tar.${ext}" ]; then
				break
			fi
		done
		if ! tar -xf "${1}.tar.${ext}"; then
			rm -fr "$1"
			return 1
		fi
	fi
	if [ -n "$2" ]; then
		ln -sfT "$1" "$2"
	fi
}


log() {
	echo "$@"
	test -n "$logging" && eval 'echo "$@" '"$logging"
}

r() {
	log "RUNNING: $@ [in `pwd`]"
	local res=0
	eval '"$@" '"$logging" || res=$?
	if [ $res -ne 0 ]; then
		log "FAILED: $@"
		if [ -n "$logfile" ]; then
			log "[ logs in $logfile ]"
		fi
	fi
	return $res
}

setlog() {
	logfile="$LOGDIR/${1}.log"
	:> "$logfile"
	logging=">>$logfile 2>&1"
}
clearlog() {
	logging=
	logfile=
}

CONFIGURE() {
	local dir="$1"
	shift
	echo "$@" > config_args.tmp
	if [ -f Makefile ] && ! cmp -s config_args config_args.tmp; then
		echo "Configure arguments changed! Rerunning configure."
		rm -f Makefile
	fi
	mv config_args.tmp config_args
	if [ ! -f Makefile ]; then
		r "../$dir/configure" "$@"
	fi
}

recv_keys() {
	local missing=()
	for key in "$@"; do
		if ! gpg --list-keys "$key"; then
			missing+=( "$key" )
		fi
	done
	echo Fetching keys: "${missing[@]}"
	# Ignoring failures since gpg seems to be random (maybe list-keys is
	# actually fetching from a server or something?)
	gpg --recv-keys "${missing[@]}" || true
}
