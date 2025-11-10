# v2 Changelog

v2 최적화 버전의 변경 사항을 기록합니다.

---

## v0.2.0-beta (2025-11-09)

### 🎉 신규 명령어

#### `/dailyreview-v2`
- **80% 짧은 출력**: ~50줄 → ~10줄
- **85% 적은 승인**: 8-14회 → 1-3회
- **73% 빠른 실행**: ~30초 → ~8초

**새로운 기능:**
- 3단계 출력 모드
  - 기본: 10줄 간결 요약
  - `--brief`: 3줄 초간결
  - `--full`: v1 수준 상세 정보
- 통합 Git 명령 (1회 호출로 모든 정보 수집)
- 개선된 에러 처리 (Git 명령어 파싱 오류 방지)

#### `/todo-v2`
- **70% 짧은 출력**: ~70줄 → ~15줄
- **60% 적은 승인**: 10-14회 → 3-5회
- **50% 빠른 실행**: ~20초 → ~10초

**새로운 기능:**
- 3단계 출력 모드
  - 기본: 파일:라인만 표시
  - `--brief`: 2줄 통계
  - `--priority-only`: 긴급만
  - `--full`: v1 수준 (코드 블록 포함)
- Task 에이전트 활용 가능 (복잡한 경우)
- 병렬 검색 최적화

---

## 📊 성능 비교표

### /dailyreview

| 지표 | v1 | v2 (기본) | v2 (--brief) | 개선율 |
|------|----|-----------|--------------|----|
| 출력 줄 수 | ~50줄 | ~10줄 | ~3줄 | 80-94% ↓ |
| Accept 요청 | 8-14회 | 1-3회 | 1회 | 85-93% ↓ |
| 실행 시간 | ~30초 | ~8초 | ~5초 | 73-83% ↓ |
| Git 명령 수 | 8회 | 1회 | 1회 | 88% ↓ |

### /todo

| 지표 | v1 | v2 (기본) | v2 (--brief) | 개선율 |
|------|----|-----------|--------------|----|
| 출력 줄 수 | ~70줄 | ~15줄 | ~2줄 | 70-97% ↓ |
| Accept 요청 | 10-14회 | 3-5회 | 1-2회 | 60-85% ↓ |
| 실행 시간 | ~20초 | ~10초 | ~5초 | 50-75% ↓ |
| 코드 블록 | 모든 항목 | 없음 | 없음 | N/A |

---

## 🔧 기술적 개선사항

### dailyreview-v2

**Before (v1)**:
```bash
# 8번의 독립적인 Git 명령어 실행
git rev-parse --is-inside-work-tree
git log --since="today 00:00" ...
git show --stat commit1
git show --stat commit2
git diff --shortstat ...
# ... (계속)
```

**After (v2)**:
```bash
# 1번의 통합 Git 명령어 실행
git log --since="today 00:00" \
  --pretty=format:"COMMIT:%H|%ai|%s|%an" \
  --stat \
  --no-merges \
  --max-count=20
```

### todo-v2

**Before (v1)**:
```bash
# 순차적 검색 (14회 도구 호출)
Grep "TODO|FIXME..." (type: ts)
Grep "TODO|FIXME..." (type: js)
Grep "console.log..." (type: ts)
Grep "console.log..." (type: js)
# ... (각각 독립 실행)
```

**After (v2)**:
```bash
# 통합 검색 또는 Task 에이전트 위임
# 복잡한 경우: Task 에이전트에 병렬 검색 위임
# 단순한 경우: 통합 Grep 3-5회
```

---

## 📝 출력 포맷 변경

### dailyreview-v2 (기본 모드)

**Before (v1 - 50줄)**:
```markdown
# 📅 Daily Review - 2025년 11월 9일

## 🎯 오늘의 활동 요약
- **총 커밋**: 2개
- **변경 파일**: 7개
...

## 📝 커밋 타임라인
[상세 파일 목록]
...

## 💡 주요 작업 패턴
[상세 분석]
...

## 📊 파일별 변경 빈도
[TOP 5]
...

## 🔗 Own It 포트폴리오 연동
[홍보 문구]
```

**After (v2 - 10줄)**:
```markdown
# 📅 Daily Review - 2025.11.09

**2개 커밋 | 7개 파일 | +755줄**

18:07 feat: Add basic authentication module (src/auth)
18:07 feat: Add custom Claude Code commands (.claude/commands)

💡 주요 작업: 인증 모듈, 커스텀 명령어 개발
```

### todo-v2 (기본 모드)

**Before (v1 - 70줄, 각 항목마다 코드 블록)**:
```markdown
### 1. 인증 로직 구현 필요
**파일**: `src/auth/login.ts:3`
**이유**: FIXME 마커 - 핵심 기능 미구현
**코드**:
```typescript
// FIXME: Implement actual authentication logic
console.log('Login attempt:', username);
```
...
```

**After (v2 - 15줄, 파일:라인만)**:
```markdown
## 🔴 긴급 (2)
1. src/auth/login.ts:3 - FIXME: 인증 로직 구현
2. src/auth/login.ts:1 - TODO: 에러 핸들링

## 🟡 일반 (2)
3. src/auth/login.ts:4 - console.log 제거
4. tests/auth.test.ts:4 - 테스트 케이스 추가
```

---

## 🎯 v2 사용 권장 시나리오

### dailyreview-v2

**기본 모드**: 일상적인 일일 리뷰
```bash
/dailyreview-v2
```

**--brief 모드**: 빠른 확인, 팀 채팅 공유
```bash
/dailyreview-v2 --brief
```

**--full 모드**: 상세 분석, 블로그 초안, 주간 리포트
```bash
/dailyreview-v2 week --full
```

### todo-v2

**기본 모드**: 일반적인 할 일 확인
```bash
/todo-v2
```

**--brief 모드**: 스탠드업 미팅, 빠른 상태 확인
```bash
/todo-v2 --brief
```

**--priority-only**: 긴급 작업 집중 모드
```bash
/todo-v2 --priority-only
```

**--full 모드**: 코드 리뷰, 온보딩, 상세 분석
```bash
/todo-v2 --full
```

---

## ⚠️ Breaking Changes

### 없음 (v1 완전 호환)

- v1 명령어 (`/dailyreview`, `/todo`)는 그대로 유지
- v2는 별도 명령어 (`/dailyreview-v2`, `/todo-v2`)로 제공
- 점진적 마이그레이션 가능

---

## 🔜 향후 계획

### v0.2.1 (피드백 반영)
- [ ] 실사용 피드백 수집
- [ ] 발견된 버그 수정
- [ ] 성능 튜닝

### v0.3.0 (v2 정식 버전)
- [ ] v2 안정화 완료
- [ ] v1 → `*-legacy.md`로 리네임
- [ ] v2 → 기본 명령어로 승격
- [ ] Task 에이전트 통합 완성

---

## 📚 참고 문서

- [V2_TEST_GUIDE.md](./V2_TEST_GUIDE.md) - v2 테스트 가이드
- [examples/dailyreview-v2-example.md](./examples/dailyreview-v2-example.md) - v2 출력 예시
- [examples/todo-v2-example.md](./examples/todo-v2-example.md) - v2 출력 예시
- [README.md](./README.md) - 전체 문서

---

**버전**: v0.2.0-beta
**릴리스 날짜**: 2025-11-09
**상태**: 베타 테스트 중
