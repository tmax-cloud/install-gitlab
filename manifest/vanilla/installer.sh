#!/bin/bash
[[ "$0" != "$BASH_SOURCE" ]] && export install_dir=$(dirname "$BASH_SOURCE") || export install_dir=$(dirname $0)
. "$install_dir/gitlab.config"

function push_argoCD(){
  git --version 2>&1 >/dev/null
  GIT_IS_AVAILABLE=$?
  if [ $GIT_IS_AVAILABLE -ne 0 ]; then
    yum install git
  fi

  gitlab_host=$(kubectl -n "$NAMESPACE" get ingress "$APP_NAME"-ingress -o jsonpath='{.spec.rules[0].host}')
  gitlab_user="root"

  body_header=$(curl --insecure -c cookies.txt -i "https://${gitlab_host}/users/sign_in" -s)

  csrf_token=$(echo $body_header | perl -ne 'print "$1\n" if /new_user.*?authenticity_token"[[:blank:]]value="(.+?)"/' | sed -n 1p)

  curl --insecure -b cookies.txt -c cookies.txt -i "https://${gitlab_host}/users/sign_in" \
      --data "user[login]=${gitlab_user}&user[password]=${GITLAB_PASSWORD}" \
      --data-urlencode "authenticity_token=${csrf_token}"

  body_header=$(curl --insecure -H 'user-agent: curl --insecure' -b cookies.txt -i "https://${gitlab_host}/profile/personal_access_tokens" -s)
  csrf_token=$(echo $body_header | perl -ne 'print "$1\n" if /authenticity_token"[[:blank:]]value="(.+?)"/' | sed -n 1p)

  body_header=$(curl --insecure -L -b cookies.txt "https://${gitlab_host}/profile/personal_access_tokens" \
      --data-urlencode "authenticity_token=${csrf_token}" \
      --data 'personal_access_token[name]=golab-generated&personal_access_token[expires_at]=&personal_access_token[scopes][]=api')

  personal_access_token=$(echo $body_header | perl -ne 'print "$1\n" if /created-personal-access-token"[[:blank:]]value="(.+?)"/' | sed -n 1p)
  echo $personal_access_token

  # gitlab repository config
  repo_config=$(echo "{"name" : "$REPO_NAME"}")

  # Create gitlab repository
  curl --insecure https://$gitlab_host/api/v4/projects/ \
  -i \
  -X POST \
  -H "content-type:application/json" \
  -H "PRIVATE-TOKEN: $personal_access_token" \
  -d "$repo_config"
  echo "finish create repo"

  git clone "$GIT_URL$GIT_REPO.git"

  cd $install_dir/$GIT_REPO
  rm -rf .git
  cd ..
  mv $install_dir/$GIT_REPO $install_dir/temp


  # if using self-signed certificate, set sslVerify as false
  git config --global http.sslVerify false
  git clone https://$gitlab_user:$GITLAB_PASSWORD@$gitlab_host/$gitlab_user/$REPO_NAME.git
  cp -a $install_dir/temp/. $install_dir/$REPO_NAME
  cd $REPO_NAME
  git add .
  git commit -m "inital_commit"
  git push -u origin master
}

function integrate_OIDC(){
  echo  "========================================================================="
  echo  "========================  Integrate with OIDC =========================="
  echo  "========================================================================="

  cp "$install_dir/yaml/gitlab-deploy.yaml" "$install_dir/yaml/gitlab-deploy-modified.yaml"
  sed -i "s/@@NAMESPACE@@/$NAMESPACE/g" "$install_dir/yaml/gitlab-deploy-modified.yaml"
  sed -i "s/@@APP_NAME@@/$APP_NAME/g" "$install_dir/yaml/gitlab-deploy-modified.yaml"
  sed -i "s/@@STORAGE@@/$STORAGE/g" "$install_dir/yaml/gitlab-deploy-modified.yaml"
  sed -i "s/@@SERVICE_TYPE@@/$SERVICE_TYPE/g" "$install_dir/yaml/gitlab-deploy-modified.yaml"
  sed -i "s/@@GITLAB_PASSWORD@@/$GITLAB_PASSWORD/g" "$install_dir/yaml/gitlab-deploy-modified.yaml"
  sed -i "s/@@RESOURCE_CPU@@/$RESOURCE_CPU/g" "$install_dir/yaml/gitlab-deploy-modified.yaml"
  sed -i "s/@@RESOURCE_MEM@@/$RESOURCE_MEM/g" "$install_dir/yaml/gitlab-deploy-modified.yaml"
  sed -i "s/@@INGRESS_HOST@@/$INGRESS_HOST/g" "$install_dir/yaml/gitlab-deploy-modified.yaml"
  sed -i "s/@@INGRESS_CLASS@@/$INGRESS_CLASS/g" "$install_dir/yaml/gitlab-deploy-modified.yaml"
  sed -i "s/@@STORAGE_CLASS@@/$STORAGE_CLASS/g" "$install_dir/yaml/gitlab-deploy-modified.yaml"
  sed -i "s|@@EXTERNAL_URL@@|$EXTERNAL_URL|g" "$install_dir/yaml/gitlab-deploy-modified.yaml"
  sed -i "s/@@TLS_SECRET@@/$TLS_SECRET/g" "$install_dir/yaml/gitlab-deploy-modified.yaml"
  sed -i "s/@@KEYCLOAK_TLS_SECRET_NAME@@/$KEYCLOAK_TLS_SECRET_NAME/g" "$install_dir/yaml/gitlab-deploy-modified.yaml"
  sed -i "s/@@KEYCLOAK_CLIENT@@/$KEYCLOAK_CLIENT/g" "$install_dir/yaml/gitlab-deploy-modified.yaml"
  sed -i "s/@@KEYCLOAK_SECRET@@/$KEYCLOAK_SECRET/g" "$install_dir/yaml/gitlab-deploy-modified.yaml"
  sed -i "s|@@KEYCLOAK_URL@@|$KEYCLOAK_URL|g" "$install_dir/yaml/gitlab-deploy-modified.yaml"
  kubectl apply -f "$install_dir/yaml/gitlab-deploy-modified.yaml"

  echo "=== Waiting for GitLab's address to be ready... ==="
  TRIAL=0
  while true; do
    sleep 5s
    echo "Trial $TRIAL..."
    TRIAL=$((TRIAL+1))
    status=$(kubectl -n "$NAMESPACE" get pod -o jsonpath='{.items[0].status.containerStatuses[0].ready}')
    if [[ "$status" == "true" ]]; then
      URL=$(kubectl -n "$NAMESPACE" exec -t "$POD" -- cat /tmp/shared/omnibus.env 2>/dev/null | grep -oP "external_url '\K[^']*(?=')")
      echo "Access URL is $URL"
      export GITLAB_URL="$URL"
      break
    fi
  done
  echo  "========================================================================="
  echo  "====================  finish integrating with OIDC ====================="
  echo  "========================================================================="
}

function install(){
  echo  "========================================================================="
  echo  "=======================  Start Installing GitLab ========================"
  echo  "========================================================================="
  cp "$install_dir/yaml/gitlab.yaml" "$install_dir/yaml/gitlab_modified.yaml"
  sed -i "s/@@NAMESPACE@@/$NAMESPACE/g" "$install_dir/yaml/gitlab_modified.yaml"
  sed -i "s/@@APP_NAME@@/$APP_NAME/g" "$install_dir/yaml/gitlab_modified.yaml"
  sed -i "s/@@STORAGE@@/$STORAGE/g" "$install_dir/yaml/gitlab_modified.yaml"
  sed -i "s/@@SERVICE_TYPE@@/$SERVICE_TYPE/g" "$install_dir/yaml/gitlab_modified.yaml"
  sed -i "s/@@GITLAB_PASSWORD@@/$GITLAB_PASSWORD/g" "$install_dir/yaml/gitlab_modified.yaml"
  sed -i "s/@@RESOURCE_CPU@@/$RESOURCE_CPU/g" "$install_dir/yaml/gitlab_modified.yaml"
  sed -i "s/@@RESOURCE_MEM@@/$RESOURCE_MEM/g" "$install_dir/yaml/gitlab_modified.yaml"
  sed -i "s/@@INGRESS_HOST@@/$INGRESS_HOST/g" "$install_dir/yaml/gitlab_modified.yaml"
  sed -i "s/@@INGRESS_CLASS@@/$INGRESS_CLASS/g" "$install_dir/yaml/gitlab_modified.yaml"
  sed -i "s/@@STORAGE_CLASS@@/$STORAGE_CLASS/g" "$install_dir/yaml/gitlab_modified.yaml"
  sed -i "s|@@EXTERNAL_URL@@|$EXTERNAL_URL|g" "$install_dir/yaml/gitlab_modified.yaml"
  sed -i "s/@@TLS_SECRET@@/$TLS_SECRET/g" "$install_dir/yaml/gitlab_modified.yaml"
  sed -i "s/@@KEYCLOAK_TLS_SECRET_NAME@@/$KEYCLOAK_TLS_SECRET_NAME/g" "$install_dir/yaml/gitlab_modified.yaml"
  sed -i "s/@@KEYCLOAK_CLIENT@@/$KEYCLOAK_CLIENT/g" "$install_dir/yaml/gitlab_modified.yaml"
  sed -i "s/@@KEYCLOAK_SECRET@@/$KEYCLOAK_SECRET/g" "$install_dir/yaml/gitlab_modified.yaml"
  sed -i "s|@@KEYCLOAK_URL@@|$KEYCLOAK_URL|g" "$install_dir/yaml/gitlab_modified.yaml"

  kubectl apply -f "$install_dir/yaml/gitlab_modified.yaml"

  echo "=== Waiting for GitLab's address to be ready... ==="
  TRIAL=0
  while true; do
    sleep 5s
    echo "Trial $TRIAL..."
    TRIAL=$((TRIAL+1))
    status=$(kubectl -n "$NAMESPACE" get pod -o jsonpath='{.items[0].status.containerStatuses[0].ready}')
    if [[ "$status" == "true" ]]; then
      URL=$(kubectl -n "$NAMESPACE" exec -t "$POD" -- cat /tmp/shared/omnibus.env 2>/dev/null | grep -oP "external_url '\K[^']*(?=')")
      export GITLAB_URL="$URL"
      break
    fi
  done
  echo "start create repository and push argoCD manifests"
  push_argoCD
  echo  "========================================================================="
  echo  "====================  Successfully Installed GitLab ====================="
  echo  "========================================================================="
  echo "Access URL is $URL"

}

function uninstall(){
  echo  "========================================================================="
  echo  "======================  Start Uninstalling GitLab ======================="
  echo  "========================================================================="

  kubectl delete -f "$install_dir/yaml/gitlab_modified.yaml"

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
    integrate_OIDC)
      integrate_OIDC
      ;;
    *)
      echo "Usage: $0 [install|uninstall|integrate_OIDC]"
      ;;
  esac
}

main "$1"
