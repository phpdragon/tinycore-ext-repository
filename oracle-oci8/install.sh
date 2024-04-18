#!/bin/sh
#
#  Oracle oci8 installer for Tiny Core Linux
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
#  Copyright (c) 2023 phpdragon <phpdragon@qq.com>
#

HERE="$(cd $(dirname $0);pwd)"

# Source function library.
. "${HERE}/../functions"

check_not_root

# java architecture
SITE="https://www.oracle.com/database/technologies/instant-client/downloads.html"

PKG_HOME="${TC_USR_LOCAL_DIR}/${EXT_NAME}"
# shellcheck disable=SC2125
SOURCE_PACKAGE="/tmp/instantclient-"*"-linux."*".zip"
# shellcheck disable=SC2012
SOURCE_PACKAGE_FILES=$(ls "/tmp/instantclient-"*"-linux."*".zip" 2>/dev/null)

build_usage_tip(){
    clear
    cat <<EOF
=====================================================================================

Oracle oci8 installer for Tiny Core Linux
by phpdragon <phpdragon@qq.com>

=====================================================================================

Before proceeding You must download ${SOURCE_PACKAGE:-/tmp/instantclient-*-linux.*.zip}
from ${SITE}
to /tmp directory !

If you want to use this SQL*Plus command line tool,
Please also download instantclient-sqlplus-linux.*.zip.

EOF
    # shellcheck disable=SC2039
    read -r -n 1 -p "Press any key to continue... " -s
}

build_check(){
    [ -n "${SOURCE_PACKAGE_FILES}" ] || die "${SOURCE_PACKAGE} not found! exiting ..."
    return 0
}

build_env_init(){
    cat  <<EOF

+-----------------------------------------------------+
| Install the necessary dependent environments, list: |
+-----------------------------------------------------+
libaio
==>
EOF
    tce-load -wi libaio || return 1
    cat <<EOF
-------------------------------------------------------

EOF
    return 0
}

clean_src_files() {
  cd "${WORK_DIR}" || return 1

  # rm -rf src
  rm -rf "${EXT_SRC_DIR}"
}

clean_source_files() {
  if ask_clean_source_files "$1" ;then
    for file in ${SOURCE_PACKAGE_FILES} ; do
        rm -f "${file}"
    done
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
${SOURCE_PACKAGE_FILES}
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
  for file in ${SOURCE_PACKAGE_FILES} ; do
      unzip -o "${file}" -d "${SRC_USR_LOCAL_DIR}" || return 1
  done
  mv "${SRC_USR_LOCAL_DIR}/instantclient"* "${SRC_PKG_HOME}" || return 1


  # mkdir -p src/etc/profile.d
  mkdir -p "${SRC_TC_PROFILE_DIR}"
  # cat > /etc/profile.d/oracle-oci8.sh
  cat > "${SRC_TC_PROFILE_SH}" <<EOF
export ORACLE_CLIENT_HOME="${PKG_HOME}"
export LD_LIBRARY_PATH=\${ORACLE_CLIENT_HOME}:\$LD_LIBRARY_PATH
export NLS_LANG="AMERICAN_AMERICA.AL32UTF8"
export PATH=\${ORACLE_CLIENT_HOME}:\$PATH

EOF

  # mkdir -p src/usr/local/tce.installed
  mkdir -p "${SRC_TCE_INSTALLED_DIR}"
  # cat > src/usr/local/tce.installed/oracle-oci8
  cat > "${SRC_TCE_INSTALLED_FILE}" <<EOF
#!/bin/sh

. /etc/profile.d/oracle-oci8.sh
[ -e /lib64 ] || [ "\$(uname -m)" != "x86_64" ] || ln -s /lib /lib64
grep -q "^oracle-oci8" "/etc/ld.so.conf" || echo "${PKG_HOME}" >> /etc/ld.so.conf
ldconfig -q

EOF

  return 0
}

get_pkg_info() {
  size=$(du -h "${EXT_OUT_PUT_FILE}"|awk '{print $1}')
  version="1.0.0"

  readme="${SRC_PKG_HOME}/SQLPLUS_README"
  if [ -f "${readme}" ] ; then
    # shellcheck disable=SC2002
    version=$(cat "$readme"| grep 'Client Shared Library'|sed 's| ||g'|awk -F '-' '{print $3}')
  fi

  cat <<EOF
Title:          ${TCZ_NAME}
Description:    Oracle Instant Client
Version:        ${version}
Author:         Oracle
Original-site:  https://www.oracle.com/database/technologies/instant-client.html
Copying-policy: GPL
Size:           ${size}
Extension_by:   phpdragon <phpdragon@qq.com>
Tags:           Oracle OCI8
Comments:       Oracle Instant Client enables development and
                deployment of applications that connect to
                Oracle Database,either on-premise or in the Cloud.
Change-log:     ${CURRENT_DAY} Original for TC ${OS_TRUNK_VERSION}.x
Current:        ${CURRENT_DAY} Original for TC ${OS_TRUNK_VERSION}.x
EOF
}

get_pkg_dep() {
  echo 'libaio.tcz'
}

get_pkg_tree() {
  cat <<EOF
${TCZ_NAME}
    libaio.tcz
EOF
}

build_result_tip(){
  echo ""
  cat <<EOF
${GREEN}Congratulations, All Done !${NORMAL}

Environment variables are set in "${TC_PROFILE_SH}",
And added "${TCZ_NAME}" to "${TCE_ON_BOOT_FILE}",
Then added "${PKG_HOME}" to "/etc/ld.so.conf",
for oracle oci8 to be automatically added to PATH.

You must execute "${BLUE}source /etc/profile${NORMAL}" for it to take effect
on current session terminal ${YELLOW}or open new session terminal${NORMAL}.

Example:
    tc@~\$: source /etc/profile
    tc@~\$: sqlplus -V

EOF
}

main
