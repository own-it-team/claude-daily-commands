# 🎯 Own It - Claude Code Custom Commands

> Git 기반 일일 작업 리뷰와 포트폴리오 자동 생성을 위한 Claude Code 커스텀 명령어

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Claude Code](https://img.shields.io/badge/Claude-Code-blue.svg)](https://claude.ai/code)

[English](./README-en.md) | 한국어

## 📌 소개

**Own It**은 개발자의 일일 작업을 자동으로 정리하고, 습관화를 돕고, 나아가 전문적인 포트폴리오로 전환할 수 있게 해주는 Claude Code 커스텀 명령어 모음입니다.

### 핵심 기능

- **📅 /dailyreview** - Git 커밋 기반 일일 작업 자동 요약
- **✅ /todo** - 코드 분석으로 다음 할 일 자동 추천
- **💼 /portfolio** - 작업 히스토리 기반 포트폴리오 생성 (준비 중)

## 🚀 빠른 시작

### 필수 요구사항

- [Claude Code](https://claude.ai/code) 설치
- Git 2.0 이상
- macOS / Linux / Windows (WSL)

### 설치 방법

#### 방법 1: 자동 설치 (권장)

```bash
git clone https://github.com/YOUR_USERNAME/owinit-custom-command.git
cd owinit-custom-command
./install.sh
```

#### 방법 2: 수동 설치

**프로젝트별 설치** (해당 프로젝트에서만 사용)
```bash
# 프로젝트 루트에서
mkdir -p .claude/commands
cp owinit-custom-command/.claude/commands/*.md .claude/commands/
```

**전역 설치** (모든 프로젝트에서 사용)
```bash
mkdir -p ~/.claude/commands
cp owinit-custom-command/.claude/commands/*.md ~/.claude/commands/
```

### 설치 확인

Claude Code를 실행하고 `/` 를 입력하면 다음 명령어들이 보여야 합니다:
- `/dailyreview`
- `/todo`
- `/portfolio`

## 📖 사용 가이드

### `/dailyreview` - 일일 작업 리뷰

Git 커밋 히스토리를 분석하여 하루 동안의 작업을 자동으로 요약합니다.

```bash
# 오늘 작업 요약
/dailyreview

# 어제 작업 요약
/dailyreview yesterday

# 최근 7일 요약
/dailyreview week

# 상세 diff 포함
/dailyreview --detailed
```

**출력 내용:**
- ✅ 커밋 통계 (개수, 변경 파일, 추가/삭제 줄)
- 📝 시간순 커밋 타임라인
- 💡 작업 패턴 분석
- 📊 파일별 변경 빈도

**실제 출력 예시:** [`examples/dailyreview-example.md`](./examples/dailyreview-example.md)

### `/todo` - 스마트 할 일 추천

코드베이스를 분석하여 미완성 작업과 개선 사항을 자동으로 발견합니다.

```bash
# 전체 프로젝트 분석
/todo

# 특정 디렉토리만
/todo @src/

# 긴급 항목만 표시
/todo --priority-only
```

**검색 항목:**
- 🔴 `TODO`, `FIXME`, `BUG` 코멘트
- 🟡 `console.log`, `debugger` 디버깅 코드
- 🔵 `NOTE`, `HACK` 개선 제안
- ⚡ Git diff 기반 미완성 작업 추론

**실제 출력 예시:** [`examples/todo-example.md`](./examples/todo-example.md)

### `/portfolio` - 포트폴리오 생성 (베타)

> ⚠️ 현재 베타 테스트 중 - 간단한 미리보기만 제공

```bash
/portfolio
```

Git 히스토리를 분석하여 간단한 마크다운 포트폴리오를 생성합니다.
전체 버전은 Own It 웹 플랫폼에서 제공 예정입니다.

## 🎯 사용 시나리오

### 시나리오 1: 일일 스탠드업 미팅 준비
```bash
# 오전에 실행
/dailyreview yesterday

# 어제 한 일을 빠르게 파악하고 공유
```

### 시나리오 2: 주간 회고 작성
```bash
# 금요일 오후에
/dailyreview week

# 한 주 동안의 성과를 정리하고 회고 문서 작성
```

### 시나리오 3: 작업 시작 전 우선순위 파악
```bash
# 작업 시작 전
/todo

# 긴급 항목부터 처리 시작
```

### 시나리오 4: 포트폴리오 업데이트
```bash
# 프로젝트 완료 후
/portfolio

# 간단한 프로젝트 소개서 생성
```

## 🔧 고급 사용법

### 명령어 조합

```bash
# 아침 루틴: 어제 리뷰 + 오늘 할 일
/dailyreview yesterday
/todo --priority-only

# 주간 정리: 주간 리뷰 + 전체 할 일
/dailyreview week
/todo
```

### 커스터마이징

각 명령어 파일(`.claude/commands/*.md`)을 직접 수정하여 출력 형식이나 분석 로직을 변경할 수 있습니다.

예시: `dailyreview.md` 파일에서 출력 포맷 수정
```markdown
## 📝 커밋 타임라인
→ 원하는 형식으로 변경
```

## 🛠️ 문제 해결

### 명령어가 안 보여요
```bash
# Claude Code 재시작
# 또는 명령어 파일 위치 확인
ls -la ~/.claude/commands/
```

### Git 저장소가 아니라는 오류
```bash
# 현재 디렉토리가 Git 저장소인지 확인
git status

# Git 저장소가 아니라면 초기화
git init
```

### 커밋이 없다고 나와요
```bash
# 오늘 커밋이 있는지 확인
git log --since="today 00:00" --oneline

# 다른 날짜로 시도
/dailyreview yesterday
/dailyreview week
```

## 🗺️ 로드맵

### v0.1.0 (현재) - MVP
- ✅ `/dailyreview` 기본 기능
- ✅ `/todo` 기본 기능
- ✅ `/portfolio` 스텁

### v0.2.0 - 개선
- [ ] 다국어 지원 (영어, 일본어)
- [ ] 커스텀 출력 템플릿
- [ ] 성능 최적화

### v1.0.0 - Own It 플랫폼 연동
- [ ] Own It 웹 서버 연동
- [ ] OAuth2 인증
- [ ] `/portfolio` 전체 기능
  - AI 기반 프로젝트 분석
  - 시각화된 통계
  - PDF/HTML 내보내기
- [ ] `/export` - 다양한 형식 내보내기
- [ ] `/sync` - 자동 동기화

## 🤝 기여하기

이슈와 PR을 환영합니다!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 라이선스

MIT License - 자유롭게 사용하세요!

## 💬 문의 및 지원

- **Issues**: [GitHub Issues](https://github.com/YOUR_USERNAME/owinit-custom-command/issues)
- **Discussions**: [GitHub Discussions](https://github.com/YOUR_USERNAME/owinit-custom-command/discussions)
- **Email**: your-email@example.com (준비 중)

## 🙏 감사의 말

- [Claude Code](https://claude.ai/code) - Anthropic의 AI 코딩 도구
- 모든 오픈소스 기여자들

---

**Made with ❤️ for developers who want to Own It**

⭐ 이 프로젝트가 도움이 되었다면 Star를 눌러주세요!
