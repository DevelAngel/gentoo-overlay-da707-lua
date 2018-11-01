# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit eutils multilib git-r3

DESCRIPTION="Cloud roster module for Prosody IM: Take your Nextcloud groups to your XMPP client"
HOMEPAGE="https://github.com/jsxc/prosody-cloud-roster"
EGIT_REPO_URI="https://github.com/jsxc/prosody-cloud-roster"

LICENSE="MIT"
SLOT="0"
KEYWORDS=""


PROSODY_MODULES="roster_cloud"
IUSE=""

DEPEND="net-im/prosody"
RDEPEND="
	${DEPEND}
"

DOCS=( README.md )

src_install() {
	default

	cd "${S}";
	for m in ${PROSODY_MODULES}; do
		if [ "${m}" == "roster_cloud" ]; then
			insinto ${EPREFIX}/usr/$(get_libdir)/prosody/modules/mod_${m};
			doins "mod_${m}.lua"
			doins "json.lib.lua"
			doins "sha1.lib.lua"
		fi
	done
}
