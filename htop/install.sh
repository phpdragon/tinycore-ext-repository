#!/bin/sh
#
#  htop installer for Tiny Core Linux
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License along
#  with this program; if not, write to the Free Software Foundation, Inc.,
#  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
#  Copyright (c) 2024 phpdragon <phpdragon@qq.com>
#  Updated by phpdragon <phpdragon@qq.com>
#

HERE="$(cd $(dirname $0);pwd)"

# Source function library.
. "${HERE}/../functions"

check_not_root

# pkg architecture
SITE="https://htop.dev/downloads.html or https://github.com/htop-dev/htop/releases"

# shellcheck disable=SC2125
SOURCE_PACKAGE="/tmp/htop-"*".tar.xz"
# shellcheck disable=SC2012
SOURCE_PACKAGE_FILE=$(ls "/tmp/htop-"*".tar.xz" 2> /dev/null | tail -1)
PACKAGE_FILE_NAME=$(echo "$SOURCE_PACKAGE_FILE"|sed 's|/tmp/||'|sed 's|.tar.xz||')
PKG_VERSION=$(echo "$SOURCE_PACKAGE_FILE"|awk -F '-' '{print $2}'|sed 's|.tar.xz||')
build_usage_tip() {
      cat <<EOF
=======================================================
        $EXT_NAME installer for Tiny Core Linux
             by phpdragon <phpdragon@qq.com>
         Updated by phpdragon <phpdragon@qq.com>
=======================================================

Before proceeding You must download ${SOURCE_PACKAGE:-/tmp/htop-*.tar.xz}
from $SITE
to /tmp directory !

EOF
  # shellcheck disable=SC2039
  read -r -n 1 -p "Press any key to continue... " -s
}

build_check() {
    [ -e "${SOURCE_PACKAGE_FILE}" ] || die "${SOURCE_PACKAGE} not found! exiting ..."
    return 0
}

build_env_init(){
    cat  <<EOF

+-----------------------------------------------------+
| Install the necessary dependent environments, list: |
+-----------------------------------------------------+
autoconf
automake
m4
pkg-config
gcc
libtool
ncursesw
ncursesw-dev
make
glibc => glibc_base-dev
glibc-lib => glibc_add_lib
headers => linux-6.1_api_headers
==>
EOF
    tce-load -wi autoconf automake m4 pkg-config gcc ncursesw ncursesw-dev make glibc_base-dev glibc_add_lib linux-6.1_api_headers || return 1
    cat <<EOF
-------------------------------------------------------

EOF
    return 0
}

clean_src_files(){
    cd "${WORK_DIR}" || return 1

    # rm -rf src
    rm -rf "${EXT_SRC_DIR}"
}

clean_source_files() {
  if ask_clean_source_files "$1" ;then
    rm -f "${SOURCE_PACKAGE_FILE}"
  fi
}

ask_clean_source_files() {
      if [ "$1" != "ask" ];then
        return 1
      fi

cat <<EOF

+------------------------------------------------------+
| Do you want to keep the following build source file: |
+------------------------------------------------------+
${SOURCE_PACKAGE_FILE}
--------------------------------------------------------
EOF
    # shellcheck disable=SC2162
    # shellcheck disable=SC2039
    read -n 1 -p "keep them (y/n) [n]:" answer
    case ${answer} in
       y | Y)
          echo ""
          return 1
          ;;
       *)
          echo ""
          return 0
          ;;
    esac
}

build_pkg_src() {
  tar xf "${SOURCE_PACKAGE_FILE}" -C "/tmp" || return 1
  cd "/tmp/${PACKAGE_FILE_NAME}" || return 1
  ./autogen.sh
  ./configure --prefix=/usr/local
  make -j"${CORES_COUNT}"

  mkdir -p "${SRC_USR_LOCAL_DIR}"
  mkdir -p "${SRC_USR_LOCAL_BIN_DIR}"
  mkdir -p "${SRC_USR_LOCAL_DIR}/share/icons/hicolor/scalable/apps/"
  mkdir -p "${SRC_USR_LOCAL_DIR}/share/applications/"
  mkdir -p "${SRC_USR_LOCAL_DIR}/share/pixmaps/"
  mkdir -p "${SRC_USR_LOCAL_DIR}/share/man/man1/"
  mkdir -p "${EXT_OUT_PUT_DIR}"

  cp htop "${SRC_USR_LOCAL_BIN_DIR}"
  cp htop.svg "${SRC_USR_LOCAL_DIR}/share/icons/hicolor/scalable/apps/"
  cp htop.desktop "${SRC_USR_LOCAL_DIR}/share/applications/"
  cp htop.png "${SRC_USR_LOCAL_DIR}/share/pixmaps/"
  cp htop.1 "${SRC_USR_LOCAL_DIR}/share/man/man1/"

  rm -rf "/tmp/${PACKAGE_FILE_NAME}"

  return 0
}

get_pkg_info() {
  size=$(du -h "${EXT_OUT_PUT_FILE}"|awk '{print $1}')

  cat <<EOF
Title:          ${TCZ_NAME}
Description:    Interactive process viewer
Version:        ${PKG_VERSION}
Author:         Hisham H. Muhammad
Original-site:  https://htop.dev/
Copying-policy: GPL v2
Size:           ${size}
Extension_by:   phpdragon <phpdragon@qq.com>
Tags:           SYSTEM CLI
Comments:       Binaries only
                ----
Change-log:     ----
Current:        ${CURRENT_DAY} Original for TC ${OS_TRUNK_VERSION}.x
EOF
}

build_result_tip(){
  echo ""
  cat <<EOF
${GREEN}Congratulations, All Done !${NORMAL}

EOF
}

main

