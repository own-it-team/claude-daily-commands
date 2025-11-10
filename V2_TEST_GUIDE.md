# v2 테스트 가이드

v1과 v2를 비교 테스트하기 위한 완벽한 가이드입니다.

---

## 📁 생성된 파일

### 명령어 파일
```
.claude/commands/
├── dailyreview.md       (v1 - 원본 유지)
├── dailyreview-v2.md    (v2 - 신규 생성 ✨)
├── todo.md              (v1 - 원본 유지)
└── todo-v2.md           (v2 - 신규 생성 ✨)
```

### 예시 파일
```
examples/
├── dailyreview-example.md     (v1 예시)
├── dailyreview-v2-example.md  (v2 예시 ✨)
├── todo-example.md            (v1 예시)
└── todo-v2-example.md         (v2 예시 ✨)
```

---

## 🎯 v2 핵심 개선사항

### 1. 출력 간소화
| 명령어 | v1 | v2 (기본) | v2 (--brief) |
|--------|----|-----------| -------------|
| `/dailyreview` | ~50줄 | ~10줄 | ~3줄 |
| `/todo` | ~70줄 | ~15줄 | ~2줄 |

### 2. Accept 요청 감소
| 명령어 | v1 | v2 |
|--------|----|----|
| `/dailyreview` | 8-14회 | 1-3회 |
| `/todo` | 10-14회 | 3-5회 |

### 3. 실행 속도 향상
| 명령어 | v1 | v2 |
|--------|----|----|
| `/dailyreview` | ~30초 | ~8초 |
| `/todo` | ~20초 | ~10초 |

---

## 🧪 테스트 시나리오

### Day 1: 기본 기능 테스트

#### 1️⃣ dailyreview 비교
```bash
# v1 실행 (기존)
/dailyreview

# v2 기본 모드 실행
/dailyreview-v2

# v2 초간결 모드
/dailyreview-v2 --brief

# v2 상세 모드 (v1 호환)
/dailyreview-v2 --full
```

**체크리스트**:
- [ ] v2 기본 출력이 10줄 이내인가?
- [ ] v2 --brief가 3줄 이내인가?
- [ ] v2 --full이 v1과 동일한 정보를 제공하는가?
- [ ] Accept 요청이 3회 이하인가?
- [ ] 실행 시간이 10초 이하인가?

#### 2️⃣ todo 비교
```bash
# v1 실행 (기존)
/todo

# v2 기본 모드 실행
/todo-v2

# v2 초간결 모드
/todo-v2 --brief

# v2 긴급 항목만
/todo-v2 --priority-only

# v2 상세 모드
/todo-v2 --full
```

**체크리스트**:
- [ ] v2 기본 출력이 20줄 이내인가?
- [ ] v2 --brief가 3줄 이내인가?
- [ ] 우선순위 분류가 정확한가?
- [ ] Accept 요청이 5회 이하인가?
- [ ] 실행 시간이 15초 이하인가?

---

### Day 2: 성능 측정

#### 시간 측정
```bash
# v1 실행 시간
time /dailyreview
time /todo

# v2 실행 시간
time /dailyreview-v2
time /todo-v2
```

**기록 템플릿**:
```
| 명령어 | v1 시간 | v2 시간 | 개선율 |
|--------|---------|---------|--------|
| dailyreview | __초 | __초 | __% |
| todo | __초 | __초 | __% |
```

#### Accept 카운트
```
| 명령어 | v1 Accept | v2 Accept | 감소율 |
|--------|-----------|-----------|--------|
| dailyreview | __회 | __회 | __% |
| todo | __회 | __회 | __% |
```

---

### Day 3: 다양한 시나리오

#### 시간 범위 테스트
```bash
# 어제 작업
/dailyreview-v2 yesterday

# 최근 7일
/dailyreview-v2 week
```

#### 디렉토리 필터링
```bash
# 특정 디렉토리만
/todo-v2 @src/
/todo-v2 @components/
```

#### 에러 케이스
```bash
# 커밋이 없는 경우
cd /tmp && mkdir empty-repo && cd empty-repo
git init
/dailyreview-v2
# 예상: "📭 No commits today"

# Git 저장소가 아닌 경우
cd /tmp
/dailyreview-v2
# 예상: "❌ Not a git repo"

# Todo가 없는 경우
cd clean-project
/todo-v2
# 예상: "🎉 No todos found!"
```

---

## 📊 테스트 결과 기록표

### 기본 기능 (Pass/Fail)

| 항목 | v2 목표 | 실제 결과 | 상태 |
|------|---------|-----------|------|
| dailyreview 기본 출력 | ≤10줄 | ____줄 | ⬜ |
| dailyreview --brief | ≤3줄 | ____줄 | ⬜ |
| todo 기본 출력 | ≤20줄 | ____줄 | ⬜ |
| todo --brief | ≤3줄 | ____줄 | ⬜ |
| dailyreview Accept | ≤3회 | ____회 | ⬜ |
| todo Accept | ≤5회 | ____회 | ⬜ |

### 성능 (실제 측정값)

| 명령어 | v1 실행시간 | v2 실행시간 | 개선율 |
|--------|-------------|-------------|--------|
| /dailyreview | ____초 | ____초 | ___% |
| /todo | ____초 | ____초 | ___% |

### 정확성 (Pass/Fail)

| 항목 | 체크 |
|------|------|
| v2 --full이 v1과 동일한 정보 제공 | ⬜ |
| 커밋 개수가 v1과 일치 | ⬜ |
| Todo 개수가 v1과 일치 | ⬜ |
| 우선순위 분류 정확함 | ⬜ |

---

## 🐛 알려진 이슈 / 개선 사항

테스트 중 발견한 이슈를 기록하세요:

### Issue 1
- **설명**:
- **재현 방법**:
- **예상 동작**:
- **실제 동작**:
- **해결 방법**:

### Issue 2
- **설명**:
- **재현 방법**:
- **예상 동작**:
- **실제 동작**:
- **해결 방법**:

---

## 💡 사용 팁

### 추천 워크플로우

**아침 루틴**:
```bash
/dailyreview-v2 yesterday --brief   # 어제 뭐 했지?
/todo-v2 --priority-only            # 오늘 긴급한 것만
```

**점심 루틴**:
```bash
/todo-v2                            # 오전에 뭐 남았지?
```

**저녁 루틴**:
```bash
/dailyreview-v2                     # 오늘 뭐 했지?
/todo-v2                            # 내일 뭐 해야 하지?
```

**주간 리뷰 (금요일)**:
```bash
/dailyreview-v2 week --full         # 이번 주 전체 요약
/todo-v2 --full                     # 다음 주 계획
```

---

## 🔄 v1 → v2 마이그레이션 계획

### Week 1: 병렬 테스트
- ✅ v2 파일 생성 완료
- ⬜ 실제 프로젝트에서 테스트
- ⬜ 이슈 수집 및 개선

### Week 2: 안정화
- ⬜ 발견된 버그 수정
- ⬜ 성능 튜닝
- ⬜ 문서 업데이트

### Week 3: 전환 결정
- ⬜ v2 성능이 목표 달성 시 v1 대체
- ⬜ v1 → `dailyreview-legacy.md`로 리네임
- ⬜ v2 → `dailyreview.md`로 승격

---

## 📞 피드백 방법

테스트 후 피드백은 다음 형식으로:

```markdown
## 테스트 결과 피드백

**테스트 날짜**: YYYY.MM.DD
**테스트 환경**: [프로젝트 종류, 커밋 수 등]

### 👍 좋았던 점
-
-

### 👎 개선 필요
-
-

### 💡 제안 사항
-
-

### 종합 평가 (1-5)
- 속도: ⭐⭐⭐⭐⭐
- 간결성: ⭐⭐⭐⭐⭐
- 정확성: ⭐⭐⭐⭐⭐
- 사용성: ⭐⭐⭐⭐⭐

### v1 대체 의향
- [ ] 즉시 대체 가능
- [ ] 개선 후 대체
- [ ] v1 계속 사용
```

---

## 🚀 Quick Start

바로 테스트 시작하려면:

```bash
# 1. Claude Code에서 명령어 새로고침
# (필요시 Claude Code 재시작)

# 2. 첫 번째 테스트 실행
/dailyreview-v2

# 3. 결과 확인
# - 출력이 10줄 이내인가?
# - Accept 요청이 3회 이하인가?
# - 정보가 명확한가?

# 4. v1과 비교
/dailyreview

# 5. 피드백 기록
```

---

**화이팅! 🎉**

v2가 생각보다 훨씬 빠르고 간결할 거예요.
테스트 중 궁금한 점이 있으면 언제든 물어보세요!
