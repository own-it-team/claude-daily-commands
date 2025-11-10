# 🚀 GitHub 배포 가이드

이 파일을 따라하면 5분 안에 배포 완료됩니다!

---

## ✅ Step 1: GitHub에서 저장소 생성 (2분)

### 1.1 GitHub 웹사이트 접속
브라우저에서 열기: https://github.com/new

### 1.2 저장소 설정
다음 정보를 입력하세요:

**Repository name:**
```
claude-daily-commands
```

**Description:**
```
⚡ Fast and concise Claude Code commands for daily work review and todo management
```

**Visibility:**
- ✅ **Public** 선택 (필수 - 원클릭 설치를 위해)

**Initialize this repository with:**
- ❌ Add a README file (체크 해제 - 이미 로컬에 있음)
- ❌ Add .gitignore (체크 해제 - 이미 로컬에 있음)
- ❌ Choose a license (체크 해제 - 이미 MIT 추가됨)

### 1.3 생성 버튼 클릭
**"Create repository"** 버튼 클릭

---

## ✅ Step 2: 로컬에서 Push (1분)

GitHub 저장소가 생성되면 다음 명령어를 터미널에서 실행하세요:

### 2.1 Remote 연결
```bash
git remote add origin https://github.com/wineny/claude-daily-commands.git
```

### 2.2 브랜치 이름 변경 (master → main)
```bash
git branch -M main
```

### 2.3 Push
```bash
git push -u origin main
```

**완료!** 이제 https://github.com/wineny/claude-daily-commands 에서 확인할 수 있습니다.

---

## ✅ Step 3: 저장소 설정 최적화 (2분)

### 3.1 About 섹션 설정
1. GitHub 저장소 페이지 우측의 **⚙️ (톱니바퀴)** 클릭
2. 다음 정보 입력:

**Description:**
```
⚡ Fast and concise Claude Code commands for daily work review and todo management
```

**Website:**
```
https://claude.ai/code
```

**Topics (태그):**
```
claude-code
productivity
developer-tools
git
workflow
automation
daily-review
todo-management
```

3. **"Save changes"** 클릭

### 3.2 Repository settings
1. 상단 **Settings** 탭 클릭
2. 왼쪽 **General** 메뉴에서:
   - ✅ **Issues** 활성화
   - ✅ **Discussions** 활성화 (선택)
   - ✅ **Wiki** 비활성화 (README만 사용)

---

## ✅ Step 4: 원클릭 설치 테스트 (1분)

터미널에서 다른 디렉토리로 이동해서 테스트:

```bash
# 다른 디렉토리로 이동
cd /tmp

# 원클릭 설치 테스트
curl -fsSL https://raw.githubusercontent.com/wineny/claude-daily-commands/main/install.sh | bash
```

**예상 출력:**
```
================================
  Own It - Custom Commands
  Claude Code Installer
================================

Installation options:
  1) Global (all projects - recommended)
  2) Local (current project only)
  3) Cancel

Choose installation type (1/2/3):
```

`1`을 입력하고 Enter → `y`를 입력하고 Enter

**설치 완료 메시지가 나오면 성공!** ✅

---

## ✅ Step 5: (선택) 첫 Release 생성

### 5.1 Release 페이지 이동
GitHub 저장소에서:
1. 우측 **Releases** 클릭
2. **"Create a new release"** 클릭

### 5.2 Release 정보 입력

**Choose a tag:**
```
v0.2.0-beta
```
"Create new tag: v0.2.0-beta on publish" 선택

**Release title:**
```
v0.2.0-beta - v2 Optimized Commands
```

**Describe this release:**
```markdown
## 🎉 v0.2.0-beta - v2 최적화 버전

### ✨ 새로운 기능

#### `/dailyreviewv2`
- 80% 짧은 출력 (~50줄 → ~10줄)
- 85% 적은 승인 요청 (8-14회 → 1-3회)
- 73% 빠른 실행 (~30초 → ~8초)

#### `/todov2`
- 70% 짧은 출력 (~70줄 → ~15줄)
- 60% 적은 승인 요청 (10-14회 → 3-5회)
- 50% 빠른 실행 (~20초 → ~10초)

### 📦 설치 방법

**원클릭 설치:**
```bash
curl -fsSL https://raw.githubusercontent.com/wineny/claude-daily-commands/main/install.sh | bash
```

### 📚 문서
- [README](https://github.com/wineny/claude-daily-commands#readme)
- [V2 Test Guide](./V2_TEST_GUIDE.md)
- [V2 Changelog](./V2_CHANGELOG.md)

### 🙏 감사합니다!
베타 테스트에 참여해주셔서 감사합니다. 피드백은 [Issues](https://github.com/wineny/claude-daily-commands/issues)에 남겨주세요!
```

### 5.3 Publish
**"Publish release"** 클릭

---

## 🎉 완료!

이제 다음이 가능합니다:

### 사용자들이 할 일:
```bash
# 한 줄로 설치
curl -fsSL https://raw.githubusercontent.com/wineny/claude-daily-commands/main/install.sh | bash

# Claude Code 재시작 후 사용
/dailyreviewv2
/todov2
```

### 앞으로 업데이트 하는 방법:
```bash
# 1. 로컬에서 수정
# 2. Commit
git add .
git commit -m "feat: New feature"

# 3. Push
git push

# 4. 사용자는 다시 설치 스크립트 실행하면 최신 버전 받음
```

---

## 📢 홍보 방법 (선택)

### 1. Reddit
- r/claudeai
- r/productivity
- r/devtools

### 2. Twitter/X
```
Just released Claude Daily Commands v2! ⚡

🚀 80% shorter output
⏱️ 85% fewer approvals
💨 73% faster execution

One-line install:
curl -fsSL https://raw.githubusercontent.com/wineny/claude-daily-commands/main/install.sh | bash

#ClaudeCode #Productivity
```

### 3. Hacker News (Show HN)
제목: "Show HN: Claude Daily Commands – Fast daily review and todo management"

### 4. Dev.to / Medium
블로그 포스트 작성 (README 기반)

---

**축하합니다! 배포 완료! 🎉**

문제가 있으면 Issues에 올려주세요: https://github.com/wineny/claude-daily-commands/issues
