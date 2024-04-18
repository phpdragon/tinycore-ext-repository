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

# shellcheck disable=SC2125
SOURCE_PACKAGE="/tmp/jdk-"*"u"*"-linux-${ARCH}.tar.gz"
# shellcheck disable=SC2012
SOURCE_PACKAGE_FILE=$(ls "/tmp/jdk-"*"u"*"-linux-${ARCH}.tar.gz" 2> /dev/null | tail -1)
PKG_VERSION=""

build_usage_tip(){
    clear
    cat <<EOF
=====================================================================================

Java installer for Tiny Core Linux
by Sercan Arslan <arslanserc@gmail.com>
Updated by phpdragon <phpdragon@qq.com>

=====================================================================================

Before proceeding You must download ${SOURCE_PACKAGE:-/tmp/jdk-*u*-linux-${ARCH}.tar.gz}
from $SITE
to /tmp directory !

EOF
    # shellcheck disable=SC2039
    read -r -n 1 -p "Press any key to continue... " -s
}

build_check(){
    [ -e "${SOURCE_PACKAGE_FILE}" ] || die "${SOURCE_PACKAGE} not found! exiting ..."
    return 0
}

build_env_init(){
    return 0
}

clean_src_files() {
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
  # cd $(pwd)
  cd "${CURRENT_DIR}" || return 1

  # tar zxf /tmp/jdk-*-linux-*.tar.gz -C src/usr/local/
  tar zxf "${SOURCE_PACKAGE_FILE}" -C "${SRC_USR_LOCAL_DIR}" || return 1
  # mv -f src/usr/local/jdk* src/usr/local/oracle-jdk
  mv "${SRC_USR_LOCAL_DIR}/jdk"* "${SRC_PKG_HOME}" || return 1

  # delete jdk unnecessary files
  #rm -r "${SRC_PKG_HOME}/jre"
  #rm -r "${SRC_PKG_HOME}/lib/desktop"
  unlink "${SRC_PKG_HOME}/src.zip"
  unlink "${SRC_PKG_HOME}/javafx-src.zip"
  find "${SRC_PKG_HOME}" -name '*\.bat' -delete

  # mkdir -p src/etc/profile.d
  mkdir -p "${SRC_TC_PROFILE_DIR}"
  # cat > /etc/profile.d/oracle-jdk.sh
  cat > "${SRC_TC_PROFILE_SH}" <<EOF
export JAVA_HOME="${PKG_HOME}"
export JRE_HOME="\${JAVA_HOME}/jre"
export CLASSPATH=.:\${JAVA_HOME}/lib:\${JRE_HOME}/lib
export PATH=\${JAVA_HOME}/bin:\$PATH

EOF

  # mkdir -p src/usr/local/tce.installed
  mkdir -p "${SRC_TCE_INSTALLED_DIR}"
  # cat > src/usr/local/tce.installed/oracle-jdk
  cat > "${SRC_TCE_INSTALLED_FILE}" <<EOF
#!/bin/sh

. ${TC_PROFILE_SH}
[ -e /lib64 ] || [ "\$(uname -m)" != "x86_64" ] || ln -s /lib /lib64

EOF

  return 0
}

get_pkg_info() {
  size=$(du -h "${EXT_OUT_PUT_FILE}"|awk '{print $1}')
  version="1.0.0"

  if [ -f "${SRC_PKG_HOME}/release" ]; then
    # shellcheck disable=SC2002
    version=$(cat "${SRC_PKG_HOME}/release"|grep 'JAVA_VERSION='|awk -F '"' '{print $2}')
  fi

  cat <<EOF
Title:          ${TCZ_NAME}
Description:    Oracle JDK
Version:        ${version}
Author:         Oracle
Original-site:  https://www.oracle.com/java/
Copying-policy: GPL
Size:           ${size}
Extension_by:   phpdragon <phpdragon@qq.com>
Tags:           Oracle JDK
Comments:
Change-log:     ${CURRENT_DAY} Original for TC ${OS_TRUNK_VERSION}.x
Current:        ${CURRENT_DAY} Original for TC ${OS_TRUNK_VERSION}.x
EOF
}

build_result_tip(){
  echo ""
  cat <<EOF
${GREEN}Congratulations, All Done !${NORMAL}

Environment variables are set in "${TC_PROFILE_SH}",
And add "${TCZ_NAME}" to "${TCE_ON_BOOT_FILE}"
For JAVA to be automatically added to PATH.

You must execute "${BLUE}source /etc/profile${NORMAL}" for it to take effect
on current session terminal ${YELLOW}or open new session terminal${NORMAL}.

Example:
    tc@~\$: source /etc/profile
    tc@~\$: java -version

EOF
}

main
