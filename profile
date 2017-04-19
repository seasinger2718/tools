# System-wide .profile for sh(1)

PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/X11R6/bin"
export PATH

if [ "${BASH-no}" != "no" ]; then
	[ -r /etc/bashrc ] && . /etc/bashrc
fi
