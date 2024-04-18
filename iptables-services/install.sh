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
#  Copyright (c) 2023 phpdragon <phpdragon@qq.com>
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

SRC_IPTABLES_START_BIN="${EXT_SRC_DIR}/${IPTABLES_START_BIN}"
SRC_IP6TABLES_START_BIN="${EXT_SRC_DIR}/${IP6TABLES_START_BIN}"

build_usage_tip(){
    clear
    cat <<EOF
================================================================================================

Iptables-services installer for Tiny Core Linux
by phpdragon <phpdragon@qq.com>

================================================================================================

EOF
    # shellcheck disable=SC2039
    read -r -n 1 -p "Press any key to continue... " -s
}

build_env_init() {
    return 0

    cat  <<EOF

+-----------------------------------------------------+
| Install the necessary dependent environments, list: |
+-----------------------------------------------------+
iptables
==>
EOF
    tce-load -wi iptabless || return 1
    cat <<EOF
-------------------------------------------------------

EOF
    return 0
}

build_env_init(){
    cat  <<EOF

+-----------------------------------------------------+
| Install the necessary dependent environments, list: |
+-----------------------------------------------------+
iptables
==>
EOF
    tce-load -wi iptables || return 1
    cat <<EOF
-------------------------------------------------------

EOF
    return 0
}

build_pkg_src() {
  sudo chmod 775 "${SRC_IPTABLES_START_BIN}"
  sudo chmod 775 "${SRC_IP6TABLES_START_BIN}"

  find "${EXT_SRC_DIR}" -type f -exec dos2unix {} \;

  return 0
}

get_pkg_info() {
  size=$(du -h "${EXT_OUT_PUT_FILE}"|awk '{print $1}')

  cat <<EOF
Title:          ${TCZ_NAME}
Description:    start and stop iptables firewall
Version:        1.0.0
Author:         Red Hat, Inc.
Original-site:  https://phpdragon.github.io/blog/
Copying-policy: GPL v2
Size:           ${size}
Extension_by:   phpdragon <phpdragon@qq.com>
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
Change-log:     ${CURRENT_DAY} Original for TC ${OS_TRUNK_VERSION}.x
Current:        ${CURRENT_DAY} Original for TC ${OS_TRUNK_VERSION}.x
EOF
}

get_pkg_dep() {
  echo 'iptables.tcz'
}

get_pkg_tree() {
  cat <<EOF
${TCZ_NAME}
    iptables.tcz
        ipv6-netfilter-6.1.2-tinycore.tcz
EOF
}

install_tcz_after() {
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

build_result_tip() {
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

build_finished() {
  ask_backup
}

main
