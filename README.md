# GitLab 설치 가이드

## 구성 요소 및 버전
* gitlab ([gitlab/gitlab-ce:13.6.4-ce.0](https://hub.docker.com/layers/gitlab/gitlab-ce/13.6.4-ce.0/images/sha256-5c8937153d7d1373d6b2cbe6f3c5e4b80e85f13aa21c09261d7d02960d7bb774?context=explore))
* bitnami/kubectl ([bitnami/kubectl](https://hub.docker.com/layers/bitnami/kubectl/latest/images/sha256-c2844926575f75dcefbc67a1375531bcfaea07cd404e57bdc274380a513be2bd?context=explore))

## Prerequisite
* Template Operator

## 폐쇄망 설치 가이드
설치를 진행하기 전 아래의 과정을 통해 필요한 이미지 및 yaml 파일을 준비한다.
1. 폐쇄망에서 설치하는 경우 사용하는 image repository에 Gitlab 설치 시 필요한 이미지를 push한다.
    * 작업 디렉토리 생성 및 환경 설정
   ```bash
   git clone https://github.com/tmax-cloud/install-gitlab.git -b 5.0 --single-branch
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

    3. TLS 시크릿 복사 (Keycloak이 self-signed 인증서를 사용할 경우)  
       - Keycloak이 클러스터 내부에 있을 경우  
         Keycloak 네임스페이스의 TLS 시크릿을 gitlab-system 네임스페이스로 복사
         ```bash
         KEYCLOAK_NS=<Keycloak 네임스페이스>
         KEYCLOAK_TLS_SECRET_NAME=<Keycloak TLS 인증서가 저장되어있는 Secret 이름>

         kubectl create ns gitlab-system
         kubectl -n "$KEYCLOAK_NS" get secret "$KEYCLOAK_TLS_SECRET_NAME" --export -o yaml | kubectl apply -n gitlab-system -f -
         ```
       - Keycloak이 외부에 있을 경우  
         해당 Keycloak의 public 인증서를 `data`>`tls.crt`에 넣어 Secret 생성
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
           tls.crt: $(cat -n $KEYCLOAK_CERT_FILE | base64 -w 0)
           tls.key: $(echo 'dummyKey' | base64 -w 0)
         EOT

         kubectl -n gitlab-system create secret tls "$KEYCLOAK_TLS_SECRET_NAME" --cert="$KEYCLOAK_CERT_FILE"
         ```

4. gitlab.config 설정
   ```config
   imageRegistry=172.22.11.2:30500 # 레지스트리 주소 (폐쇄망 아닐 경우 빈 값으로 설정)
   
   # 아래는 Keycloak 연동시 기재 필요
   authUrl='https://172.22.22.2' # 키클록 URL (`http://`또는 `https://` 포함)
   authClient='gitlab' # 키클록 클라이언트 이름
   authSecret='*******' # 키클록 클라이언트 시크릿
   authTLSSecretName='hyperauth-https' # 키클록 TLS 시크릿 이름
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
