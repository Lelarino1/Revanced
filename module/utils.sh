#!/system/bin/sh

RVPATH=/data/adb/rvhc/${MODDIR##*/}.apk
. "$MODDIR/config"

# Magisk supports `su -M`; KernelSU variants may not. Use the init mount
# namespace as a compatible fallback so install, service, and Action use the
# same mount view.
mount_exec() {
	if su -M -c true >/dev/null 2>&1; then
		su -M -c "$@"
	else
		nsenter -t 1 -m "$@"
	fi
}

ch_desc() {
	sed -i "s|^description=.*|description=${1}|" "$MODDIR/module.prop"
}

ch_desc_err() {
	ch_desc "⚠️ Needs reflash: '${1}'"
}

pmex() {
	OP=$(pm "$@" 2>&1 </dev/null)
	RET=$?
	echo "$OP"
	return $RET
}

get_app_version() {
	VERSION=$(dumpsys package "$PKG_NAME" 2>&1 | grep -m1 versionName=)
	VERSION="${VERSION#*=}"
	echo "$VERSION"
}

get_basepath() {
	BASEPATH=$(pmex path "$PKG_NAME")
	SVCL=$?
	BASEPATH=${BASEPATH##*:}
	BASEPATH=${BASEPATH%/*}
	echo "$BASEPATH"
	return $SVCL
}

umount_all() {
	mount_exec grep -F "$PKG_NAME" /proc/mounts | while read -r line; do
		mp=${line#* }
		mp=${mp%% *}
		mp=${mp%%\\*}
		mount_exec umount -l "$mp"
	done
	am force-stop "$PKG_NAME" || :
}

get_mounts() {
	mount_exec grep -F "$PKG_NAME" /proc/mounts || :
}

mount_rv() {
	if [ ! -d "${1}/lib" ]; then
		ch_desc_err "Your installation got broken. Dont report this, consider using rvmm-zygisk-mount."
		return 1
	fi
	VERSION=$(get_app_version)
	if [ "$VERSION" != "$PKG_VER" ] && [ "$VERSION" ]; then
		ch_desc_err "Version mismatch (installed:$VERSION, module:$PKG_VER)"
		return 1
	fi
	umount_all
	if ! OP=$(chcon u:object_r:apk_data_file:s0 "$RVPATH" 2>&1); then
		ch_desc_err "Error chcon: '$OP'"
		return 1
	fi
	if ! OP=$(mount_exec mount -o bind "$RVPATH" "${1}/base.apk" 2>&1); then
		ch_desc_err "Mount failed: '$OP'"
		return 1
	fi
	am force-stop "$PKG_NAME"
	[ -f "$MODDIR/module.prop.orig" ] && cp -f "$MODDIR/module.prop.orig" "$MODDIR/module.prop"
	return 0
}

mount_rv_now() {
	if ! BASEPATH=$(get_basepath); then
		ch_desc_err "App not installed: '$BASEPATH'"
		return 1
	fi
	mount_rv "$BASEPATH"
}
