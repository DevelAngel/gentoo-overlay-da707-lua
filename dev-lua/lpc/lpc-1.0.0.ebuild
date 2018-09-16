# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit cmake-multilib

DESCRIPTION="Allows Lua scripts to call external processes while capturing both their input and output."
HOMEPAGE="https://github.com/LuaDist/lpc"
SRC_URI="https://github.com/LuaDist/lpc/archive/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~x86 ~amd64 ~arm ~arm64"
IUSE=""

# It is not needed to install COPYING because ebuild has this information.
PATCHES=( "${FILESDIR}"/lpc-1.0.0-remove-data-COPYING.patch )

multilib_src_configure() {
	local mycmakeargs=(
		-DINSTALL_LIB="${EPREFIX}/usr/$(get_libdir)"
	)
	cmake-utils_src_configure
}
