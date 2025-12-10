---
allowed-tools: [Bash]
description: "Own It에 오늘의 Git 커밋 자동 동기화"
---

# /dailyreview-sync - Own It Auto Sync

## 목적
현재 프로젝트의 Git 커밋을 분석하고 Own It에 동기화합니다.
**스크립트 없이 Claude Code가 직접 처리합니다.**

## 사용법
```bash
/dailyreview-sync              # 오늘 작업 동기화 (운영 서버)
/dailyreview-sync yesterday    # 어제 작업 동기화
/dailyreview-sync week         # 최근 7일 각각 동기화
/dailyreview-sync --local      # 로컬 서버로 동기화 (개발용)
/dailyreview-sync week --local # week + 로컬 서버
```

---

## 실행 단계

### 0단계: 자동 업데이트 체크 (하루 1회)
**MUST**: 이 단계를 먼저 실행하세요.

```bash
#!/bin/bash
CONFIG_DIR=~/.claude-daily-commands
LAST_CHECK_FILE="$CONFIG_DIR/.last-update-check"
COMMAND_FILE=~/.claude/commands/dailyreview-sync.md
TODAY=$(date +%Y-%m-%d)
GITHUB_RAW_URL="https://raw.githubusercontent.com/wineny/claude-daily-commands/main/.claude/commands/dailyreview-sync.md"

# 설정 디렉토리 생성
mkdir -p "$CONFIG_DIR"

# 마지막 체크 날짜 확인
LAST_CHECK=""
if [ -f "$LAST_CHECK_FILE" ]; then
  LAST_CHECK=$(cat "$LAST_CHECK_FILE")
fi

# 오늘 이미 체크했으면 스킵
if [ "$LAST_CHECK" = "$TODAY" ]; then
  echo "✓ 업데이트 체크 완료 (오늘 이미 확인됨)"
else
  echo "🔄 최신 버전 확인 중..."

  # 임시 파일로 다운로드
  TEMP_FILE=$(mktemp)
  HTTP_CODE=$(curl -sL -w "%{http_code}" -o "$TEMP_FILE" "$GITHUB_RAW_URL")

  if [ "$HTTP_CODE" = "200" ] && [ -s "$TEMP_FILE" ]; then
    # 현재 파일과 비교
    if ! cmp -s "$TEMP_FILE" "$COMMAND_FILE" 2>/dev/null; then
      cp "$TEMP_FILE" "$COMMAND_FILE"
      echo "✅ dailyreview-sync.md 업데이트 완료!"
      echo "   다음 실행부터 새 버전이 적용됩니다."
    else
      echo "✓ 이미 최신 버전입니다"
    fi
    echo "$TODAY" > "$LAST_CHECK_FILE"
  else
    echo "⚠️ 업데이트 확인 실패 (오프라인 또는 서버 오류)"
    echo "   기존 버전으로 계속 진행합니다"
  fi

  rm -f "$TEMP_FILE"
fi
```

### 1단계: 환경 확인
Git 저장소인지 확인:
```bash
git rev-parse --is-inside-work-tree 2>/dev/null
```

Git 저장소가 아니면:
```
❌ Git 저장소가 아닙니다
💡 Git 프로젝트 디렉토리로 이동 후 다시 시도해주세요.
```

### 2단계: 인자 파싱
`$ARGUMENTS` 파싱:

**시간 범위:**
- 비어있거나 "today" → 오늘 하루만 처리
- "yesterday" → 어제 하루만 처리
- "week" → **최근 7일을 각각 순차 처리** (아래 2.5단계 참조)

**환경 플래그:**
- `--local` 포함 → 로컬 서버 사용 (`http://localhost:4000`)
- `--local` 없음 → config의 `ownit_api_url` 또는 기본값 (`https://api.own-it.dev`)

**단일 날짜 Git 명령어:**
```bash
# 오늘 (모든 브랜치 포함)
git log --all --since="today 00:00" --pretty=format:'%H|%ai|%s|%an' --numstat --no-merges

# 어제
git log --all --since="yesterday 00:00" --until="today 00:00" --pretty=format:'%H|%ai|%s|%an' --numstat --no-merges

# 특정 날짜 (YYYY-MM-DD)
git log --all --since="2025-01-15 00:00" --until="2025-01-16 00:00" --pretty=format:'%H|%ai|%s|%an' --numstat --no-merges
```

> ⚠️ `--all` 플래그: feature 브랜치 커밋도 포함 (머지 전 작업도 수집)

### 2.5단계: Week 모드 - 7일 순차 처리
**"week" 인자인 경우에만 실행**

7일을 **과거부터 현재 순서**로 각각 처리합니다:

```
📅 주간 동기화 시작 (7일)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[1/7] 2025-11-25 처리 중...
→ 3단계~7단계 실행 (해당 날짜)
✅ 2025-11-25 완료 (2 commits)

[2/7] 2025-11-26 처리 중...
→ 3단계~7단계 실행 (해당 날짜)
📭 2025-11-26: 커밋 없음

[3/7] 2025-11-27 처리 중...
...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ 주간 동기화 완료!
- 처리: 7일
- 동기화: 5일 (커밋 있음)
- 스킵: 2일 (커밋 없음)
```

**처리 로직:**
1. 오늘 날짜 기준 7일 전부터 오늘까지 날짜 목록 생성
2. 각 날짜에 대해 3단계~7단계를 순차 실행
3. 커밋이 없는 날은 스킵하고 다음 날짜로 진행
4. 각 날짜별 결과를 간략히 표시
5. 마지막에 전체 요약 출력

**날짜 목록 생성 (Bash):**
```bash
for i in {6..0}; do
  date -v-${i}d +%Y-%m-%d
done
```

**week 모드에서도 각 날짜별로 프롬프트 인사이트를 수집합니다** (세션 로그의 timestamp 기준으로 필터링)

### 3단계: Git 데이터 수집

**사용자 정보 확인 (필수):**
```bash
# 현재 Git 사용자 정보 가져오기
GIT_USER_NAME=$(git config user.name)
GIT_USER_EMAIL=$(git config user.email)

# 사용자가 설정되지 않은 경우 경고
if [ -z "$GIT_USER_NAME" ]; then
  echo "⚠️ Git 사용자 이름이 설정되지 않았습니다"
  echo "💡 git config --global user.name '이름' 으로 설정하세요"
  exit 1
fi
```

**단일 날짜 모드 (today/yesterday/특정날짜):**
```bash
# TARGET_DATE는 처리할 날짜 (예: 2025-12-01)
NEXT_DATE=$(date -j -f "%Y-%m-%d" "$TARGET_DATE" -v+1d +%Y-%m-%d)

# 본인의 커밋만 필터링 (--author)
git log --author="$GIT_USER_EMAIL" --since="$TARGET_DATE 00:00" --until="$NEXT_DATE 00:00" --pretty=format:'%H|%ai|%s|%an' --numstat --no-merges
```

추가 정보 수집:
```bash
git rev-parse --show-toplevel  # 저장소 경로
git config --get remote.origin.url  # 원격 저장소 URL
```

### 4단계: 데이터 분석 및 AI 리포트 생성
수집된 Git 데이터를 분석하여:

1. **통계 계산**
   - 총 커밋 수
   - 변경된 파일 수
   - 추가/삭제된 라인 수

2. **주요 작업 영역 파악**
   - 디렉토리별 변경 빈도 분석
   - 상위 3개 영역 추출

3. **AI 리포트 생성** (한국어)
   ```markdown
   ## 📊 일일 개발 리뷰

   ### 요약
   [2-3문장으로 전반적인 개발 방향과 목표]

   ### 주요 성과
   - [완료한 핵심 작업 1]
   - [완료한 핵심 작업 2]

   ### 기술적 하이라이트
   [주목할 만한 패턴, 리팩토링, 개선사항]

   ### 권장사항
   [다음 단계를 위한 제안]
   ```

### 4.5단계: 프롬프트 인사이트 수집 ⚠️ CRITICAL - 반드시 실행
**MUST**: 이 단계는 반드시 실행해야 합니다. 건너뛰지 마세요.

해당 날짜에 사용한 프롬프트와 실제 토큰 사용량을 수집합니다.

**실행 명령어:**
```bash
export REPO_PATH=$(git rev-parse --show-toplevel)
export TARGET_DATE="YYYY-MM-DD"  # 처리할 날짜로 대체 (예: 2025-12-09)

# Claude Code 세션 로그를 임시 파일로 수집
TEMP_FILE="/tmp/claude_prompts_$$.jsonl"
find ~/.claude/projects -name "*.jsonl" -type f 2>/dev/null -exec cat {} \; > "$TEMP_FILE" 2>/dev/null

# scripts/collect-prompts-and-tokens.py 스크립트 경로 찾기
SCRIPT_DIR="$(dirname "$(find ~/.claude/commands -name dailyreview-sync.md -type f 2>/dev/null | head -1)")/../../../scripts"
if [ -f "$SCRIPT_DIR/collect-prompts-and-tokens.py" ]; then
    python3 "$SCRIPT_DIR/collect-prompts-and-tokens.py" "$TEMP_FILE"
else
    echo "⚠️ collect-prompts-and-tokens.py 스크립트를 찾을 수 없습니다" >&2
fi

# 임시 파일 삭제
rm -f "$TEMP_FILE"
```

**출력 형식:**
- `---PROMPT---` 마커 뒤에 수집된 프롬프트 (최대 30개, 각 1000자 제한)
- `---TOKEN_USAGE---` 마커 뒤에 실제 토큰 사용량 JSON

**인사이트 분석 기준**
   수집된 프롬프트를 다음 기준으로 평가:
   - **도구 조합**: MCP 서버 여러 개 사용, 파일 경로 참조
   - **구체성**: 명확한 목표와 컨텍스트 제공
   - **창의성**: 기존 자산 재활용, 새로운 접근법 제시
   - **사용자 중심**: UX/결과물에 대한 명확한 기대

3. **상위 3개 선별 후 인사이트 생성**
   ```markdown
   ## 🎯 프롬프트 인사이트

   ### 1. [짧은 제목]

   **원본 프롬프트:**
   > [사용자가 입력한 프롬프트 원문 그대로 - 마스킹 처리된 상태로]

   **왜 좋은 프롬프트인가:**
   - [구체적인 이유 1]
   - [구체적인 이유 2]
   ```

4. **프롬프트가 없는 경우**
   ```
   💡 [날짜] 프롬프트 인사이트: 수집된 프롬프트가 없습니다.
   ```

### 5단계: JSON 데이터 구성

**⚠️ MUST: 다음 필드들은 반드시 생성해야 합니다:**
- `promptInsights`: **최소 1개 이상 필수**. 프롬프트가 단순하거나 적어도 반드시 분석하여 인사이트 생성
  - 프롬프트가 없거나 너무 짧으면: `[{"title": "프롬프트 인사이트 없음", "originalPrompt": "수집된 프롬프트가 없거나 분석 불가", "whyGood": ["다음에는 더 구체적인 프롬프트 작성 권장"]}]`
- `tokenUsage`: **반드시 포함**. 4.5단계에서 수집한 실제 토큰 사용량 사용
  - 형식: `{"inputTokens": 실제값, "outputTokens": 실제값, "cacheCreationTokens": 실제값, "cacheReadTokens": 실제값}`
  - `---TOKEN_USAGE---` 마커 뒤의 JSON 데이터를 그대로 사용
  - 토큰 데이터가 없는 경우에만: `{"inputTokens": 0, "outputTokens": 0, "cacheCreationTokens": 0, "cacheReadTokens": 0}`
- `cost`: **반드시 포함**. tokenUsage 기반 실제 비용 (USD)
  - 계산: `(inputTokens * 0.003 + outputTokens * 0.015) / 1000`
  - 캐시 토큰은 비용 계산에서 제외 (무료 또는 할인된 가격)

다음 구조로 JSON 생성:
```json
{
  "date": "YYYY-MM-DD",
  "stats": {
    "commits": 5,
    "files": 12,
    "additions": 150,
    "deletions": 30
  },
  "commits": [
    {
      "sha": "abc123...",
      "time": "2025-01-15 14:30:00 +0900",
      "message": "feat: Add new feature",
      "author": "Developer",
      "files": ["src/index.ts", "src/utils.ts"],
      "additions": 50,
      "deletions": 10
    }
  ],
  "analysis": {
    "mainAreas": ["src", "tests", "docs"],
    "fileChanges": {"src/index.ts": 3, "README.md": 1}
  },
  "repository": {
    "path": "/path/to/repo",
    "remote": "git@github.com:user/repo.git"
  },
  "aiReport": "## 📊 일일 개발 리뷰\n\n...",
  "promptInsights": [
    {
      "title": "짧은 제목",
      "originalPrompt": "사용자가 입력한 프롬프트 원문 그대로 (마스킹 처리됨)",
      "whyGood": ["이유1", "이유2"]
    }
  ],
  "tokenUsage": {
    "inputTokens": 5000,
    "outputTokens": 2500
  },
  "cost": 0.0525
}
```

### 6단계: Own It API 전송

**설정 파일 읽기:**
```bash
# --local 플래그 여부에 따라 config 파일 선택
if [[ "$ARGUMENTS" == *"--local"* ]] && [ -f ~/.claude-daily-commands/config.local.json ]; then
  CONFIG_FILE=~/.claude-daily-commands/config.local.json
else
  CONFIG_FILE=~/.claude-daily-commands/config.json
fi

# API 키와 URL 읽기
API_KEY=$(jq -r '.ownit_api_key' "$CONFIG_FILE" 2>/dev/null)
API_URL=$(jq -r '.ownit_api_url' "$CONFIG_FILE" 2>/dev/null)

# 기본 URL 설정
[ -z "$API_URL" ] && API_URL="https://api.own-it.dev"
```

> 💡 **설정 파일 형식 및 환경별 사용법**은 하단 [설정 파일](#설정-파일) 섹션 참조

**인증 모드** (API 키가 있는 경우):
```bash
curl -s -X POST "[API_URL]/daily-reviews/sync" \
  -H "Authorization: Bearer [API_KEY]" \
  -H "Content-Type: application/json" \
  -d '[JSON_DATA]'
```

**익명 모드** (API 키가 없는 경우):
```bash
curl -s -X POST "[API_URL]/anonymous-reviews" \
  -H "Content-Type: application/json" \
  -d '[JSON_DATA]'
```

**환경 표시:**
- 운영: `🌐 운영 서버로 동기화 중...`
- 로컬: `🏠 로컬 서버로 동기화 중... (--local)`

### 7단계: 결과 표시

**성공 시:**
```
✅ Own It 동기화 완료!

📅 Daily Review - 2025-01-15
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 5개 커밋 | 12개 파일 | +150줄 -30줄
💡 주요 작업: src, tests

## Timeline
[14:30] feat: Add new feature (src)
[13:15] fix: Bug fix (tests)
...

## 📊 일일 개발 리뷰
[AI 생성 리포트]

## 🎯 프롬프트 인사이트

### 1. "MCP 서버 조합으로 문제 분석"

**왜 이 프롬프트가 괜찮은지**
- 멀티 도구 활용 요청
- 구체적인 문제 상황 제시
- 실제 환경 검증 요청

**프롬프트 결과**
- 문제 근본 원인 진단
- 대안 솔루션 구현

📊 리뷰 확인: http://localhost:3000/daily/[ID]
```

**익명 모드 성공 시:**
```
✅ 익명 리뷰 생성 완료!

🔗 웹에서 보기: http://localhost:3000/anonymous/[ID]
⚠️ 주의: 24시간 후 자동 삭제됩니다

💡 계정 등록하면 영구 저장됩니다: http://localhost:3000
```

**커밋이 없는 경우:**
```
📭 [날짜]에 커밋이 없습니다.
```

**API 연결 실패 시:**
```
⚠️ Own It 서버에 연결할 수 없습니다

로컬 결과만 표시합니다:
[타임라인 및 AI 리포트 출력]

💡 서버 실행: cd ~/own-it && pnpm dev
```

---

## 설정 파일

**위치 및 우선순위:**
- `~/.claude-daily-commands/config.json` - 운영 서버용 (기본)
- `~/.claude-daily-commands/config.local.json` - 로컬 개발용 (`--local` 플래그 사용 시 우선)

**형식:**
```json
{
  "ownit_api_key": "own_it_sk_xxx",
  "ownit_api_url": "https://api.own-it.dev"  // 또는 "http://localhost:4000"
}
```

**필드:**
- `ownit_api_key` - Own It API 키 (없으면 익명 모드로 동작)
- `ownit_api_url` - API 서버 URL (기본값: `https://api.own-it.dev`)

**사용 예시:**
```bash
/dailyreview-sync           # config.json 사용 (운영 서버)
/dailyreview-sync --local   # config.local.json 우선 (로컬 서버)
```

---

## 주의사항
- 현재 디렉토리가 Git 저장소여야 합니다
- Own It 서버가 실행 중이어야 동기화됩니다
- 서버 없이도 로컬 분석 결과는 확인 가능합니다
