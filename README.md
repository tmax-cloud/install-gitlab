# GitLab 설치 가이드

## 개요

GitLab is a single application that spans the entire software development lifecycle

## 목적

사설 GitLab 설치 

## 구성 요소 및 버전

* gitlab ([gitlab/gitlab-ce:15.3.2-ce.0](https://hub.docker.com/layers/gitlab/gitlab-ce/15.3.2-ce.0/images/sha256-3ebdf9c85f8f78f058c4313eb9e222068410ce4cba269e7f22321e255fc3cf6d?context=explore))
* bitnami/kubectl ([bitnami/kubectl](https://hub.docker.com/layers/bitnami/kubectl/latest/images/sha256-c2844926575f75dcefbc67a1375531bcfaea07cd404e57bdc274380a513be2bd?context=explore))

## Prerequisite
* Template Operator

## 폐쇄망 설치 가이드
설치를 진행하기 전 아래의 과정을 통해 필요한 이미지 및 yaml 파일을 준비한다.
1. 폐쇄망에서 설치하는 경우 사용하는 image repository에 Gitlab 설치 시 필요한 이미지를 push한다.
    * 작업 디렉토리 생성 및 환경 설정
   ```bash
   git clone https://github.com/tmax-cloud/install-gitlab.git -b 15.3.2-ce.0 --single-branch
   cd install-gitlab/manifest
    
   ./installer.sh prepare-online
   ```

2. 폐쇄망 환경으로 전송
   ```bash
   # 생성된 파일 모두 SCP 또는 물리 매체를 통해 폐쇄망 환경으로 복사
   cd ../..
   scp -r install-gitlab <REMOTE_SERVER>:<PATH>
   ```

3. **(Keycloak 연동 시)**
    1. 키클록에서 클라이언트 생성
    - Name: `gitlab`
    - Client-Protocol: `openid-connect`
    - AccessType: `confidential`
    - Valid Redirect URIs: `*`

    2. 클라이언트 시크릿 복사
    - `Client > gitlab > Credentials > Secret` 복사

    3. TLS 시크릿 
       
         **HyperAuth를 사용할 경우 HyperAuth 설치 시 마스터 노드들에 설치된 `/etc/kubernetes/pki/hypercloud-root-ca.crt` 인증서 사용**
         
         ```bash
         KEYCLOAK_CERT_FILE=<인증서 파일 경로>
         KEYCLOAK_TLS_SECRET_NAME=<Keycloak TLS 인증서가 저장될 Secret 이름>
         
         kubectl create ns gitlab-system
         
         cat <<EOT | kubectl apply -n gitlab-system -f -
         apiVersion: v1
         kind: Secret
         metadata:
           name: $KEYCLOAK_TLS_SECRET_NAME
         type: kubernetes.io/tls
         data:
           tls.crt: $(cat $KEYCLOAK_CERT_FILE | base64 -w 0)
           tls.key: $(echo -n 'dummyKey' | base64 -w 0)
         EOT
         ```
         
         
    
4. gitlab.config 설정
   ```config
   imageRegistry=172.22.11.2:30500 # 레지스트리 주소 (폐쇄망 아닐 경우 빈 값으로 설정)
   
   # 아래는 Keycloak 연동시 기재 필요
   authUrl='https://172.22.22.2' # 키클록 URL (`http://`또는 `https://` 포함)
   authClient='gitlab' # 키클록 클라이언트 이름
   authSecret='*******' # 키클록 클라이언트 시크릿
   authTLSSecretName='gitlab-secret' # TLS 시크릿 이름
   custom_domain_name='tmaxcloud.org' #(`http://`또는 `https://`미포함)
   
   
   
   ```
   
5. 위의 과정에서 생성한 tar 파일들을 폐쇄망 환경으로 이동시킨 뒤 사용하려는 registry에 이미지를 push한다.
   ```bash
   ./installer.sh prepare-offline
   ```

## 설치 가이드
1. [GitLab 설치](#step-1-gitlab-설치)

## Step 1. GitLab 설치
* 목적 : `GitLab에 필요한 구성 요소 설치`
* 생성 순서 : 아래 command로 설치 yaml 적용
   ```bash
   ./installer.sh install
   ```


## 삭제 가이드
1. [GitLab 삭제](#step-1-gitlab-삭제)

## Step 1. GitLab 삭제
* 목적 : `GitLab 구성 요소 삭제`
* 생성 순서 : 아래 command로 설치 yaml 삭제
   ```bash
   ./installer.sh unsinstall
   ```

## root 비밀번호
username: root
password:
```bash
kubectl exec {gitlab-pod-name} -n gitlab-system -- grep 'Password:' /etc/gitlab/initial_root_password
```
