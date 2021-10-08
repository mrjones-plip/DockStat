#!/usr/bin/env bash

##########################################################
##                                                      ##
#    Helper script to show running Docker containers     #
#             and related Docker resources               #
##                                                      ##
##########################################################

get_load_avg() {
  # "system_profiler" exists only on MacOS, if it's not here, then run linux style command for
  # load avg.  Otherwise use MacOS style command
  if ! command -v "system_profiler" &>/dev/null; then
    awk '{ print  $1 " " $2 " " $3 }' </proc/loadavg
  else
    sysctl -n vm.loadavg
  fi
}

get_global_docker_process_count() {
  count=0
  containersArray=$(docker ps | awk '{if(NR>1) print $NF}')
  for container in $containersArray; do
    tmpCount=$(get_container_process_count "$container")
    count="$((tmpCount + count))"
  done
  echo "$count"
}

get_container_process_count(){
  container=$1
  echo $(docker top "${container}" | tail -n +2 | wc -l)
}

required_apps_installed(){
  error=''
  appString=$1
  IFS=';' read -ra appsArray <<<"$appString"
  for app in "${appsArray[@]}"; do
    if ! command -v "$app" &>/dev/null; then
      error="${app} ${error}"
    fi
  done
  echo "${error}"
}

# shellcheck disable=SC2046
. $(dirname $0)/simple_curses.sh

main() {

  declare -r APP_STRING="docker;docker-compose;awk;echo;ps;wc"

  # with constants set, let's ensure all the apps are present, exit if not
  appStatus=$(required_apps_installed "$APP_STRING")
  if [ -n "$appStatus" ]; then
    window "WARNING: Missing Apps" "red" "100%"
    append "Install before proceeding:"
    append "$appStatus"
    endwin
    set -e
    return 0
  fi

  containers=$(docker ps | awk '{if(NR>1) print $NF}')
  containerCount=$(docker ps | tail -n +2 | wc -l)

  networks=$(docker network ls --format '{{.Name}}')
  networkCount=$(docker network ls --format '{{.Name}}' | wc -l)

  images=$(docker image ls --format ' {{.Repository}}:{{.Tag}}')
  imageCount=$(docker image ls --format ' {{.Repository}}:{{.Tag}}' | wc -l)

  volumes=$(docker volume ls --format ' {{.Name}}')
  volumeCount=$(docker volume ls --format ' {{.Name}}' | wc -l)

  loadAvg=$(get_load_avg)
  globalProcessCount=$(ps aux | wc -l)
  dockerProcessCount=$(get_global_docker_process_count)

  window "DockStat" "green" "100%"
  append "Load Average $loadAvg"
  append "Processes: Global ($globalProcessCount) Docker ($dockerProcessCount)"
  endwin

  window "Running Containers ($containerCount)" "green" "100%"
  if [[ $containerCount -gt 0 ]]; then
    append_tabbed "NAME|IP|PORTS|STATE" 4 "|"
    for container in $containers; do
      processes=$( get_container_process_count "$container" )
      upSince=$(docker ps --format='{{.Status}}' -f="name=$container")
      ip=$(docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container")
      ports=$(docker inspect --format='{{range $p, $conf := .NetworkSettings.Ports}}{{(index $conf 0).HostPort}} > {{$p}} {{end}}' "$container")
      append_tabbed "$container|$ip|$ports|$upSince, $processes processes" 4 "|"
    done
  else
    append "No containers running"
  fi
  endwin

  move_up

  window "Networks ($networkCount)" "green" "50%"
  append "$networks"
  endwin

  col_right
  move_up

  window "Images ($imageCount)" "green" "50%"
  append "$images"
  endwin

  window "Volumes ($volumeCount)" "green" "50%"
  append "$volumes"
  endwin

}

main_loop -t 1.2 $@
