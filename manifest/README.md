# Installer 사용 방법

## 전체 설치
### 공통
1. gitlab.config 설정
    - imageRegistry: 레지스트리 주소 입력 (폐쇄망이 아닐 경우 빈 값으로 설정)
    - 각 모듈 버전: 설치할 모듈 버전 (버전 변경을 추천하지 않음)
### 폐쇄망일 경우
1. 온라인 환경에서 준비
   ```bash
   ./installer.sh prepare-online
   ```
2. 해당 폴더 (`./yaml`, `./tar` 포함) 폐쇄망 환경으로 복사
3. 실제 폐쇄망 환경에서 준비
   ```bash
   ./installer.sh prepare-offline
   ```
### 공통
```bash
./installer.sh install
```

## 전체 삭제
```bash
./installer.sh uninstall
```
