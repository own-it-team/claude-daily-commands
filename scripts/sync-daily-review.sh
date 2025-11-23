#!/bin/bash
# sync-daily-review.sh - Sync daily review to Own It backend

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
CONFIG_DIR="$HOME/.claude-daily-commands"
CONFIG_FILE="$CONFIG_DIR/config.json"

# Parse arguments
NO_SYNC=false
TIME_RANGE="today"

for arg in "$@"; do
  case "$arg" in
    --no-sync) NO_SYNC=true ;;
    yesterday|week) TIME_RANGE="$arg" ;;
  esac
done

# Check if in git repository
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  echo -e "${RED}❌ Not a git repository${NC}"
  echo "💡 Run this command in a git repository"
  exit 1
fi

# Determine time range
case "$TIME_RANGE" in
  yesterday)
    SINCE="yesterday 00:00"
    UNTIL="yesterday 23:59"
    if [[ "$OSTYPE" == "darwin"* ]]; then
      DATE=$(date -v-1d +%Y-%m-%d)
    else
      DATE=$(date -d "yesterday" +%Y-%m-%d)
    fi
    ;;
  week)
    SINCE="7 days ago"
    UNTIL="now"
    DATE=$(date +%Y-%m-%d)
    ;;
  *)
    SINCE="today 00:00"
    UNTIL="now"
    DATE=$(date +%Y-%m-%d)
    ;;
esac

# Collect git data
GIT_LOG=$(git log --since="$SINCE" --until="$UNTIL" \
  --pretty=format:'COMMIT:%H|%ai|%s|%an' \
  --numstat \
  --no-merges 2>/dev/null || true)

if [ -z "$GIT_LOG" ]; then
  echo "📭 No commits found for $DATE"
  exit 0
fi

# Get repository info
REPO_PATH=$(git rev-parse --show-toplevel)
REPO_REMOTE=$(git config --get remote.origin.url 2>/dev/null || echo "")

# Parse git data and create JSON using Python
JSON_DATA=$(python3 << PYTHON_EOF
import sys
import json
from collections import defaultdict

git_log = """$GIT_LOG"""
repo_path = """$REPO_PATH"""
repo_remote = """$REPO_REMOTE"""
review_date = """$DATE"""

commits = []
stats = {"commits": 0, "files": set(), "additions": 0, "deletions": 0}
file_changes = defaultdict(int)
current_commit = None

for line in git_log.strip().split('\n'):
    if line.startswith('COMMIT:'):
        if current_commit:
            commits.append(current_commit)

        # Parse: COMMIT:sha|datetime|message|author
        parts = line[7:].split('|', 3)
        if len(parts) >= 4:
            current_commit = {
                "sha": parts[0],
                "time": parts[1],
                "message": parts[2],
                "author": parts[3],
                "files": [],
                "additions": 0,
                "deletions": 0
            }
            stats["commits"] += 1
    elif '\t' in line and current_commit:
        # Parse numstat: additions\tdeletions\tfilename
        parts = line.split('\t')
        if len(parts) == 3:
            adds_str, dels_str, filename = parts
            adds = int(adds_str) if adds_str.isdigit() else 0
            dels = int(dels_str) if dels_str.isdigit() else 0

            current_commit["files"].append(filename)
            current_commit["additions"] += adds
            current_commit["deletions"] += dels

            stats["files"].add(filename)
            stats["additions"] += adds
            stats["deletions"] += dels

            file_changes[filename] += 1

# Add last commit
if current_commit:
    commits.append(current_commit)

# Analyze main work areas
main_areas = []
if file_changes:
    dir_changes = defaultdict(int)
    for file, count in file_changes.items():
        dir_name = file.split('/')[0] if '/' in file else 'root'
        dir_changes[dir_name] += count

    # Top 3 directories
    main_areas = sorted(dir_changes.items(), key=lambda x: x[1], reverse=True)[:3]
    main_areas = [area[0] for area in main_areas]

# Build JSON output
output = {
    "date": review_date,
    "stats": {
        "commits": stats["commits"],
        "files": len(stats["files"]),
        "additions": stats["additions"],
        "deletions": stats["deletions"]
    },
    "commits": commits,
    "analysis": {
        "mainAreas": main_areas,
        "fileChanges": dict(file_changes)
    }
}

# Add repository info if available
if repo_path and repo_remote:
    output["repository"] = {
        "path": repo_path,
        "remote": repo_remote
    }

print(json.dumps(output))
PYTHON_EOF
)

# Extract stats for display
COMMIT_COUNT=$(echo "$JSON_DATA" | python3 -c "import sys, json; print(json.load(sys.stdin)['stats']['commits'])")
FILE_COUNT=$(echo "$JSON_DATA" | python3 -c "import sys, json; print(json.load(sys.stdin)['stats']['files'])")
ADDITIONS=$(echo "$JSON_DATA" | python3 -c "import sys, json; print(json.load(sys.stdin)['stats']['additions'])")
DELETIONS=$(echo "$JSON_DATA" | python3 -c "import sys, json; print(json.load(sys.stdin)['stats']['deletions'])")
MAIN_AREAS=$(echo "$JSON_DATA" | python3 -c "import sys, json; areas = json.load(sys.stdin)['analysis']['mainAreas']; print(', '.join(areas[:2]) if areas else 'N/A')")

# Print local summary header
echo ""
echo "# 📅 Daily Review - $DATE"
echo ""
echo "**${COMMIT_COUNT}개 커밋 | ${FILE_COUNT}개 파일 | +${ADDITIONS}줄 -${DELETIONS}줄**"
echo ""

# ============================================
# AI Report Generation (Claude API)
# ============================================
AI_REPORT=""
CLAUDE_API_KEY=""

if [ -f "$CONFIG_FILE" ] && command -v jq &>/dev/null; then
  CLAUDE_API_KEY=$(jq -r '.claude_api_key // ""' "$CONFIG_FILE" 2>/dev/null || echo "")
fi

if [ -n "$CLAUDE_API_KEY" ]; then
  echo -e "${CYAN}🤖 AI 리포트 생성 중...${NC}"

  # Create prompt for Claude
  PROMPT="당신은 기술 개발 분석가입니다. 다음 Git 커밋 데이터를 분석하여 간결하고 통찰력 있는 일일 리뷰 리포트를 한국어로 작성해주세요.

Git 커밋 데이터:
- 날짜: $DATE
- 커밋 수: $COMMIT_COUNT
- 변경된 파일: $FILE_COUNT개
- 라인 변경: +$ADDITIONS -$DELETIONS
- 주요 작업 영역: $MAIN_AREAS

상세 커밋 내역:
$GIT_LOG

다음 내용을 포함해주세요:
1. 요약 (2-3문장): 전반적인 개발 방향과 목표
2. 주요 성과: 오늘 완료한 핵심 작업들
3. 기술적 하이라이트: 주목할 만한 패턴, 리팩토링, 개선사항
4. 권장사항: 다음 단계를 위한 제안

리포트는 간결하게 (300단어 이하) 작성하되 실행 가능한 내용으로 구성해주세요.
마크다운 형식으로 작성하고, 제목은 '# 📊 일일 개발 리뷰'로 시작해주세요."

  # Call Claude API
  CLAUDE_RESPONSE=$(curl -s https://api.anthropic.com/v1/messages \
    -H "content-type: application/json" \
    -H "x-api-key: $CLAUDE_API_KEY" \
    -H "anthropic-version: 2023-06-01" \
    -d "{
      \"model\": \"claude-haiku-4-5-20251001\",
      \"max_tokens\": 1024,
      \"messages\": [{
        \"role\": \"user\",
        \"content\": $(echo "$PROMPT" | python3 -c "import sys, json; print(json.dumps(sys.stdin.read()))")
      }]
    }" 2>/dev/null)

  # Extract AI report and token usage from response
  TOKENS_INPUT=0
  TOKENS_OUTPUT=0
  TOKENS_CACHE_CREATION=0
  TOKENS_CACHE_READ=0

  if [ -n "$CLAUDE_RESPONSE" ]; then
    # Parse response and extract both AI report and token usage
    PARSED_RESPONSE=$(echo "$CLAUDE_RESPONSE" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    result = {'report': '', 'tokens_input': 0, 'tokens_output': 0, 'tokens_cache_creation': 0, 'tokens_cache_read': 0}

    # Extract AI report text
    if 'content' in data and len(data['content']) > 0:
        result['report'] = data['content'][0]['text']

    # Extract token usage from 'usage' field
    if 'usage' in data:
        usage = data['usage']
        result['tokens_input'] = usage.get('input_tokens', 0)
        result['tokens_output'] = usage.get('output_tokens', 0)

        # Cache tokens (if available)
        if 'cache_creation_input_tokens' in usage:
            result['tokens_cache_creation'] = usage['cache_creation_input_tokens']
        if 'cache_read_input_tokens' in usage:
            result['tokens_cache_read'] = usage['cache_read_input_tokens']

    print(json.dumps(result))
except Exception as e:
    print(json.dumps({'report': '', 'tokens_input': 0, 'tokens_output': 0, 'tokens_cache_creation': 0, 'tokens_cache_read': 0}))
" 2>/dev/null || echo '{"report":"","tokens_input":0,"tokens_output":0,"tokens_cache_creation":0,"tokens_cache_read":0}')

    # Extract values from parsed response
    AI_REPORT=$(echo "$PARSED_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('report', ''))" 2>/dev/null || echo "")
    TOKENS_INPUT=$(echo "$PARSED_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('tokens_input', 0))" 2>/dev/null || echo "0")
    TOKENS_OUTPUT=$(echo "$PARSED_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('tokens_output', 0))" 2>/dev/null || echo "0")
    TOKENS_CACHE_CREATION=$(echo "$PARSED_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('tokens_cache_creation', 0))" 2>/dev/null || echo "0")
    TOKENS_CACHE_READ=$(echo "$PARSED_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('tokens_cache_read', 0))" 2>/dev/null || echo "0")

    if [ -n "$AI_REPORT" ]; then
      echo -e "${GREEN}✅ AI 리포트 생성 완료${NC}"
      echo -e "${CYAN}📊 토큰 사용: Input=$TOKENS_INPUT, Output=$TOKENS_OUTPUT${NC}"
      if [ "$TOKENS_CACHE_CREATION" -gt 0 ] || [ "$TOKENS_CACHE_READ" -gt 0 ]; then
        echo -e "${CYAN}   Cache: Creation=$TOKENS_CACHE_CREATION, Read=$TOKENS_CACHE_READ${NC}"
      fi
      echo ""
    else
      echo -e "${YELLOW}⚠️  AI 리포트 생성 실패 (응답 파싱 오류)${NC}"
      echo ""
    fi
  else
    echo -e "${YELLOW}⚠️  AI 리포트 생성 실패 (API 호출 오류)${NC}"
    echo ""
  fi
else
  echo -e "${YELLOW}💡 AI 리포트를 생성하려면 Claude API 키를 설정하세요${NC}"
  echo "   설정 방법: ~/.claude-daily-commands/config.json에 'claude_api_key' 추가"
  echo ""
fi

# Add AI report and token usage to JSON data
echo "[DEBUG] Before adding AI report - AI_REPORT length: ${#AI_REPORT}" >&2
if [ -n "$AI_REPORT" ]; then
  echo "[DEBUG] AI_REPORT is NOT empty, adding to JSON..." >&2
  JSON_DATA=$(echo "$JSON_DATA" | AI_REPORT="$AI_REPORT" python3 -c "
import sys, json, os
data = json.load(sys.stdin)
ai_report = os.environ.get('AI_REPORT', '')
data['aiReport'] = ai_report
print(f'[DEBUG-PYTHON] ai_report length: {len(ai_report)}', file=sys.stderr)

# Add token usage information
data['tokenUsage'] = {
    'input': int($TOKENS_INPUT),
    'output': int($TOKENS_OUTPUT),
    'cacheCreation': int($TOKENS_CACHE_CREATION),
    'cacheRead': int($TOKENS_CACHE_READ),
    'total': int($TOKENS_INPUT) + int($TOKENS_OUTPUT) + int($TOKENS_CACHE_CREATION) + int($TOKENS_CACHE_READ)
}

# Calculate cost (Claude 3.5 Sonnet pricing)
# Input: \$3 per MTok, Output: \$15 per MTok
# Cache creation: \$3.75 per MTok, Cache read: \$0.30 per MTok
input_cost = (int($TOKENS_INPUT) / 1_000_000) * 3.0
output_cost = (int($TOKENS_OUTPUT) / 1_000_000) * 15.0
cache_creation_cost = (int($TOKENS_CACHE_CREATION) / 1_000_000) * 3.75
cache_read_cost = (int($TOKENS_CACHE_READ) / 1_000_000) * 0.30
total_cost = input_cost + output_cost + cache_creation_cost + cache_read_cost

data['cost'] = {
    'usd': round(total_cost, 4)
}

print(json.dumps(data))
")
else
  echo "[DEBUG] AI_REPORT is EMPTY, skipping aiReport field" >&2
fi

# ============================================
# Claude Code Token Collection (from session JSONL files)
# ============================================
echo -e "${CYAN}🔍 Claude Code 토큰 사용량 수집 중...${NC}"

CLAUDE_TOKENS=$(DATE="$DATE" REPO_PATH="$REPO_PATH" python3 << 'PYTHON_TOKENS'
import sys
import json
import os
from pathlib import Path
from datetime import datetime
from glob import glob

# Get target date and repository path
target_date = os.environ.get('DATE', datetime.now().strftime('%Y-%m-%d'))
repo_path = os.environ.get('REPO_PATH', '').strip()

# Normalize repository path for comparison
if repo_path:
    repo_path = os.path.abspath(repo_path)

# Initialize token counters
tokens = {
    'input': 0,
    'output': 0,
    'cache_creation': 0,
    'cache_read': 0,
    'total': 0
}

# Define Claude data directories to search
claude_dirs = []
config_dir = os.environ.get('CLAUDE_CONFIG_DIR', '').strip()

if config_dir:
    # Use environment variable paths
    for path in config_dir.split(','):
        path = path.strip()
        if path and os.path.isdir(path):
            claude_dirs.append(path)
else:
    # Default paths
    home = str(Path.home())
    xdg_config = os.environ.get('XDG_CONFIG_HOME', os.path.join(home, '.config'))
    default_paths = [
        os.path.join(xdg_config, 'claude'),
        os.path.join(home, '.claude')
    ]
    claude_dirs = [p for p in default_paths if os.path.isdir(p)]

# Search for JSONL files in all Claude directories
for claude_dir in claude_dirs:
    projects_dir = os.path.join(claude_dir, 'projects')
    if not os.path.isdir(projects_dir):
        continue

    # Find all JSONL session files
    pattern = os.path.join(projects_dir, '**', '*.jsonl')
    jsonl_files = glob(pattern, recursive=True)

    for jsonl_path in jsonl_files:
        try:
            with open(jsonl_path, 'r', encoding='utf-8') as f:
                for line in f:
                    line = line.strip()
                    if not line:
                        continue

                    try:
                        entry = json.loads(line)

                        # Check if entry has required fields
                        if 'timestamp' not in entry or 'message' not in entry:
                            continue

                        # Filter by current repository path (cwd field)
                        if repo_path:
                            entry_cwd = entry.get('cwd', '').strip()
                            if entry_cwd:
                                entry_cwd = os.path.abspath(entry_cwd)
                                # Check if entry is from current repository
                                if not entry_cwd.startswith(repo_path):
                                    continue

                        # Parse timestamp and check if it matches target date
                        timestamp = entry['timestamp']
                        entry_date = timestamp.split('T')[0]  # Extract YYYY-MM-DD

                        if entry_date != target_date:
                            continue

                        # Extract usage from message
                        message = entry.get('message', {})
                        usage = message.get('usage', {})

                        if not usage:
                            continue

                        # Accumulate tokens
                        tokens['input'] += usage.get('input_tokens', 0)
                        tokens['output'] += usage.get('output_tokens', 0)
                        tokens['cache_creation'] += usage.get('cache_creation_input_tokens', 0)
                        tokens['cache_read'] += usage.get('cache_read_input_tokens', 0)

                    except json.JSONDecodeError:
                        continue
        except Exception:
            continue

# Calculate total
tokens['total'] = tokens['input'] + tokens['output'] + tokens['cache_creation'] + tokens['cache_read']

# Calculate cost (Claude 3.5 Sonnet pricing)
input_cost = (tokens['input'] / 1_000_000) * 3.0
output_cost = (tokens['output'] / 1_000_000) * 15.0
cache_creation_cost = (tokens['cache_creation'] / 1_000_000) * 3.75
cache_read_cost = (tokens['cache_read'] / 1_000_000) * 0.30
total_cost = input_cost + output_cost + cache_creation_cost + cache_read_cost

result = {
    'tokens': tokens,
    'cost_usd': round(total_cost, 4)
}

print(json.dumps(result))
PYTHON_TOKENS
)

# Extract Claude Code token data
CC_TOKENS_INPUT=$(echo "$CLAUDE_TOKENS" | python3 -c "import sys, json; print(json.load(sys.stdin)['tokens']['input'])" 2>/dev/null || echo "0")
CC_TOKENS_OUTPUT=$(echo "$CLAUDE_TOKENS" | python3 -c "import sys, json; print(json.load(sys.stdin)['tokens']['output'])" 2>/dev/null || echo "0")
CC_TOKENS_CACHE_CREATION=$(echo "$CLAUDE_TOKENS" | python3 -c "import sys, json; print(json.load(sys.stdin)['tokens']['cache_creation'])" 2>/dev/null || echo "0")
CC_TOKENS_CACHE_READ=$(echo "$CLAUDE_TOKENS" | python3 -c "import sys, json; print(json.load(sys.stdin)['tokens']['cache_read'])" 2>/dev/null || echo "0")
CC_TOKENS_TOTAL=$(echo "$CLAUDE_TOKENS" | python3 -c "import sys, json; print(json.load(sys.stdin)['tokens']['total'])" 2>/dev/null || echo "0")
CC_COST_USD=$(echo "$CLAUDE_TOKENS" | python3 -c "import sys, json; print(json.load(sys.stdin)['cost_usd'])" 2>/dev/null || echo "0.0000")

if [ "$CC_TOKENS_TOTAL" -gt "0" ]; then
  echo -e "${GREEN}✅ Claude Code 토큰: ${CC_TOKENS_TOTAL} (비용: \$${CC_COST_USD})${NC}"
  echo "   Input: ${CC_TOKENS_INPUT} | Output: ${CC_TOKENS_OUTPUT}"
  echo "   Cache Creation: ${CC_TOKENS_CACHE_CREATION} | Cache Read: ${CC_TOKENS_CACHE_READ}"
else
  echo -e "${YELLOW}⚠️  Claude Code 토큰 사용 내역 없음${NC}"
fi
echo ""

# Add Claude Code usage to JSON data
JSON_DATA=$(echo "$JSON_DATA" | python3 -c "
import sys, json
data = json.load(sys.stdin)

# Add Claude Code token usage
data['claudeCodeUsage'] = {
    'input': int($CC_TOKENS_INPUT),
    'output': int($CC_TOKENS_OUTPUT),
    'cacheCreation': int($CC_TOKENS_CACHE_CREATION),
    'cacheRead': int($CC_TOKENS_CACHE_READ),
    'total': int($CC_TOKENS_TOTAL),
    'costUsd': float($CC_COST_USD)
}

print(json.dumps(data))
")

# Determine sync mode (authenticated vs anonymous)
MODE="anonymous"
API_KEY=""
API_URL="http://localhost:4000"

if [ -f "$CONFIG_FILE" ] && command -v jq &>/dev/null; then
  API_KEY=$(jq -r '.ownit_api_key // ""' "$CONFIG_FILE" 2>/dev/null || echo "")
  CUSTOM_API_URL=$(jq -r '.ownit_api_url // ""' "$CONFIG_FILE" 2>/dev/null || echo "")

  if [ -n "$CUSTOM_API_URL" ]; then
    API_URL="$CUSTOM_API_URL"
  fi

  if [ -n "$API_KEY" ]; then
    MODE="authenticated"
  fi
fi

# Sync to backend (if not disabled)
SYNC_SUCCESS=false
REVIEW_URL=""

if [ "$NO_SYNC" = false ]; then
  if [ "$MODE" = "authenticated" ]; then
    # ============================================
    # Authenticated Mode (기존 로직)
    # ============================================
    echo -e "${CYAN}🔄 Own It에 동기화 중... (인증 모드)${NC}"

    ENDPOINT="$API_URL/api/daily-reviews/sync"

    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$ENDPOINT" \
      -H "Authorization: Bearer $API_KEY" \
      -H "Content-Type: application/json" \
      -d "$JSON_DATA")

    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')

    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
      if echo "$BODY" | python3 -c "import sys, json; exit(0 if json.load(sys.stdin).get('success') else 1)" 2>/dev/null; then
        REVIEW_ID=$(echo "$BODY" | python3 -c "import sys, json; print(json.load(sys.stdin)['data']['id'])" 2>/dev/null || echo "")
        echo -e "${GREEN}✅ Own It 동기화 완료!${NC}"
        if [ -n "$REVIEW_ID" ]; then
          WEB_URL=$(echo "$API_URL" | sed 's/:4000/:3000/')
          REVIEW_URL="${WEB_URL}/daily/${REVIEW_ID}"
          echo "📊 리뷰 확인: ${REVIEW_URL}"
        fi
        echo ""
        SYNC_SUCCESS=true
      else
        ERROR_MSG=$(echo "$BODY" | python3 -c "import sys, json; print(json.load(sys.stdin).get('message', 'Unknown error'))" 2>/dev/null || echo "Unknown error")
        echo -e "${RED}❌ 동기화 실패: $ERROR_MSG${NC}"
        echo ""
      fi
    else
      echo -e "${RED}❌ 동기화 실패 (HTTP $HTTP_CODE)${NC}"
      echo ""
    fi

  else
    # ============================================
    # Anonymous Mode (새로운 로직)
    # ============================================
    echo -e "${CYAN}🔄 Own It에 업로드 중... (익명 모드)${NC}"

    ENDPOINT="$API_URL/api/anonymous-reviews"

    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$ENDPOINT" \
      -H "Content-Type: application/json" \
      -d "$JSON_DATA")

    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')

    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
      if echo "$BODY" | python3 -c "import sys, json; exit(0 if json.load(sys.stdin).get('success') else 1)" 2>/dev/null; then
        REVIEW_URL=$(echo "$BODY" | python3 -c "import sys, json; print(json.load(sys.stdin)['data']['url'])" 2>/dev/null || echo "")
        EXPIRES_AT=$(echo "$BODY" | python3 -c "import sys, json; print(json.load(sys.stdin)['data']['expiresAt'])" 2>/dev/null || echo "")

        echo -e "${GREEN}✅ 익명 리뷰 생성 완료!${NC}"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo -e "${YELLOW}💡 웹에서 예쁘게 보고 싶으신가요?${NC}"
        echo ""
        echo "브라우저에서 타임라인과 통계를 확인할 수 있습니다:"
        echo -e "${BLUE}${REVIEW_URL}${NC}"
        echo ""
        echo -e "${YELLOW}⚠️  주의: 익명 리뷰는 24시간 후 자동 삭제됩니다${NC}"
        if [ -n "$EXPIRES_AT" ]; then
          echo "   만료 시간: $EXPIRES_AT"
        fi
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""

        # 브라우저 오픈 여부 물어보기
        read -p "지금 브라우저에서 보시겠습니까? (Y/n) " -n 1 -r
        echo ""

        if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
          echo -e "${CYAN}🌐 브라우저 열기...${NC}"

          # OS별 브라우저 오픈
          if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            open "$REVIEW_URL"
          elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Linux
            if command -v xdg-open &>/dev/null; then
              xdg-open "$REVIEW_URL"
            else
              echo -e "${YELLOW}⚠️  xdg-open을 찾을 수 없습니다. 직접 방문하세요:${NC}"
              echo "$REVIEW_URL"
            fi
          elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
            # Windows Git Bash
            start "$REVIEW_URL"
          else
            echo -e "${YELLOW}⚠️  OS를 인식할 수 없습니다. 직접 방문하세요:${NC}"
            echo "$REVIEW_URL"
          fi

          echo ""
          echo -e "${GREEN}✅ 브라우저가 열렸습니다!${NC}"
          echo ""
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo -e "${CYAN}💼 계속 이렇게 보고 싶으신가요?${NC}"
          echo ""
          echo "GitHub로 로그인하면:"
          echo "  ✓ 무제한 저장"
          echo "  ✓ 언제든 확인 가능"
          echo "  ✓ 자동 포트폴리오 생성"
          echo ""
          echo -e "회원가입: ${BLUE}${API_URL}${NC}"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo ""
        fi

        SYNC_SUCCESS=true
      else
        ERROR_MSG=$(echo "$BODY" | python3 -c "import sys, json; print(json.load(sys.stdin).get('error', 'Unknown error'))" 2>/dev/null || echo "Unknown error")
        echo -e "${RED}❌ 업로드 실패: $ERROR_MSG${NC}"
        echo ""
      fi
    else
      echo -e "${RED}❌ 업로드 실패 (HTTP $HTTP_CODE)${NC}"
      echo ""
    fi
  fi
fi

# Print commit timeline
echo "## Timeline"
echo ""
echo "$GIT_LOG" | grep '^COMMIT:' | while IFS='|' read -r commit_line; do
  SHA=$(echo "$commit_line" | cut -d'|' -f1 | sed 's/COMMIT://')
  DATETIME=$(echo "$commit_line" | cut -d'|' -f2)
  TIME=$(echo "$DATETIME" | awk '{print $2}' | cut -d':' -f1,2)
  MSG=$(echo "$commit_line" | cut -d'|' -f3)

  # Get main directory for this commit
  MAIN_DIR=$(git show --stat --format="" "$SHA" 2>/dev/null | head -5 | awk '{print $1}' | xargs -I{} dirname {} 2>/dev/null | sort | uniq -c | sort -rn | head -1 | awk '{print $2}' || echo ".")

  echo "[$TIME] $MSG ($MAIN_DIR)"
done

echo ""
echo "💡 주요 작업: $MAIN_AREAS"
echo ""
