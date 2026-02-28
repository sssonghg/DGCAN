# DGCAN - 동국대 컴퓨터·AI학부 공지사항 앱

## 🚀 빠른 시작

### 1. 파이썬 서버 실행 (맥북)

```bash
# 프로젝트 루트 디렉토리에서
pip3 install -r requirements.txt

# 서버 실행
python3 server.py
```

서버가 `http://localhost:5000`에서 실행됩니다.

### 2. iOS 앱 실행

- Xcode에서 프로젝트 열기
- 시뮬레이터 또는 실기기에서 실행
- **학부 공지** 탭을 열면 자동으로 서버에서 공지사항을 가져옵니다

---

## 📱 실기기에서 테스트할 때

실기기에서 테스트하려면 **맥북의 로컬 IP 주소**를 사용해야 합니다:

1. **맥북 IP 확인**:
   ```bash
   ifconfig | grep "inet " | grep -v 127.0.0.1
   ```
   예: `192.168.0.100`

2. **`NoticeService.swift` 수정**:
   ```swift
   #else
   private let baseURL = "http://192.168.0.100:5000"  // 본인 맥북 IP로 변경
   #endif
   ```

3. **맥북과 실기기가 같은 Wi-Fi에 연결되어 있어야 합니다**

---

## 🔧 문제 해결

### "서버 연결 실패" 오류가 뜨는 경우

1. **서버가 실행 중인지 확인**:
   ```bash
   python3 server.py
   ```

2. **서버가 정상 작동하는지 확인**:
   브라우저에서 `http://localhost:5000/health` 접속 → `{"status":"ok"}` 나와야 함

3. **실기기 사용 시**: `NoticeService.swift`의 IP 주소가 올바른지 확인

### iOS에서 HTTP 접근 오류 (App Transport Security)

iOS는 기본적으로 HTTPS만 허용합니다. 로컬 개발을 위해 HTTP를 허용하려면:

1. Xcode에서 `Info.plist` 열기 (또는 프로젝트 설정 → Info 탭)
2. **App Transport Security Settings** 추가:
   - `Allow Arbitrary Loads` = `YES`
   - 또는 `Exception Domains`에 `localhost`, `192.168.x.x` 추가

---

## 📂 파일 구조

```
DGCAN/
├── server.py              # 파이썬 서버 (Flask)
├── requirements.txt       # 파이썬 패키지 목록
├── README.md              # 이 파일
└── DGCAN/
    └── DGCAN/
        ├── DeptNoticeView.swift    # 학부 공지 탭
        ├── NoticeService.swift     # 서버 통신 서비스
        ├── NoticeWebView.swift     # 웹뷰 (상세 페이지)
        └── ...
```

---

## 🎯 다음 단계 (푸시 알림 추가 시)

나중에 Apple Developer 가입 후 푸시 알림을 추가하려면:

1. Apple Developer에서 APNs 설정
2. `server.py`에 푸시 발송 로직 추가
3. iOS 앱에 푸시 알림 권한 요청 코드 추가

---

## 📝 API 엔드포인트

- `GET /notices` - 학부 공지 최신 10개 반환
- `GET /health` - 서버 상태 확인
