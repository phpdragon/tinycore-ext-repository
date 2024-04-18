#!/bin/sh
#
#  lrzsz installer for Tiny Core Linux
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
SITE="https://www.ohse.de/uwe/software/lrzsz.html"

# shellcheck disable=SC2125
SOURCE_PACKAGE="/tmp/lrzsz-"*".tar.gz"
# shellcheck disable=SC2012
SOURCE_PACKAGE_FILE=$(ls "/tmp/lrzsz-"*".tar.gz" 2> /dev/null | tail -1)
PACKAGE_FILE_NAME=$(echo "$SOURCE_PACKAGE_FILE"|sed 's|/tmp/||'|sed 's|.tar.gz||')

build_usage_tip() {
      cat <<EOF
=======================================================
        $EXT_NAME installer for Tiny Core Linux
             by phpdragon <phpdragon@qq.com>
         Updated by phpdragon <phpdragon@qq.com>
=======================================================

Before proceeding You must download ${SOURCE_PACKAGE:-/tmp/lrzsz-*.tar.gz}
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
gcc
make
glibc => glibc_base-dev
headers => linux-6.1_api_headers
==>
EOF
    tce-load -wi gcc make glibc_base-dev linux-6.1_api_headers || return 1
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
  ./configure --prefix=/usr/local
  make -j"${CORES_COUNT}"

  cd "/tmp/${PACKAGE_FILE_NAME}/src" || return 1

  mkdir -p "${SRC_USR_LOCAL_DIR}"
  mkdir -p "${SRC_USR_LOCAL_BIN_DIR}"
  mkdir -p "${SRC_USR_LOCAL_DIR}/man/man1/"
  mkdir -p "${EXT_OUT_PUT_DIR}"

  cp lrz lsz "${SRC_USR_LOCAL_BIN_DIR}"
  cd "${SRC_USR_LOCAL_BIN_DIR}" || return 1
  ln -s lrz lrb
  ln -s lrz lrx
  ln -s lrz rz
  ln -s lsz lsb
  ln -s lsz lsx
  ln -s lsz sz
  cd "/tmp/${PACKAGE_FILE_NAME}/man" || return 1
  cp lrz.1 lsz.1 "${SRC_USR_LOCAL_DIR}/man/man1/"

  rm -rf "/tmp/${PACKAGE_FILE_NAME}"

  return 0
}

get_pkg_info() {
    size=$(du -h "${EXT_OUT_PUT_FILE}"|awk '{print $1}')

    cat <<EOF
  Title:          ${TCZ_NAME}
  Description:    Free x/y/zmodem implementation
  Version:        0.12.20
  Author:         Chuck Forsberg, Matt Porter, mblack@csihq.com, Uwe Ohse
  Original-site:  https://www.ohse.de/uwe/software/lrzsz.html
  Copying-policy: GPL v2
  Size:           ${size}
  Extension_by:   phpdragon <phpdragon@qq.com>
  Tags:           CLI COMMUNICATION TERMINAL XMODEM ZMODEM YMODEM
  Comments:       Binaries only
                  ----
                  Compiled for Core ${OS_TRUNK_VERSION}.x
  Change-log:     ${CURRENT_DAY} Original for TC ${OS_TRUNK_VERSION}.x
  Current:        2016/04/02 First version, 0.12.20
EOF
}

build_result_tip(){
  echo ""
  cat <<EOF
${GREEN}Congratulations, All Done !${NORMAL}

EOF
}

main
