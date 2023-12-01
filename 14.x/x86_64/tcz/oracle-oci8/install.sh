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
#  Copyright (c) 2023 phpdragon phpdragon@qq.com
#

HERE="$(cd $(dirname $0);pwd)"

# Source function library.
. "${HERE}/../functions"

check_not_root

# java architecture
SITE="https://www.oracle.com/database/technologies/instant-client/downloads.html"

OCI8_HOME="${TC_USR_LOCAL_DIR}/${EXT_NAME}"
# shellcheck disable=SC2125
OCI8_SOURCE_PACKAGE="/tmp/instantclient-"*"-linux."*".zip"
# shellcheck disable=SC2012
OCI8_SOURCE_PACKAGE_FILES=$(ls "/tmp/instantclient-"*"-linux."*".zip" 2>/dev/null)

# extensions to be created
OCI8_PROFILE_SH="${TC_PROFILE_DIR}/${EXT_NAME}.sh"
TMP_TC_PROFILE_SH="${EXT_SRC_DIR}${OCI8_PROFILE_SH}"
TMP_TCE_INSTALLED_FILE="${EXT_SRC_DIR}${TCE_INSTALLED_DIR}/${EXT_NAME}"
TMP_TC_USR_LOCAL_DIR="${EXT_SRC_DIR}${TC_USR_LOCAL_DIR}"
TMP_OCI8_HOME="${EXT_SRC_DIR}/${OCI8_HOME}"

usage_tip(){
    clear
    cat <<EOF
=====================================================================================

Oracle oci8 installer for Tiny Core Linux
by phpdragon phpdragon@qq.com

=====================================================================================

Before proceeding You must download ${OCI8_SOURCE_PACKAGE:-/tmp/instantclient-*-linux.*.zip}
from $SITE
to /tmp directory !

If you want to use this SQL*Plus command line tool,
Please also download instantclient-sqlplus-linux.*.zip.

EOF
    # shellcheck disable=SC2039
    read -r -n 1 -p "Press any key to continue." -s
    echo ""
    echo ""
}

build_check(){
    [ -n "${OCI8_SOURCE_PACKAGE_FILES}" ] || die "${OCI8_SOURCE_PACKAGE} not found! exiting ..."
    return 0
}

build_init(){
    tce-load -wi libaio || exit 1
    install_squashfs
    return 0
}

clean_build_files() {
  rm -rf "${TMP_OCI8_HOME}"
  build_clean "$1"
}

build_unpack() {
  for file in ${OCI8_SOURCE_PACKAGE_FILES} ; do
      unzip -o "${file}" -d "${TMP_TC_USR_LOCAL_DIR}" || return 1
  done
  mv -f "${TMP_TC_USR_LOCAL_DIR}/instantclient"* "${TMP_OCI8_HOME}" || return 1
  return 0
}

unpack_oci_package(){
  # shellcheck disable=SC2039
  echo -e "Unpacking oracle oci8 source package... \c"
  build_unpack >> "${LOG}" 2>&1
  # shellcheck disable=SC2181
  if [ $? -gt 0 ]
  then
       echo "failed !"
       echo "See ${LOG} for details"
       return 1
  else
      echo "successful ! "
      return 0
  fi
}

build_tcz() {
  # shellcheck disable=SC2164
  cd "${WORK_DIR}"

  sudo chmod 775 "${TMP_TC_PROFILE_SH}"
  sudo chmod 775 "${TMP_TCE_INSTALLED_FILE}"
  sudo chown -R "${TC_USER_AND_GROUP}" "${EXT_SRC_DIR}"

  mksquashfs "${EXT_SRC_DIR}" "${EXT_OUT_PUT_FILE}" || return 1

  size=$(du -h "${EXT_OUT_PUT_FILE}"|awk '{print $1}')

  echo 'libaio.tcz' > "${EXT_OUT_PUT_FILE}.dep"
  cat > "${EXT_OUT_PUT_FILE}.info" <<EOF
Title:          ${TCZ_NAME}
Description:    Oracle Instant Client
Version:        1.0.0
Author:         Oracle
Original-site:  https://www.oracle.com/database/technologies/instant-client.html
Copying-policy: GPL
Size:           ${size}
Extension_by:   phpdragon
Tags:           Oracle OCI8
Comments:       Oracle Instant Client enables development and
                deployment of applications that connect to
                Oracle Database,either on-premise or in the Cloud.
Change-log:     2023/12/01 Original for TC 14.x
Current:        2023/12/01 Original for TC 14.x
EOF
  find "${EXT_SRC_DIR}" -not -type d | sed "s|${EXT_SRC_DIR}||g" > "${EXT_OUT_PUT_FILE}.list"
  cd "${EXT_OUT_PUT_DIR}" && md5sum "${TCZ_NAME}" > "${EXT_OUT_PUT_FILE}.md5.txt"
  cat > "${EXT_OUT_PUT_FILE}.tree" <<EOF
${TCZ_NAME}
    libaio.tcz
EOF

  sudo chmod 664 "${EXT_OUT_PUT_FILE}"*
  sudo chown "${TC_USER_AND_GROUP}" "${EXT_OUT_PUT_FILE}"*

  [ -f "${EXT_OUT_PUT_FILE}" ] || return 1

  return 0
}

result_notice(){
  echo ""
  cat <<EOF
${GREEN}Congratulations, All Done !${NORMAL}

Environment variables are set in "${OCI8_PROFILE_SH}",
And added "${TCZ_NAME}" to "${TCE_ON_BOOT_FILE}",
Then added "${OCI8_HOME}" to "/etc/ld.so.conf",
for oracle oci8 to be automatically added to PATH.

You must execute "${BLUE}source /etc/profile${NORMAL}" for it to take effect
on current session terminal ${YELLOW}or open new session terminal${NORMAL}.

Example:
    tc@~\$: source /etc/profile
    tc@~\$: sqlplus -V

EOF
}

main() {
    clean_build_files
    usage_tip
    build_check || exit 1
    build_init || exit 1
    unpack_oci_package || exit 1
    create_tcz || exit 1
    install_tcz || exit 1
    clean_build_files "ask"
    result_notice
    exit 0
}

main
