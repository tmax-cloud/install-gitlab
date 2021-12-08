#!/bin/bash

export kubectl_opt="-v=0"
[[ "$0" != "$BASH_SOURCE" ]] && export install_dir=$(dirname "$BASH_SOURCE") || export install_dir=$(dirname $0)
. "$install_dir/gitlab.config"

function get_resources(){
  kubectl get "$1" -A 2>/dev/null
}

function delete_resources(){
  header="$(get_resources "$1" | head -n 1)"
  if [[ "$header" == "" ]]; then
    kubectl delete crd "$1" "$kubectl_opt"
    return
  fi

  get_resources "$1" | tail -n +2 | while read line; do
    if [[ "$(echo "$header" | awk '{print $1}')" == "NAMESPACE" ]]; then
      ns="$(echo "$line" | awk '{print $1}')"
      name=$(echo "$line" | awk '{print $2}')

      kubectl -n "$ns" delete "$1" "$name" "$kubectl_opt"
    else
      name=$(echo "$line" | awk '{print $1}')

      kubectl delete "$1" "$name" "$kubectl_opt"
    fi
  done

  kubectl delete crd "$1" "$kubectl_opt"
}
