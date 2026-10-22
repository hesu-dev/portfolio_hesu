# 사진 교체

사진 앱의 보관함, 앨범 표지와 사진 상세 화면은 아래 PNG 파일을 공통으로 사용합니다.
기존 파일과 **같은 이름·경로·PNG 확장자**로 이미지를 덮어쓰면 코드 수정 없이 사진을 교체할 수 있습니다.
파일명은 `assets/photos/img1.png`부터 `assets/photos/img12.png`까지 사용합니다.
현재 이미지는 기존 앱의 그라데이션과 아이콘을 PNG로 옮긴 자리표시 이미지입니다.

```text
assets/photos/
├── img1.png
├── img2.png
├── img3.png
├── img4.png
├── img5.png
├── img6.png
├── img7.png
├── img8.png
├── img9.png
├── img10.png
├── img11.png
├── img12.png
└── README.md
```

| 파일 | 제목 | 앨범 |
| --- | --- | --- |
| img1.png | 오후의 커피 | 일상 |
| img2.png | 창가의 햇빛 | 일상 |
| img3.png | 저녁 식탁 | 일상 |
| img4.png | 오늘의 음악 | 일상 |
| img5.png | 작업 공간 | 작업 |
| img6.png | 프로토타입 | 작업 |
| img7.png | 아이디어 보드 | 작업 |
| img8.png | 릴리스 데이 | 작업 |
| img9.png | 푸른 해안 | 여행 |
| img10.png | 숲길 | 여행 |
| img11.png | 도시 산책 | 여행 |
| img12.png | 밤 기차 | 여행 |

- 앨범 표지: 일상 `img1.png`, 작업 `img5.png`, 여행 `img9.png`.
- 현재 이미지는 512 × 512px입니다. 다른 크기의 PNG도 사용할 수 있으며, 보관함과 앨범 표지는 정사각형으로 잘라 표시합니다.
- 사진 제목·날짜·앨범 구성은 `lib/portfolio/apps/photos_app.dart`의 `_galleryPhotos`에서 변경합니다.
- 파일 교체 후 실행 중인 앱을 완전히 재시작하거나 릴리스를 다시 빌드하면 반영됩니다.
- 웹 호스팅용 결과물은 `./deploy.sh 3`으로 다시 만듭니다. 이 명령은 Cloudflare에 업로드하지 않습니다.
- JPG 등 다른 형식의 사진은 PNG로 변환해서 넣습니다. 확장자만 바꾸는 방식은 피합니다.
