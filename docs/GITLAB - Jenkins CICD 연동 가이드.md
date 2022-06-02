# GITLAB - Jenkins CICD 연동 가이드

## 01. Jenkins - Gitlab 연동 사전 준비 작업

- gitlab plugin 설치 - Dashboard - Plugin Manager

![004_젠킨스_깃랩플러그인설치](https://user-images.githubusercontent.com/25574165/171547940-67a66301-a1a2-4fb2-8164-d24553722207.PNG)

- gitlab 연동 정보 기입
  - Manage Credential - global Scope - add Credential - gitlab 정보 기입

![005_젠킨스_credential](https://user-images.githubusercontent.com/25574165/171548257-531b129d-731e-4024-a5cd-5e516b3c42fd.PNG)

![006_젠킨스_credential](https://user-images.githubusercontent.com/25574165/171548260-1fd6200c-832d-40b5-8c91-3dbaf9abb65d.PNG)

![007_젠킨스_credential](https://user-images.githubusercontent.com/25574165/171548253-3e255c25-2336-4dce-8a69-1d5732c29e77.PNG)


![008_젠킨스_credential](https://user-images.githubusercontent.com/25574165/171548255-8df2496f-4507-4b2c-bbae-dc0c36f8f900.PNG)

## 02. Jenkins 아이템 생성

- FreeStyle Project : jenkins 내 shell스크립트 사용 
- Pipeline : jenkins file 작성 통한 CI/CD 파이프라인 구축 

![000](https://user-images.githubusercontent.com/25574165/171548759-1be34290-17ee-4c06-b707-7a0136b594e4.PNG)

- FreeStyle 프로젝트로 진행할 경우
  - git 정보 기입 & 스크립트 작성

![Inked009_젠킨스_gitlab-연동_LI](https://user-images.githubusercontent.com/25574165/171549756-36561c02-f2a3-4df9-8dd9-a36da9d0bac1.jpg)

![script](https://user-images.githubusercontent.com/25574165/171549947-5d5ed3a3-740b-46de-bab7-d30cc6e36b54.PNG)

- Pipeline으로 생성할 경우
  - 스크립트를 jenkins 내 pipeline에서 작성하거나, git repo에 jenkins파일을 포함할 수 있다

![001](https://user-images.githubusercontent.com/25574165/171551774-3401b3bf-37e1-485c-a2de-9ae0b1b01b24.PNG)

![002](https://user-images.githubusercontent.com/25574165/171551835-a07b22c9-6e97-40df-b3d7-5377c56610d4.PNG)

- webhook 등록
  - build trigger - URL & 시크릿값을 gitlab webhook으로 등록

![003](https://user-images.githubusercontent.com/25574165/171552505-a83c6f51-1728-4e55-bae0-e7e71504f95f.PNG)
![004](https://user-images.githubusercontent.com/25574165/171552511-e935618c-b765-42dc-8609-f42e227e38e6.PNG)

![005](C:\Users\hayeo\Desktop\005.PNG)