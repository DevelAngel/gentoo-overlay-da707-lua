# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

PYTHON_COMPAT=( python3_{4,5,6,7} )

inherit multilib distutils-r1 user systemd

DESCRIPTION="Authentication hub for Nextcloud+JSXC -> Prosody, ejabberd, saslauthd, Postfix"
HOMEPAGE="https://www.jsxc.org/"
SRC_URI="https://github.com/jsxc/xmpp-cloud-auth/archive/v${PV}.tar.gz -> ${P}.tar.gz"
KEYWORDS="~amd64 ~arm ~x86"
S=${WORKDIR}/xmpp-cloud-auth-${PV}

LICENSE="MIT"
SLOT="0"
IUSE="+socket prosody ejabberd postfix saslauth"

PROSODY_MODULES="auth_external_xcauth"
for m in ${PROSODY_MODULES}; do
	IUSE="${IUSE} prosody_modules_${m}"
done

REQUIRED_USE="${REQUIRED_USE} socket? ( || ( prosody ejabberd postfix saslauth ) )"

for m in ${PROSODY_MODULES}; do
	REQUIRED_USE="${REQUIRED_USE} prosody_modules_${m}? ( prosody )"
done

for m in ${PROSODY_MODULES}; do
	DEPEND="${DEPEND} prosody_modules_${m}? ( net-im/prosody )"
done

RDEPEND="${DEPEND}"
RDEPEND="${RDEPEND} dev-lang/python[sqlite]" # needed by xclib.db
RDEPEND="${RDEPEND} dev-python/urllib3[${PYTHON_USEDEP}]" # needed by xclib.sigcloud
RDEPEND="${RDEPEND} dev-python/bsddb3[${PYTHON_USEDEP}]" # needed by xclib.{db,dbmops}

XCAUTH_ETC="/etc/${PN}"
XCAUTH_LOG="/var/log/${PN}"
XCAUTH_HOME="/var/lib/${PN}"

DOCS=( README.md CHANGELOG.md doc/ )

PATCHES=(
	"${FILESDIR}"/${PN}-2.0.2-change-conf-path.patch
	"${FILESDIR}"/${PN}-2.0.2-change-xcauth-path.patch
	"${FILESDIR}"/${PN}-2.0.2-remove-sasl-chgrp-command.patch
)

pkg_setup() {
	ebegin "Creating ${PN} user and group"
	enewgroup ${PN}
	enewuser ${PN} -1 -1 ${XCAUTH_HOME} ${PN}
	eend $?
}

src_unpack() {
	default

	if [ ! -f "${S}"/setup.py ]; then
		cp "${FILESDIR}"/setup-${PV}.py "${S}"/setup.py
		elog "Add missing setup.py"
	fi

	if [ -f "${S}"/Makefile ]; then
		rm "${S}"/Makefile
		elog "Remove Makefile because ebuild handles installation"
	fi
}

python_install_all() {
	default
	distutils-r1_python_install_all

	# install to /usr/bin instead of /usr/sbin
	newbin xcauth.py ${PN}

	# systemd
	systemd_dounit systemd/${PN}.service
	if use socket; then
		use prosody && systemd_dounit systemd/xcprosody.socket
		use ejabberd && systemd_dounit systemd/xcejabberd.socket
		use postfix && systemd_dounit systemd/xcpostfix.socket
		use saslauth && systemd_dounit systemd/xcsaslauth.socket
	fi
	systemd_newtmpfilesd "${FILESDIR}/${PN}".tmpfilesd "${PN}".conf

	# prosody modules
	for m in ${PROSODY_MODULES}; do
		if use prosody_modules_${m}; then
			insinto ${EPREFIX}/usr/$(get_libdir)/prosody/modules/mod_${m};
			if [ "${m}" = "auth_external_xcauth" ]; then
				newins "prosody-modules/mod_auth_external.lua" mod_${m}.lua
				doins "prosody-modules/pseudolpty.lib.lua"
				einfo "xcauth's version of mod_auth_external is installed as mod_${m}"
			else
				doins "prosody-modules/mod_${m}.lua"
			fi
		fi
	done

	# logrotate
	insinto /etc/logrotate.d
	newins tools/xcauth.logrotate ${PN}

	# create the directory where our log file will go
	diropts -m 0750 -o ${PN} -g ${PN}
	keepdir ${XCAUTH_LOG}

	# conf
	diropts -m 0750 -o ${PN} -g ${PN}
	keepdir ${XCAUTH_ETC}
	insinto ${XCAUTH_ETC}
	doins xcauth.conf
}

pkg_postinst() {
	if use socket; then
		einfo "It is recommended for security reasons to use the xcauth socket to authenticate xmpp cloud users"
		if use prosody; then
			einfo "Use prosody module auth_external_xcauth to access the xcauth-prosody socket"
		fi
	else
		ewarn "It is recommended for security reasons to use the xcauth sockets to authenticate xmpp cloud users by activating the socket use flag"
	fi

	if use prosody || use ejabberd; then
		einfo "If you don't want to use the socket, add user jabber to group ${PN} to be able to read ${XCAUTH_ETC}/xcauth.conf"
	fi
}
