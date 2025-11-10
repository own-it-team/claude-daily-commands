# Todo v2 - Output Examples

실제 `/todo-v2` 명령어 출력 예시입니다.

---

## 예시 1: 기본 모드 (Default)

### 입력
```bash
/todo-v2
```

### 출력
```markdown
# ✅ Todo (15개 발견)

## 🔴 긴급 (3)
1. src/auth/login.ts:3 - FIXME: 인증 로직 구현
2. src/payment/stripe.ts:12 - BUG: 결제 실패 시 롤백 누락
3. src/api/endpoints.ts:45 - FIXME: SQL injection 취약점

## 🟡 일반 (7)
4. src/auth/login.ts:4 - console.log 제거
5. tests/auth.test.ts:4 - TODO: 테스트 케이스 추가
6. src/utils/logger.ts:23 - TODO: 로그 레벨 설정
7. src/components/Header.tsx:67 - debugger 제거
8. src/services/api.ts:89 - TODO: 에러 메시지 개선
9. src/db/migrations/001.sql:15 - TODO: 인덱스 최적화
10. src/config/env.ts:8 - console.warn 제거

## 🔵 개선 (5)
11. src/components/Modal.tsx:120 - NOTE: 접근성 개선 필요
12. src/utils/format.ts:34 - HACK: 임시 날짜 포맷 함수
13. src/auth/login.ts:14 - NOTE: 임시 구현
14. src/api/cache.ts:56 - TODO: 캐시 전략 재검토
15. README.md:89 - TODO: API 문서 작성

📌 최근 변경: feat: Add user authentication flow
```

**특징**:
- 15줄 내외의 간결한 리스트
- 파일:라인 정보만 (코드 블록 생략)
- 우선순위별 명확한 분류
- 마지막 커밋 컨텍스트 제공

---

## 예시 2: --brief 모드 (Ultra Compact)

### 입력
```bash
/todo-v2 --brief
```

### 출력
```markdown
✅ 15 todos | 🔴 3긴급 🟡 7일반 🔵 5개선
다음: src/auth/login.ts - 인증 로직 구현
```

**특징**:
- 2줄 요약
- 즉시 다음 액션 제시
- 팀 채팅에 공유하기 좋음

---

## 예시 3: --full 모드 (Detailed)

### 입력
```bash
/todo-v2 --full
```

### 출력
```markdown
# ✅ Next Actions - AI Portfolio Generator

> 📊 분석 완료: 15개 항목 발견
> 🔍 검색 범위: 프로젝트 전체
> 📅 분석 일시: 2025년 11월 9일

## 🔴 긴급 (High Priority) - 3개

### 1. 인증 로직 구현 필요
**파일**: `src/auth/login.ts:3`
**심각도**: 🚨 Critical
**이유**: FIXME 마커 - 핵심 기능 미구현

**코드**:
```typescript
// FIXME: Implement actual authentication logic
export async function login(username: string, password: string) {
  console.log('Login attempt:', username);
  return { success: true }; // Mock implementation
}
```

**권장 조치**:
```typescript
// 실제 인증 구현 예시
export async function login(username: string, password: string) {
  try {
    const user = await db.users.findOne({ username });
    if (!user) throw new Error('User not found');

    const isValid = await bcrypt.compare(password, user.passwordHash);
    if (!isValid) throw new Error('Invalid password');

    return { success: true, token: generateJWT(user) };
  } catch (error) {
    logger.error('Login failed:', error);
    throw error;
  }
}
```

### 2. 결제 실패 시 롤백 누락
**파일**: `src/payment/stripe.ts:12`
**심각도**: 🔴 High
**이유**: BUG 키워드 - 데이터 무결성 위험

**코드**:
```typescript
// BUG: Payment failure doesn't rollback user upgrade
async function processPayment(userId: string, amount: number) {
  await db.users.update(userId, { isPremium: true });
  const charge = await stripe.charges.create({ amount });
  return charge;
}
```

**문제점**:
- Stripe 결제 실패 시 사용자는 이미 Premium으로 업그레이드됨
- 트랜잭션 처리 없음

**권장 조치**:
```typescript
async function processPayment(userId: string, amount: number) {
  const session = await db.startSession();
  try {
    const charge = await stripe.charges.create({ amount });
    await db.users.update(userId, { isPremium: true }, { session });
    await session.commitTransaction();
    return charge;
  } catch (error) {
    await session.abortTransaction();
    throw error;
  }
}
```

### 3. SQL Injection 취약점
**파일**: `src/api/endpoints.ts:45`
**심각도**: 🚨 Critical
**이유**: 보안 취약점 - 즉시 수정 필요

**코드**:
```typescript
// FIXME: SQL injection vulnerability
app.get('/users/:id', (req, res) => {
  const query = `SELECT * FROM users WHERE id = ${req.params.id}`;
  db.query(query).then(user => res.json(user));
});
```

**권장 조치**:
```typescript
app.get('/users/:id', (req, res) => {
  const query = 'SELECT * FROM users WHERE id = ?';
  db.query(query, [req.params.id]).then(user => res.json(user));
});
```

## 🟡 일반 (Medium Priority) - 7개

### 4. 디버깅 코드 제거
**파일**: `src/auth/login.ts:4`
**타입**: console.log
**코드**:
```typescript
console.log('Login attempt:', username);
```

**권장 조치**: 프로덕션 로깅 시스템 사용
```typescript
logger.info('Login attempt', { username, timestamp: new Date() });
```

### 5. 테스트 케이스 추가
**파일**: `tests/auth.test.ts:4`
**타입**: TODO
**코드**:
```typescript
// TODO: Add more test cases
test('should login successfully', async () => {
  const result = await login('user', 'pass');
  expect(result.success).toBe(true);
});
```

**권장 테스트**:
- 잘못된 비밀번호 케이스
- 존재하지 않는 사용자
- 계정 잠금 케이스
- Rate limiting 테스트

[... 6-10번 항목 생략 ...]

## 🔵 개선 제안 (Nice to Have) - 5개

### 11. 접근성 개선
**파일**: `src/components/Modal.tsx:120`
**제안 이유**: WCAG 2.1 AA 기준 미충족
**코드**:
```tsx
// NOTE: Accessibility improvements needed
<div className="modal">
  <button onClick={onClose}>X</button>
  {children}
</div>
```

**개선안**:
```tsx
<div className="modal" role="dialog" aria-modal="true">
  <button
    onClick={onClose}
    aria-label="Close modal"
    className="close-button"
  >
    ×
  </button>
  {children}
</div>
```

[... 12-15번 항목 생략 ...]

## 📊 통계 요약

| 카테고리 | 개수 | 비율 |
|---------|------|------|
| 🔴 긴급 | 3개 | 20% |
| 🟡 일반 | 7개 | 47% |
| 🔵 개선 | 5개 | 33% |
| **총합** | **15개** | **100%** |

## 🚀 다음 단계 추천

**이번 주 (Week 1)**
1. ✅ 인증 로직 실제 구현 (최우선)
2. ✅ 결제 롤백 로직 추가
3. ✅ SQL Injection 취약점 수정

**다음 주 (Week 2)**
1. console.log → logger 시스템 전환
2. 테스트 커버리지 확대 (현재 60% → 80% 목표)
3. 접근성 감사 및 개선

**장기 (Month 1)**
1. 임시 구현 코드 정식화
2. 캐시 전략 재설계
3. API 문서화 완료

## 🔍 Git 기반 인사이트

### 마지막 커밋 분석
- **커밋**: feat: Add user authentication flow
- **변경 파일**: src/auth/, tests/auth/
- **추론된 다음 작업**: 인증 로직 실제 구현 완료 후 테스트 보완

### 진행 중인 작업
- 스테이징된 파일: 없음
- 수정된 파일: src/auth/login.ts (진행 중)
- 추적되지 않는 파일: src/auth/oauth.ts (새 기능 준비)

## 💼 Own It 연동
> 이 Todo를 프로젝트 관리 시스템과 연동하고 싶다면?
>
> `/portfolio` 명령어로 작업 히스토리와 함께 포트폴리오 생성 (준비 중)

## 🎓 학습 리소스

각 항목 해결에 도움이 될 리소스:
- **인증**: [Passport.js Documentation](https://www.passportjs.org/)
- **결제 트랜잭션**: [Stripe Best Practices](https://stripe.com/docs/payments/best-practices)
- **SQL Injection**: [OWASP Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html)
- **접근성**: [WAI-ARIA Authoring Practices](https://www.w3.org/WAI/ARIA/apg/)

---
마지막 업데이트: 2025년 11월 9일 21:00
다음 리뷰 권장일: 2025년 11월 16일 (1주 후)
```

**특징**:
- v1과 동일한 상세 정보
- 각 항목마다 코드 블록 + 해결책
- 학습 리소스 포함
- Git 컨텍스트 및 다음 단계 제안

---

## 예시 4: --priority-only 모드

### 입력
```bash
/todo-v2 --priority-only
```

### 출력
```markdown
# 🔴 긴급 항목만 (3개)

1. src/auth/login.ts:3 - FIXME: 인증 로직 구현
2. src/payment/stripe.ts:12 - BUG: 결제 실패 시 롤백 누락
3. src/api/endpoints.ts:45 - FIXME: SQL injection 취약점

💡 전체 목록: /todo-v2
```

**특징**:
- 긴급 항목만 필터링
- 집중력 향상
- 빠른 우선순위 판단

---

## 예시 5: 특정 디렉토리만 검색

### 입력
```bash
/todo-v2 @src/auth/
```

### 출력
```markdown
# ✅ Todo - src/auth/ (4개 발견)

## 🔴 긴급 (1)
1. src/auth/login.ts:3 - FIXME: 인증 로직 구현

## 🟡 일반 (2)
2. src/auth/login.ts:4 - console.log 제거
3. src/auth/session.ts:23 - TODO: 세션 만료 처리

## 🔵 개선 (1)
4. src/auth/login.ts:14 - NOTE: 임시 구현

📌 검색 범위: src/auth/
```

**특징**:
- 특정 모듈만 집중 분석
- 모듈별 Todo 관리 가능

---

## 예시 6: Todo가 없는 경우

### 입력
```bash
/todo-v2
```

### 출력
```markdown
🎉 No todos found!

✨ 코드베이스가 깔끔하네요!

다음 작업 제안:
- 새로운 기능 추가
- 성능 최적화 검토
- 문서화 개선
- /dailyreview-v2로 최근 작업 확인
```

---

## 예시 7: 경로가 존재하지 않는 경우

### 입력
```bash
/todo-v2 @nonexistent/
```

### 출력
```markdown
❌ Path not found: nonexistent/

현재 디렉토리: /Users/wine_ny/project

Try:
- /todo-v2 @src/
- /todo-v2 @app/components/
```

---

## 비교: v1 vs v2

| 항목 | v1 | v2 (기본) | v2 (--brief) |
|------|----|-----------| -------------|
| 출력 줄 수 | ~70줄 | ~15줄 | ~2줄 |
| Accept 요청 | 10-14회 | 3-5회 | 1-2회 |
| 코드 블록 | 모든 항목 | 없음 | 없음 |
| 실행 시간 | ~20초 | ~10초 | ~5초 |
| 정보 손실 | 0% | 파일:라인은 유지 | 통계만 |

**추천 사용 시나리오**:
- **기본 모드**: 일반적인 Todo 확인 및 관리
- **--brief**: 빠른 상태 확인, 스탠드업 미팅
- **--full**: 상세 분석, 코드 리뷰, 온보딩 문서
- **--priority-only**: 긴급 작업 집중 모드

---

## 실제 사용 팁

### 1. 일일 워크플로우
```bash
# 아침: 어제 작업 확인
/dailyreview-v2 yesterday

# 오전: 긴급 Todo 확인
/todo-v2 --priority-only

# 저녁: 오늘 작업 요약
/dailyreview-v2

# 퇴근 전: 전체 Todo 체크
/todo-v2
```

### 2. 스프린트 리뷰
```bash
# 주간 작업 확인
/dailyreview-v2 week --full

# 모듈별 Todo 정리
/todo-v2 @src/auth/ --full
/todo-v2 @src/payment/ --full
```

### 3. 팀 공유
```bash
# Slack에 간단히 공유
/dailyreview-v2 --brief
/todo-v2 --brief

# 상세 리포트는 --full로 문서화
/dailyreview-v2 --full > weekly-report.md
```
