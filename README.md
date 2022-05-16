# GitLab 설치 가이드

## 구성 요소 및 버전
* gitlab ([gitlab/gitlab-ce:13.6.4-ce.0](https://hub.docker.com/layers/gitlab/gitlab-ce/13.6.4-ce.0/images/sha256-5c8937153d7d1373d6b2cbe6f3c5e4b80e85f13aa21c09261d7d02960d7bb774?context=explore))
* bitnami/kubectl ([bitnami/kubectl](https://hub.docker.com/layers/bitnami/kubectl/latest/images/sha256-c2844926575f75dcefbc67a1375531bcfaea07cd404e57bdc274380a513be2bd?context=explore))

## 폐쇄망 설치 가이드
설치를 진행하기 전 아래의 과정을 통해 필요한 이미지 및 yaml 파일을 준비한다.
1. 폐쇄망에서 설치하는 경우 사용하는 image repository에 Gitlab 설치 시 필요한 이미지를 push한다.
   * 작업 디렉토리 생성 및 환경 설정
   ```bash
   git clone https://github.com/tmax-cloud/install-gitlab.git -b argocd --single-branch
   cd install-gitlab/manifest
    
   ./installer.sh prepare-online
   ```

2. 폐쇄망 환경으로 전송
   ```bash
   # 생성된 파일 모두 SCP 또는 물리 매체를 통해 폐쇄망 환경으로 복사
   cd ../..
   scp -r install-gitlab <REMOTE_SERVER>:<PATH>
   ```

3. 위의 과정에서 생성한 tar 파일들을 폐쇄망 환경으로 이동시킨 뒤 사용하려는 registry에 이미지를 push한다.

    ```bash
    ./installer.sh prepare-offline
    ```

## 기본 가이드

### Keycloak 연동

1. 키클록에서 클라이언트 생성
- Name: `gitlab`
- Client-Protocol: `openid-connect`
- AccessType: `confidential`
- Valid Redirect URIs: `*`

2. 클라이언트 시크릿 복사
- `Client > gitlab > Credentials > Secret` 복사

3. TLS 시크릿 
   
     - **HyperAuth를 사용할 경우 HyperAuth 설치 시 마스터 노드들에 설치된 `/etc/kubernetes/pki/hypercloud-root-ca.crt` 인증서 사용**
     - gitlab.config에 파일경로 기입
     
     

### gitlab.config 설정

```config
# Image Registry
imageRegistry=                 # 폐쇄망 설정

NAMESPACE=gitlab-system
APP_NAME=gitlab
SERVICE_TYPE=Ingress

STORAGE=30Gi
RESOURCE_CPU=1
RESOURCE_MEM=8Gi

INGRESS_CLASS=nginx             # ex) nginx, nginx-shd
STORAGE_CLASS=nfs               # ex) nfs, csi-cephfs-sc

INGRESS_HOST=                   # http:// 또는 https:// 제외. 없으면 공백
EXTERNAL_URL=                   # http:// 또는 https:// 포함. 없으면 공백
TLS_SECRET=                     # 공인인증서 시크릿. 없으면 공백

# 최초 설치시, 공백 - HYPERAUTH 설치 이후 사용 가능함
KEYCLOAK_TLS_SECRET_NAME=			  # KEYCLOAK_ROOT_CA 시크릿 이름 설정  ex) gitlab-root-ca
KEYCLOAK_CERT_FILE=	  			   	# KEYCLOAK_ROOT_CA 파일 경로
KEYCLOAK_URL=				            # http:// 또는 https:// 포함. 없으면 공백
KEYCLOAK_CLIENT=				        # KEYCLOAK CLINET 이름.
KEYCLOAK_SECRET=				        # KEYCLOAK CONFIDENTIAL

# GITLAB 설정
GITLAB_PASSWORD=					      # root사용자 비밀번호
REPO_NAME=argocd-installer      # gitlab에 등록될 repository 이름
MANIFEST_PATH=								  # 업로드 할 폴더의 경로 
UPLOAD_PATH=								    # gitlab에 등록할 repository의 경로 설정 
# 주의: MANIFEST_PATH와 UPLOAD_PATH가 동일한 directory에 있는 것은 피해야함


```

## 설치 가이드

1. [GitLab 설치](#step-1-gitlab-설치)

## Step 1. GitLab 설치 및 manifest 업로드 
* 목적 : `GitLab에 필요한 구성 요소 설치 및 gitlab에 argocd manifest 업로드 `
* 생성 순서 : 아래 command로 설치 yaml 적용
   ```bash
   ./installer.sh install
   ```

## Step 2. OIDC연동

* 목적 : `GitLab OIDC (HPYERAUTH) 연동`

* 생성 순서 : gitlab.config에 KEYCLOAK 관련 정보 작성 이후, 아래 command로 설치 

  ```bash
  ./installer.sh integrate_OIDC
  ```

## Step 3. Ingress -traefik 설정

* 목적 : `GitLab ingress traefik 설정`

* 생성 순서 : gitlab.config에 ingress 관련 정보 작성 이후,  아래 command로 설치 

  ```bash
  ./installer.sh configure_ingress
  ```



## 삭제 가이드

1. [GitLab 삭제](#step-1-gitlab-삭제)

## Step 1. GitLab 삭제
* 목적 : `GitLab 구성 요소 삭제`
* 생성 순서 : 아래 command로 설치 yaml 삭제
   ```bash
   ./installer.sh unsinstall
   ```
   
   ---

# BACKUP 

## Step 1. 백업하기

```bash
kubectl exec -it -n {NS명} {POD명} gitlab-rake gitlab:backup:create
# ex) kubectl exec -it -n gitlab-system gitlab-5c59765867-rnp8v gitlab-rake gitlab:backup:create
```

## Step 2. 백업 파일 복사하기

```bash
kubectl cp {NS명}/{POD명}:var/opt/gitlab/backups/{BACKUP_TAR파일명} {복사할 위치/파일명.tar}
# ex) kubectl cp gitlab-system/gitlab-5c59765867-rnp8v:var/opt/gitlab/backups/1652685285_2022_05_16_13.6.4_gitlab_backup.tar ./test.tar
```

## Step 3. 시크릿 및 설정값 복사하기

```bash
kubectl exec -it -n {NS명} {POD명} -- tar cf - "etc/gitlab" | tar xf -

# ex) kubectl exec -n "gitlab-system" "gitlab-5c59765867-rnp8v" -- tar cf - "etc/gitlab" | tar xf -
```

## Step 4. Omnibus 세팅값 복사하기

```bash
kubectl exec -it -n {NS명} {POD명} -- tar cf - "tmp/shared" | tar xf -

# ex) kubectl exec -n "gitlab-system" "gitlab-5c59765867-rnp8v" -- tar cf - "tmp/shared" | tar xf -
```

---

# RESTORE

## Step 1. omnibus 세팅값 파드에 저장하기

```bash
kubectl cp tmp {NS명}/{파드명}:tmp
# ex) kubectl cp tmp/shared gitlab-system/gitlab-5c59765867-rnp8v:tmp
```

## Step 2. 시크릿 / 설정값  파드에 저장하기

```bash
kubectl cp etc/gitlab {NS명}/{파드명}:etc
# ex) kubectl cp etc/gitlab gitlab-system/gitlab-5c59765867-rnp8v:etc
```

## Step 3. 백업 파일 파드에 저장하기

```bash
kubectl cp "백업파일명" {NS명}/{파드명:var/opt/gitlab/backups
# ex) kubectl cp test.tar gitlab-system/gitlab-5c59765867-rnp8v:var/opt/gitlab/backups
```

## Step 4. Omnibus 세팅값 설정하기

```bash
kubectl exec -it -n {NS명} {pod명} bash
- export GITLAB_OMNIBUS_CONFIG="$(cat /tmp/shared/omnibus.env)"
- echo 'export GITLAB_OMNIBUS_CONFIG="$(cat /tmp/shared/omnibus.env)"' >> /root/.bashrc
- /assets/wrapper
```

## Step 5. 복구하기

```bash
kubectl exec -it -n {ns명} {pod명} gitlab-backup restore BACKUP=백업파일명
```

