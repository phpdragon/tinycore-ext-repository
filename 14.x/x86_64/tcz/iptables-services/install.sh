#!/bin/sh
#
#  Iptables-services installer for Tiny Core Linux
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

# iptables config files
SYSCTL_CONF="/etc/sysctl.conf"
IPTABLES_DATA="/etc/sysconfig/iptables"
IPTABLES_LAST_DATA="${IPTABLES_DATA}.save"
IPTABLES_CONFIG="${IPTABLES_DATA}-config"

# ip6tables config files
IP6TABLES_DATA="/etc/sysconfig/ip6tables"
IP6TABLES_LAST_DATA="${IP6TABLES_DATA}.save"
IP6TABLES_CONFIG="${IP6TABLES_DATA}-config"

IPTABLES_START_BIN="${TC_USR_LOCAL_ETC_INIT_DIR}/iptables"
IP6TABLES_START_BIN="${TC_USR_LOCAL_ETC_INIT_DIR}/ip6tables"

TMP_TCE_INSTALLED_FILE="${EXT_SRC_DIR}/${TCE_INSTALLED_DIR}/${EXT_NAME}"
TMP_IPTABLES_START_BIN="${EXT_SRC_DIR}/${IPTABLES_START_BIN}"
TMP_IP6TABLES_START_BIN="${EXT_SRC_DIR}/${IP6TABLES_START_BIN}"

usage_tip(){
    clear
    cat <<EOF
================================================================================================

Iptables-services installer for Tiny Core Linux
by phpdragon phpdragon@qq.com

================================================================================================

EOF
    # shellcheck disable=SC2039
    read -r -n 1 -p "Press any key to continue." -s
    echo ""
    echo ""
}

build_init() {
    tce-load -wi iptables || exit 1
    install_squashfs
    return 0
}

build_tcz() {
  mksquashfs "${EXT_SRC_DIR}" "${EXT_OUT_PUT_FILE}" || exit 1

  sudo chmod 775 "${TMP_IPTABLES_START_BIN}"
  sudo chmod 775 "${TMP_IP6TABLES_START_BIN}"
  sudo chmod 775 "${TMP_TCE_INSTALLED_FILE}"
  sudo chown -R "${TC_USER_AND_GROUP}" "${EXT_SRC_DIR}"

  size=$(du -h "${EXT_OUT_PUT_FILE}"|awk '{print $1}')

  echo 'iptables.tcz' > "${EXT_OUT_PUT_FILE}.dep"
  cat > "${EXT_OUT_PUT_FILE}.dep" <<EOF
${TCZ_NAME}
    iptables.tcz
       ipv6-netfilter-6.1.2-tinycore.tcz
EOF
  cat > "${EXT_OUT_PUT_FILE}.info" <<EOF
Title:          ${TCZ_NAME}
Description:    start and stop iptables firewall
Version:        1.0.0
Author:         Red Hat, Inc.
Original-site:  https://phpdragon.github.io/blog/
Copying-policy: GPL
Size:           ${size}
Extension_by:   phpdragon
Tags:           managing iptables firewall
Comments:       a script to manage the iptables firewall
                ----
                Start with ipv4: '/usr/local/etc/init.d/iptables start'
                Start with ipv6: '/usr/local/etc/init.d/ip6tables start'
                ----
                iptables data file: /etc/sysconfig/iptables,/etc/sysconfig/ip6tables
                iptables config file: /etc/sysconfig/iptables-config,/etc/sysconfig/ip6tables-config
                Dependency config file: /etc/sysctl.conf
                ----
Change-log:     2023/12/01 Original for TC 14.x
Current:        2023/12/01 Original for TC 14.x
EOF
  find "${EXT_SRC_DIR}" -not -type d | sed "s|${EXT_SRC_DIR}||g" > "${EXT_OUT_PUT_FILE}.list"
  cd "${EXT_OUT_PUT_DIR}" && md5sum "${TCZ_NAME}" > "${EXT_OUT_PUT_FILE}.md5.txt"
  cat > "${EXT_OUT_PUT_FILE}.tree" <<EOF
${TCZ_NAME}
    iptables.tcz
        ipv6-netfilter-6.1.2-tinycore.tcz
EOF

  sudo chmod 664 "${EXT_OUT_PUT_FILE}"*
  sudo chown "${TC_USER_AND_GROUP}" "${EXT_OUT_PUT_FILE}"*
  return 0
}

config_persistence() {
  if grep -q "^${SYSCTL_CONF}" "${TC_OPT_FILE_TOOL_LST}" \
                       && grep -q "^${IPTABLES_DATA}" "${TC_OPT_FILE_TOOL_LST}" \
                       && grep -q "^${IPTABLES_LAST_DATA}" "${TC_OPT_FILE_TOOL_LST}" \
                       && grep -q "^${IPTABLES_CONFIG}" "${TC_OPT_FILE_TOOL_LST}"; then
    return 0
  fi

  cat >> "${TC_OPT_FILE_TOOL_LST}" <<EOF
# iptables-services requires persistent config files: <<BEGIN
${SYSCTL_CONF}
${IPTABLES_DATA}
${IPTABLES_LAST_DATA}
${IPTABLES_CONFIG}
${IP6TABLES_DATA}
${IP6TABLES_LAST_DATA}
${IP6TABLES_CONFIG}
# <<END
EOF
    return $?
}

result_notice() {
  echo ""
  iptables_cmd_tip="${BLUE}${IPTABLES_START_BIN}${NORMAL}"
  cat <<EOF
${GREEN}Congratulations, All Done !${NORMAL}

The following file are added to tcz install config file "${TCE_ON_BOOT_FILE}":
${CYAN}${TCZ_NAME}${NORMAL}

then the following files are added to the persistent config file "${TC_OPT_FILE_TOOL_LST}":
${CYAN}${SYSCTL_CONF}${NORMAL}
${CYAN}${IPTABLES_DATA}${NORMAL}
${CYAN}${IPTABLES_LAST_DATA}${NORMAL}
${CYAN}${IPTABLES_CONFIG}${NORMAL}
${CYAN}${IP6TABLES_DATA}${NORMAL}
${CYAN}${IP6TABLES_LAST_DATA}${NORMAL}
${CYAN}${IP6TABLES_CONFIG}${NORMAL}

You must exec ${GREEN}"filetool.sh -b"${NORMAL} and ${YELLOW}reboot${NORMAL} for it to take effect.

${RED}Usage(ip6 please use ${BLUE}ip6tables${NORMAL}):
  sudo ${iptables_cmd_tip} ${MAGENTA}enable${NORMAL}   Enable the firewall service
  sudo ${iptables_cmd_tip} ${MAGENTA}disable${NORMAL}  Disable the firewall service
  sudo ${iptables_cmd_tip} ${MAGENTA}start${NORMAL}    Start the firewall service
  sudo ${iptables_cmd_tip} ${MAGENTA}status${NORMAL}   Checking firewall Status
  sudo ${iptables_cmd_tip} ${MAGENTA}stop${NORMAL}     Stop the firewall service
  sudo ${iptables_cmd_tip} ${MAGENTA}save${NORMAL}     Save firewall current configuration to /etc/sysconfig/iptables
                                                   and backup last configuration to /etc/sysconfig/iptables.last
  sudo ${iptables_cmd_tip} ${MAGENTA}reload${NORMAL}   Reload the firewall configuration
  ...                                          Details please see: /usr/local/etc/init.d/iptables

${RED}Native commands:${NORMAL}
  sudo ${BLUE}iptables${NORMAL} ${MAGENTA}-nv -L${NORMAL}   List firewall chain rules
  ...                    Please use command "iptables --help" to view details

EOF
}

main() {
  usage_tip
  build_clean
  build_init || exit 1
  create_tcz || exit 1
  install_tcz || exit 1
  config_persistence || exit 1
  build_clean "ask"
  result_notice
  ask_backup
}

main

