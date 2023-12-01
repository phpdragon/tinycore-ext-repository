#!/bin/sh
#
#  Java installer for Tiny Core Linux
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
#  Copyright (c) 2012 Sercan Arslan <arslanserc@gmail.com>
#  Updated by phpdragon phpdragon@qq.com
#

HERE="$(cd $(dirname $0);pwd)"

# Source function library.
. "${HERE}/../functions"

check_not_root

# java architecture
ARCH=$(case $(uname -m) in *64) echo 'x64';; *) echo 'i586';; esac)
SITE="https://www.oracle.com/java/technologies/downloads/archive/#JavaSE"

# JAVA_HOME="/usr/local/java"
JAVA_HOME="${TC_USR_LOCAL_DIR}/${EXT_NAME}"
# shellcheck disable=SC2125
JAVA_SOURCE_PACKAGE="/tmp/jdk-"*"u"*"-linux-${ARCH}.tar.gz"
# shellcheck disable=SC2012
JAVA_SOURCE_PACKAGE_FILE=$(ls "/tmp/jdk-"*"u"*"-linux-${ARCH}.tar.gz" 2> /dev/null | tail -1)

# extensions to be created
JDK_PROFILE_SH="${TC_PROFILE_DIR}/${EXT_NAME}.sh"

TMP_TC_PROFILE_SH="${EXT_SRC_DIR}${JDK_PROFILE_SH}"
TMP_TCE_INSTALLED_FILE="${EXT_SRC_DIR}${TCE_INSTALLED_DIR}/${EXT_NAME}"

TMP_TC_USR_LOCAL_DIR="${EXT_SRC_DIR}${TC_USR_LOCAL_DIR}"
TMP_JAVA_HOME="${EXT_SRC_DIR}/${JAVA_HOME}"

usage_tip(){
    clear
    cat <<EOF
=====================================================================================

Java installer for Tiny Core Linux
by Sercan Arslan <arslanserc@gmail.com>
Updated by phpdragon phpdragon@qq.com

=====================================================================================

Before proceeding You must download ${JAVA_SOURCE_PACKAGE:-/tmp/jdk-*u*-linux-${ARCH}.tar.gz}
from $SITE
to /tmp directory !

EOF
    # shellcheck disable=SC2039
    read -r -n 1 -p "Press any key to continue." -s
    echo ""
    echo ""
}

build_check(){
    [ -e "${JAVA_SOURCE_PACKAGE_FILE}" ] || die "${JAVA_SOURCE_PACKAGE} not found! exiting ..."
    return 0
}

build_init(){
    install_squashfs
    return 0
}

clean_build_files() {
  # rm -rf oracle-jdk/usr/local/java
  rm -rf "${TMP_JAVA_HOME}"
  build_clean "$1"
}

build_unpack() {
  # tar zxf jdk-*-linux-*.tar.gz -C jdk/usr/local/
  tar zxf "${JAVA_SOURCE_PACKAGE_FILE}" -C "${TMP_TC_USR_LOCAL_DIR}" || return 1
  # mv -f jdk/usr/local/jdk* jdk/usr/local/java
  mv -f "${TMP_TC_USR_LOCAL_DIR}/jdk"* "${TMP_JAVA_HOME}" || return 1
  return 0
}

unpack_jdk_package(){
  # shellcheck disable=SC2039
  echo -e "Unpacking JavaSE source package... \c"
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

  # delete jdk unnecessary files
  #rm -r "${TMP_JAVA_HOME}/jre"
  #rm -r "${TMP_JAVA_HOME}/lib/desktop"
  unlink "${TMP_JAVA_HOME}/src.zip"
  unlink "${TMP_JAVA_HOME}/javafx-src.zip"
  find "${TMP_JAVA_HOME}" -name '*\.bat' -delete

  sudo chmod 775 "${TMP_TC_PROFILE_SH}"
  sudo chmod 775 "${TMP_TCE_INSTALLED_FILE}"
  sudo chown -R "${TC_USER_AND_GROUP}" "${EXT_SRC_DIR}"

  mksquashfs "${EXT_SRC_DIR}" "${EXT_OUT_PUT_FILE}" || return 1

  size=$(du -h "${EXT_OUT_PUT_FILE}"|awk '{print $1}')

  cat > "${EXT_OUT_PUT_FILE}.info" <<EOF
Title:          ${TCZ_NAME}
Description:    Oracle JDK
Version:        1.0.0
Author:         Oracle
Original-site:  https://www.oracle.com/java/
Copying-policy: GPL
Size:           ${size}
Extension_by:   phpdragon
Tags:           Oracle JDK
Comments:
Change-log:     2023/12/01 Original for TC 14.x
Current:        2023/12/01 Original for TC 14.x
EOF
  find "${EXT_SRC_DIR}" -not -type d | sed "s|${EXT_SRC_DIR}||g" > "${EXT_OUT_PUT_FILE}.list"
  cd "${EXT_OUT_PUT_DIR}" && md5sum "${TCZ_NAME}" > "${EXT_OUT_PUT_FILE}.md5.txt"

  sudo chmod 664 "${EXT_OUT_PUT_FILE}"*
  sudo chown "${TC_USER_AND_GROUP}" "${EXT_OUT_PUT_FILE}"*

  # [ -f oracle-jdk.tcz ]
  [ -f "${EXT_OUT_PUT_FILE}" ] || return 1

  return 0
}

result_notice(){
  echo ""
  cat <<EOF
${GREEN}Congratulations, All Done !${NORMAL}

Environment variables are set in "${JDK_PROFILE_SH}",
And add "${TCZ_NAME}" to "${TCE_ON_BOOT_FILE}"
For JAVA to be automatically added to PATH.

You must execute "${BLUE}source /etc/profile${NORMAL}" for it to take effect
on current session terminal ${YELLOW}or open new session terminal${NORMAL}.

Example:
    tc@~\$: source /etc/profile
    tc@~\$: java -version

EOF
}

main() {
    clean_build_files
    usage_tip
    build_check || exit 1
    build_init || exit 1
    unpack_jdk_package || exit 1
    create_tcz || exit 1
    install_tcz || exit 1
    clean_build_files "ask"
    result_notice
    exit 0
}

main
