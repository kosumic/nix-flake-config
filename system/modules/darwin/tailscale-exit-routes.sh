# shellcheck shell=bash
# The Darwin CLI daemon does not install usable exit-node defaults itself.
# Keep transport sockets on the physical interface, and send ordinary traffic
# through the selected exit node using two more-specific routes per family.
set -euo pipefail

cli=/run/current-system/sw/bin/tailscale
socket=/var/run/tailscaled.socket
lock=/var/run/tailscale-exit-routes.lock
if ! mkdir "$lock" 2>/dev/null; then
  previous=$(cat "$lock/pid" 2>/dev/null || true)
  if [[ -z "$previous" ]] || kill -0 "$previous" 2>/dev/null; then
    printf 'another route manager is running\n' >&2
    exit 1
  fi
  rm -f "$lock/pid"
  rmdir "$lock"
  mkdir "$lock"
fi
printf '%s\n' "$$" > "$lock/pid"
active=""
tunnel=""
owned_family=()
owned_prefix=()
saved_family=()
saved_gateway=()
saved_interface=()
saved_address=()
owned_scope=()

log() { printf '%s %s\n' "$(date -u +%FT%TZ)" "$*"; }

default_route() {
  /usr/sbin/netstat -rn -f "$1" | awk '
    $1 == "default" && $3 !~ /I/ && $4 !~ /^(utun|lo)/ {
      print $2, $4; exit
    }'
}

addresses() {
  /sbin/ifconfig "$1" 2>/dev/null | awk '$1 == "inet" || $1 == "inet6" {print $1, $2}'
}

cleanup() {
  local i family gateway iface current
  for ((i=${#owned_prefix[@]}-1; i>=0; i--)); do
    /sbin/route -n delete "-${owned_family[i]}" -net "${owned_prefix[i]}" -interface "$tunnel" >/dev/null 2>&1 || true
  done
  owned_family=(); owned_prefix=()
  for ((i=${#saved_family[@]}-1; i>=0; i--)); do
    family=${saved_family[i]}; gateway=${saved_gateway[i]}; iface=${saved_interface[i]}
    current=$(default_route "$family")
    # tailscaled's exit-node removal can delete the physical default. Restore
    # it only if none remains and the physical interface still has its address.
    if [[ -z "$current" && "$(addresses "$iface")" == "${saved_address[i]}" ]]; then
      /sbin/route -n add "-$family" default "$gateway" >/dev/null 2>&1 || true
    fi
    if [[ ${owned_scope[i]} == yes ]]; then
      /sbin/route -n delete "-$family" default "$gateway" -ifscope "$iface" >/dev/null 2>&1 || true
    fi
  done
  saved_family=(); saved_gateway=(); saved_interface=(); saved_address=(); owned_scope=()
  if [[ -n "$active" ]]; then log 'removed exit-node routes'; fi
  active=""; tunnel=""
}
trap 'cleanup; rm -f "$lock/pid"; rmdir "$lock"' EXIT
trap 'exit 0' TERM INT HUP

install_family() {
  local family=$1 physical=$2 gateway iface prefix owned=no
  local -a prefixes
  [[ -n "$physical" ]] || return 0
  read -r gateway iface <<< "$physical"
  if /usr/sbin/netstat -rn -f "$family" | awk '$1 ~ /\/1$/ {found=1} END {exit !found}'; then
    log "refusing pre-existing $family split-default routes"
    return 1
  fi
  if [[ "$family" == inet ]]; then
    prefixes=(0.0.0.0/1 128.0.0.0/1)
  else
    prefixes=(::/1 8000::/1)
  fi
  # IP_BOUND_IF/IPV6_BOUND_IF sockets used by tailscaled need this scoped
  # default; otherwise the new tunnel defaults recursively capture transport.
  if /sbin/route -n add "-$family" default "$gateway" -ifscope "$iface" >/dev/null 2>&1; then
    owned=yes
  else
    # Only reuse an existing scope when it has the expected gateway/interface.
    /usr/sbin/netstat -rn -f "$family" | awk -v g="$gateway" -v n="$iface" '
      $1 == "default" && $2 == g && $3 ~ /I/ && $4 == n {found=1}
      END {exit !found}' || return 1
  fi
  saved_family+=("$family"); saved_gateway+=("$gateway"); saved_interface+=("$iface")
  saved_address+=("$(addresses "$iface")"); owned_scope+=("$owned")
  for prefix in "${prefixes[@]}"; do
    # Refuse conflicting pre-existing routes. Never remove somebody else's route.
    /sbin/route -n add "-$family" -net "$prefix" -interface "$tunnel" >/dev/null 2>&1 || return 1
    owned_family+=("$family"); owned_prefix+=("$prefix")
  done
}

while :; do
  if ! status=$(timeout 5 "$cli" --socket="$socket" status --json 2>/dev/null); then
    cleanup
    sleep 3
    continue
  fi
  exit_id=$(jq -r 'if .BackendState == "Running" then .ExitNodeStatus.ID // "" else "" end' <<< "$status")
  ip=$(jq -r '.Self.TailscaleIPs[]? | select(contains(":") | not)' <<< "$status")
  device=$(/sbin/ifconfig | awk -v ip="$ip" '
    /^[^ \t]/ {device=$1; sub(/:$/, "", device)}
    $1 == "inet" && $2 == ip {print device; exit}')
  v4=$(default_route inet)
  v6=$(default_route inet6)
  # Retain a saved physical default if tailscaled briefly removed it while
  # changing exit nodes. cleanup restores it before the next installation.
  key="$exit_id|$device|$v4|$v6"
  if [[ -n "$active" ]]; then
    for family in "${saved_family[@]}"; do
      if ! /usr/sbin/netstat -rn -f "$family" | awk -v dev="$tunnel" '
        $1 ~ /\/1$/ && $4 == dev {count++} END {exit count != 2}'; then
        cleanup
        break
      fi
    done
  fi
  if [[ -z "$exit_id" || "$device" != utun* ]]; then
    cleanup
  elif [[ "$key" != "$active" ]]; then
    # Keep this headless host reachable on its physical LAN. Without this
    # preference tailscaled also captures connected LAN subnets on selection.
    if ! timeout 5 "$cli" --socket="$socket" set --exit-node-allow-lan-access=true; then
      log 'could not preserve exit-node LAN access; retrying'
      cleanup
      sleep 3
      continue
    fi
    cleanup
    v4=$(default_route inet); v6=$(default_route inet6)
    tunnel=$device
    if [[ -n "$v4" ]] && install_family inet "$v4" && install_family inet6 "$v6"; then
      active="$exit_id|$device|$v4|$v6"
      log "installed CLI exit-node routes via $device ($exit_id)"
    else
      log 'could not install exit-node routes; reverting owned routes'
      cleanup
    fi
  fi
  sleep 3
done
