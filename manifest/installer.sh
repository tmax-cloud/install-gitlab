#!/bin/bash

[[ "$0" != "$BASH_SOURCE" ]] && export install_dir=$(dirname "$BASH_SOURCE") || export install_dir=$(dirname $0)

source "$install_dir/common.sh"

function prepare_online(){
  echo  "========================================================================="
  echo  "========================  Preparing for GitLab =========================="
  echo  "========================================================================="

  curl -s "https://raw.githubusercontent.com/tmax-cloud/catalog/$templateVersion/gitlab/template.yaml" -o "$install_dir/yaml/template.yaml"

  sudo docker pull "gitlab/gitlab-ce:13.6.4-ce.0"
  sudo docker pull "bitnami/kubectl:latest"
  sudo docker tag "gitlab/gitlab-ce:13.6.4-ce.0" "gitlab:13.6.4-ce.0"
  sudo docker tag "bitnami/kubectl:latest" "kubectl:latest"
  sudo docker save "gitlab:13.6.4-ce.0" > "$install_dir/tar/gitlab_13.6.4-ce.0.tar"
  sudo docker save "kubectl:latest" > "$install_dir/tar/kubectl_latest.tar"
}

function prepare_offline(){
  echo  "========================================================================="
  echo  "========================  Preparing for GitLab =========================="
  echo  "========================================================================="

  sudo docker load < "$install_dir/tar/gitlab_13.6.4-ce.0.tar"
  sudo docker load < "$install_dir/tar/kubectl_latest.tar"
  sudo docker tag "gitlab:13.6.4-ce.0" "$imageRegistry/gitlab:13.6.4-ce.0"
  sudo docker tag "kubectl:latest" "$imageRegistry/kubectl:latest"
  sudo docker push "$imageRegistry/gitlab:13.6.4-ce.0"
  sudo docker push "$imageRegistry/kubectl:latest"
}

function install(){
  echo  "========================================================================="
  echo  "=======================  Start Installing GitLab ========================"
  echo  "========================================================================="

  # Apply ClusterTemplate
  if [[ "$imageRegistry" == "" ]]; then
    kubectl apply -f "https://raw.githubusercontent.com/tmax-cloud/catalog/$templateVersion/gitlab/template.yaml" "$kubectl_opt"
  else
    cp "$install_dir/yaml/template.yaml" "$install_dir/yaml/template_modified.yaml"
    sed -i -E "s/gitlab\/gitlab-ce\:13.6.4-ce.0/$imageRegistry\/gitlab\:13.6.4-ce.0/g" "$install_dir/yaml/template_modified.yaml"
    sed -i -E "s/bitnami\/kubectl/$imageRegistry\/kubectl/g" "$install_dir/yaml/template_modified.yaml"
    kubectl apply -f "$install_dir/yaml/template_modified.yaml" "$kubectl_opt"
  fi

  # Apply TemplateInstance
  cp "$install_dir/yaml/instance.yaml" "$install_dir/yaml/instance_modified.yaml"

  sed -i "s/@@STORAGE_SIZE@@/$storageSize/g" "$install_dir/yaml/instance_modified.yaml"
  sed -i "s/@@SERVICE_TYPE@@/$serviceType/g" "$install_dir/yaml/instance_modified.yaml"
  sed -i "s|@@KEYCLOAK_URL@@|$authUrl|g" "$install_dir/yaml/instance_modified.yaml"
  sed -i "s/@@KEYCLOAK_CLIENT@@/$authClient/g" "$install_dir/yaml/instance_modified.yaml"
  sed -i "s/@@KEYCLOAK_SECRET@@/$authSecret/g" "$install_dir/yaml/instance_modified.yaml"

  kubectl apply -f "$install_dir/yaml/instance_modified.yaml" "$kubectl_opt"

  echo "=== Waiting for GitLab's address to be ready... ==="
  NAMESPACE=gitlab-system
  TRIAL=0
  while true; do
    sleep 5s
    echo "Trial $TRIAL..."
    TRIAL=$((TRIAL+1))

    POD=$(kubectl -n "$NAMESPACE" get pod | grep gitlab | awk '{print $1}')
    URL=$(kubectl -n "$NAMESPACE" exec -t "$POD" -- cat /tmp/shared/omnibus.env 2>/dev/null | grep -oP "external_url '\K[^']*(?=')")
    if [[ "$?" == "0" ]]; then
      echo "Access URL is $URL"
      export GITLAB_URL="$URL"
      break
    fi
  done

  echo "It can take several minutes until gitlab to be ready"

  echo  "========================================================================="
  echo  "====================  Successfully Installed GitLab ====================="
  echo  "========================================================================="
}

function uninstall(){
  echo  "========================================================================="
  echo  "======================  Start Uninstalling GitLab ======================="
  echo  "========================================================================="

  kubectl -n gitlab-system delete templateinstance gitlab "$kubectl_opt"
  kubectl delete namespace gitlab-system "$kubectl_opt"

  echo  "========================================================================="
  echo  "===================  Successfully Uninstalled GitLab ===================="
  echo  "========================================================================="
}

function main(){
  case "${1:-}" in
    install)
      install
      ;;
    uninstall)
      uninstall
      ;;
    prepare-online)
      prepare_online
      ;;
    prepare-offline)
      prepare_offline
      ;;
    *)
      echo "Usage: $0 [install|uninstall|prepare-online|prepare-offline]"
      ;;
  esac
}

main "$1"
