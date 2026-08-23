# 📚 초경량 로컬 독서 기록 앱 (Reading Record App)

> 서버가 100% 없는 온디바이스(On-device) 로컬 독서 기록 & 서재 관리 Flutter 애플리케이션입니다.  
> 사용자의 모든 데이터는 기기 로컬 Hive NoSQL 데이터베이스에만 안전하게 저장됩니다.

---

## ✨ 핵심 기능

1. **📖 내 로컬 서재 & 독서 관리**
   - 도서 등록, 수정, 삭제 및 완독 상태 관리
   - 실시간 검색 키워드 및 필터 탭 (전체 / 읽는 중 / 완독)
   - 부드러운 슬라이더 및 퀵 버튼(`-10p`, `-1p`, `+1p`, `+10p`) 독서 진행률 다이얼로그

2. **📝 독서 기록(노트) 타임라인 CRUD**
   - 특정 페이지별 인상 깊은 구절(발췌문)과 나의 생각/메모 기록
   - 페이지 번호순(오름차순) ⇄ 최신 작성일자순(내림차순) 정렬 토글
   - 독서 기록 작성 시 도서 진행 페이지 자동 동기화
   - 도서 삭제 시 종속된 독서 노트 일괄 캐스케이드 삭제(무결성 보장)

3. **🌐 외부 Open API 온라인 도서 검색 (Zero-Config)**
   - API 키 발급이 필요 없는 공개 Google Books & Open Library Open API 연동
   - 키워드(제목, 저자, ISBN) 검색으로 표지 이미지, 출판사, 페이지 수 자동 완성
   - 검색 결과에서 **'원터치 내 서재에 담기'** 및 **'수정 후 등록'** 지원

4. **📊 독서 통계 & 리포트 대시보드**
   - 총 등록 도서, 완독률(%), 누적 읽은 페이지, 작성된 노트 수, 평균 별점
   - 완독 진행 상태 비율 게이지 바
   - 최근 6개월 완독 권수 추이 막대 그래프 차트
   - 평점 4.0 이상 인생 도서 하이라이트

5. **💾 100% 온디바이스 JSON 백업 및 복원**
   - 모든 도서 및 독서 노트를 표준 JSON 스키마로 원터치 클립보드 복사/내보내기
   - 백업된 JSON 데이터를 붙여넣어 병합(Merge) 또는 덮어쓰기(Overwrite) 복원

---

## 🛠 기술 스택 및 아키텍처

- **Framework**: Flutter (Material 3)
- **State Management**: Flutter Riverpod (`StateNotifier`, `StreamProvider`, `family`, `autoDispose`)
- **Local Database**: Hive / Hive Flutter (NoSQL Key-Value with TypeAdapters)
- **Networking**: `http` (Google Books API & Open Library API)
- **Architecture**: Clean Layered Architecture (Domain / Data / Presentation / Core)

```
lib/
├── core/
│   ├── constants/app_constants.dart          # Hive Box Name, TypeID 상수
│   ├── database/hive_service.dart            # 로컬 NoSQL Hive DB 초기화 및 시딩
│   └── theme/app_theme.dart                  # Material 3 디자인 시스템
├── data/
│   ├── models/
│   │   ├── book_model.dart                   # 도서 엔티티 (Hive TypeAdapter)
│   │   ├── note_model.dart                   # 독서 노트 엔티티 (외래키 참조)
│   │   └── book_search_result.dart           # Open API 검색 DTO
│   ├── repositories/
│   │   ├── hive_book_repository.dart         # Hive 기반 도서 CRUD & 실시간 스트림
│   │   └── hive_note_repository.dart         # Hive 기반 노트 CRUD & 캐스케이드 삭제
│   └── services/
│       ├── book_search_service.dart          # Google Books & Open Library 검색 연동
│       └── backup_service.dart               # JSON 백업 생성 및 복원 엔진
├── domain/
│   └── repositories/
│       ├── book_repository.dart              # 추상 도서 리포지토리 인터페이스
│       └── note_repository.dart              # 추상 노트 리포지토리 인터페이스
├── presentation/
│   ├── controllers/
│   │   ├── book_controller.dart              # 도서 상태 관리 StateNotifier
│   │   ├── note_controller.dart              # 노트 상태 관리 StateNotifier
│   │   ├── book_search_controller.dart       # 온라인 검색 StateNotifier
│   │   └── backup_controller.dart            # 백업/복원 StateNotifier
│   ├── screens/
│   │   ├── main_navigation_screen.dart       # 3-Tab 메인 뷰
│   │   ├── home_screen.dart                  # 내 서재 & 필터 목록 화면
│   │   ├── book_detail_screen.dart           # 도서 상세 & 독서 노트 타임라인
│   │   ├── stats_dashboard_screen.dart       # 독서 통계 & 월별 차트 대시보드
│   │   └── settings_backup_screen.dart       # 설정 & JSON 백업/복원 화면
│   └── widgets/
│       ├── book_card.dart                    # 서재 도서 카드 (커버, 프로그레스 바)
│       ├── book_form_dialog.dart             # 도서 등록/수정 바텀시트
│       ├── book_search_dialog.dart           # 온라인 도서 검색 & 즉시 담기 모달
│       ├── note_card.dart                    # 인용구 박스 & 메모 타임라인 카드
│       ├── note_form_dialog.dart             # 독서 노트 작성/수정 바텀시트
│       ├── reading_progress_dialog.dart      # 슬라이더 & 퀵 버튼 진행률 다이얼로그
│       └── stats_header.dart                 # 서재 상단 독서 여정 통계 배너
├── providers/repository_providers.dart       # Riverpod 글로벌 DI 및 반응형 스트림
└── main.dart                                 # ProviderScope & 초기화 진입점
```

---

## 🚀 실행 방법

```bash
# 1. 의존성 설치
flutter pub get

# 2. Hive TypeAdapter 코드 생성 (필요 시)
dart run build_runner build --delete-conflicting-outputs

# 3. 앱 실행
flutter run
```
