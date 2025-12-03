# Daily Review 업데이트 가이드

## 🚀 빠른 업데이트 (권장)

### 자동 업데이트 강제 실행
```bash
rm -f ~/.claude-daily-commands/.last-update-check
/dailyreview-sync
```
다음 실행 시 자동으로 최신 버전이 다운로드됩니다.

---

## 📦 수동 업데이트

### 방법 1: curl로 직접 다운로드
```bash
curl -sL https://raw.githubusercontent.com/wineny/claude-daily-commands/main/.claude/commands/dailyreview-sync.md \
  -o ~/.claude/commands/dailyreview-sync.md
```

### 방법 2: wget 사용
```bash
wget -O ~/.claude/commands/dailyreview-sync.md \
  https://raw.githubusercontent.com/wineny/claude-daily-commands/main/.claude/commands/dailyreview-sync.md
```

### 방법 3: Git clone (개발자용)
```bash
cd ~/development
git clone https://github.com/wineny/claude-daily-commands.git
cp claude-daily-commands/.claude/commands/dailyreview-sync.md ~/.claude/commands/
```

---

## ✅ 업데이트 확인

```bash
# 버전 정보 확인 (파일 내용 확인)
head -20 ~/.claude/commands/dailyreview-sync.md

# 실행 테스트
/dailyreview-sync
```

---

## 🔧 문제 해결

### "command not found" 오류
```bash
# 명령어 디렉토리 확인
ls -la ~/.claude/commands/

# 파일이 없으면 재설치
mkdir -p ~/.claude/commands
curl -sL https://raw.githubusercontent.com/wineny/claude-daily-commands/main/.claude/commands/dailyreview-sync.md \
  -o ~/.claude/commands/dailyreview-sync.md
```

### 설정 파일 초기화
```bash
# 기존 설정 백업
cp ~/.claude-daily-commands/config.json ~/.claude-daily-commands/config.json.backup

# 새 설정 생성
cat > ~/.claude-daily-commands/config.json << 'EOF'
{
  "ownit_api_key": "own_it_sk_xxx",
  "ownit_api_url": "https://api.own-it.dev"
}
EOF
```

---

## 📋 변경 사항 (v2.0)

### 새로운 기능
- ✅ **운영 서버 지원**: `https://api.own-it.dev` 연동
- ✅ **주간 동기화**: `week` 옵션으로 7일 각각 처리
- ✅ **프롬프트 인사이트**: 효과적인 프롬프트 자동 분석
- ✅ **자동 업데이트**: 하루 1회 자동 버전 체크
- ✅ **환경 분리**: `--local` 플래그로 로컬/운영 전환

### 주요 변경
- API URL: `localhost:4000` → `api.own-it.dev` (기본값)
- config.json에 `ownit_api_url` 필드 추가
- 프롬프트 인사이트 데이터 구조 변경 (`title`, `originalPrompt`, `whyGood`)

---

## 🆘 도움이 필요하신가요?

- GitHub Issues: https://github.com/wineny/claude-daily-commands/issues
- 문서: https://github.com/wineny/claude-daily-commands/blob/main/README.md
