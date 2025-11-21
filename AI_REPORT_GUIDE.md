# AI Report Generation Guide

## Overview

Daily Review now includes AI-powered report generation using Claude API. When enabled, Claude analyzes your Git commit data and generates insightful daily review reports automatically.

---

## Features

### What the AI Report Includes

1. **Summary**: 2-3 sentence overview of development focus
2. **Key Achievements**: Main accomplishments for the day
3. **Technical Highlights**: Notable patterns, refactorings, or improvements
4. **Recommendations**: Actionable suggestions for next steps

### Benefits

- Automatic analysis of commit patterns and code changes
- Professional summary of daily work
- Objective insights into development focus
- Actionable recommendations for improvement
- Shareable reports for team communication or portfolio

---

## Setup

### 1. Get Claude API Key

Visit [Anthropic Console](https://console.anthropic.com/) and:
1. Sign in or create an account
2. Navigate to API Keys section
3. Generate a new API key
4. Copy the key (starts with `sk-ant-`)

### 2. Configure CLI

Run the setup script:

```bash
cd ~/development/claude-daily-commands
./scripts/setup-ownit.sh
```

**Interactive Prompts:**
```
Enter your Own It API key: own_it_sk_abc123...

Enter API URL (default: http://localhost:4000): [Enter]

🤖 Claude AI Integration (Optional)
Claude API key enables AI-powered daily review reports

Enter Claude API key (or press Enter to skip): sk-ant-api03-xxx...
```

### 3. Verify Configuration

Check your config file:

```bash
cat ~/.claude-daily-commands/config.json
```

**Expected Output:**
```json
{
  "api_key": "own_it_sk_abc123...",
  "api_url": "http://localhost:4000",
  "claude_api_key": "sk-ant-api03-xxx..."
}
```

---

## Usage

### Generate AI Report with Daily Review

```bash
cd /path/to/your/project
/dailyreview-sync
```

**Expected Output:**
```
# 📅 Daily Review - 2025-11-13

**3개 커밋 | 12개 파일 | +245줄 -87줄**

🤖 AI 리포트 생성 중...
✅ AI 리포트 생성 완료

🔄 Own It에 동기화 중... (인증 모드)
✅ Own It 동기화 완료!
📊 대시보드: http://localhost:4000/dashboard/reviews/abc-123
```

### Without Claude API Key

If you haven't configured Claude API key:

```
💡 AI 리포트를 생성하려면 Claude API 키를 설정하세요
   설정 방법: ~/.claude-daily-commands/config.json에 'claude_api_key' 추가
```

The sync will continue normally, just without the AI-generated report.

---

## Technical Details

### Data Flow

```
Git Commits
    ↓
Python Parser (commit data → JSON)
    ↓
Claude API (analyze commits → generate report)
    ↓
Add aiReport to JSON
    ↓
Send to Backend (daily-reviews API)
    ↓
Store in Database
    ↓
Display in Frontend
```

### JSON Structure

The AI report is added to the JSON payload:

```json
{
  "date": "2025-11-13",
  "stats": {
    "commits": 3,
    "files": 12,
    "additions": 245,
    "deletions": 87
  },
  "commits": [ /* ... */ ],
  "analysis": {
    "mainAreas": ["scripts", "docs"],
    "fileChanges": { /* ... */ }
  },
  "aiReport": "## Summary\nFocused on CLI integration...\n\n## Key Achievements\n..."
}
```

### API Request Details

**Endpoint:** `https://api.anthropic.com/v1/messages`

**Headers:**
- `content-type: application/json`
- `x-api-key: <your-claude-api-key>`
- `anthropic-version: 2023-06-01`

**Model:** `claude-3-5-sonnet-20241022`

**Max Tokens:** 1024 (approximately 300 words)

---

## Backend Integration

### Required Schema Update

The backend needs to accept and store the `aiReport` field:

```typescript
// Example schema update
interface DailyReview {
  // ... existing fields
  aiReport?: string;  // AI-generated report text
}
```

### API Endpoints

Both authenticated and anonymous modes send the `aiReport` field:

**Authenticated:**
```bash
POST /api/daily-reviews/sync
Authorization: Bearer <api-key>
{
  "date": "2025-11-13",
  "stats": { /* ... */ },
  "aiReport": "..."  # ← New field
}
```

**Anonymous:**
```bash
POST /api/anonymous-reviews
{
  "date": "2025-11-13",
  "stats": { /* ... */ },
  "aiReport": "..."  # ← New field
}
```

---

## Frontend Display

### Recommended UI Components

1. **Report Section**: Dedicated section in review detail page
2. **Markdown Rendering**: Support markdown formatting in AI reports
3. **Collapsible View**: Allow expanding/collapsing report
4. **Copy Button**: Easy sharing of report text
5. **Optional Badge**: Indicate AI-generated content

### Example Layout

```
┌─────────────────────────────────────────┐
│ 📅 Daily Review - 2025-11-13            │
├─────────────────────────────────────────┤
│ Stats: 3 commits | 12 files | +245 -87 │
├─────────────────────────────────────────┤
│ 🤖 AI-Generated Report         [Copy]   │
│ ┌───────────────────────────────────┐   │
│ │ ## Summary                        │   │
│ │ Focused on CLI integration...     │   │
│ │                                   │   │
│ │ ## Key Achievements               │   │
│ │ - Completed anonymous mode        │   │
│ │ - Added AI report generation      │   │
│ │                                   │   │
│ │ ## Technical Highlights           │   │
│ │ ...                               │   │
│ │                                   │   │
│ │ ## Recommendations                │   │
│ │ ...                               │   │
│ └───────────────────────────────────┘   │
├─────────────────────────────────────────┤
│ ## Commit Timeline                      │
│ [15:30] feat: Add Claude API...         │
│ ...                                     │
└─────────────────────────────────────────┘
```

---

## Error Handling

### API Call Failures

The script gracefully handles failures:

```bash
⚠️  AI 리포트 생성 실패 (API 호출 오류)
```

**Behavior:**
- Continues with sync even if AI report fails
- Sends data to backend without `aiReport` field
- No interruption to normal workflow

### Response Parsing Errors

```bash
⚠️  AI 리포트 생성 실패 (응답 파싱 오류)
```

**Common Causes:**
- Malformed API response
- Network timeout
- Rate limiting

---

## Cost Considerations

### Claude API Pricing

- Model: Claude 3.5 Sonnet
- Tokens per report: ~1500 (input) + ~800 (output)
- Cost: Approximately $0.01-0.02 per report

**Monthly Estimate:**
- 20 working days × 1 report/day = ~$0.20-0.40/month
- Very cost-effective for individual developers

### Rate Limits

Claude API rate limits (as of 2024):
- Free tier: Limited requests/day
- Paid tier: Higher limits

Check [Anthropic Pricing](https://www.anthropic.com/pricing) for current rates.

---

## Troubleshooting

### "Invalid API key format"

**Problem:** Claude API key not recognized

**Solutions:**
1. Verify key starts with `sk-ant-`
2. Copy entire key without spaces
3. Re-generate key from console if expired

### "AI 리포트 생성 실패"

**Problem:** API call fails

**Solutions:**
1. Check internet connection
2. Verify API key is active
3. Check Claude API status page
4. Review rate limits

### "No commits found"

**Problem:** No Git commits to analyze

**Solutions:**
1. Ensure you're in a Git repository
2. Check date range (today, yesterday, week)
3. Verify commits exist: `git log --since="today 00:00"`

---

## Manual Configuration

If you prefer manual setup:

```bash
# Edit config file
nano ~/.claude-daily-commands/config.json

# Add claude_api_key field
{
  "api_key": "own_it_sk_...",
  "api_url": "http://localhost:4000",
  "claude_api_key": "sk-ant-api03-..."
}

# Save and test
cd /your/project
/dailyreview-sync
```

---

## Disabling AI Reports

### Temporary Disable

Simply don't add Claude API key during setup. The feature is optional.

### Remove API Key

```bash
# Edit config
jq 'del(.claude_api_key)' ~/.claude-daily-commands/config.json > /tmp/config.json
mv /tmp/config.json ~/.claude-daily-commands/config.json

# Or re-run setup without entering Claude key
./scripts/setup-ownit.sh
```

---

## Privacy & Security

### Data Handling

- **Git commits sent to Claude API**: Commit messages, file names, stats
- **No code content**: Only metadata is sent, not actual code
- **Temporary processing**: Claude doesn't store analysis after response
- **Secure transmission**: HTTPS encryption for API calls

### API Key Security

- Stored in `~/.claude-daily-commands/config.json` with `chmod 600` permissions
- Never committed to Git (user's `.gitignore` should exclude)
- Environment variable option available for CI/CD

---

## Advanced Usage

### Custom Prompts

To customize the AI report prompt, edit [sync-daily-review.sh:197](sync-daily-review.sh#L197):

```bash
PROMPT="Your custom prompt here...
- Date: $DATE
- Commits: $COMMIT_COUNT
..."
```

### Different Models

Change model in [sync-daily-review.sh:224](sync-daily-review.sh#L224):

```bash
"model": "claude-3-opus-20240229",  # or other models
```

### Longer Reports

Adjust max_tokens in [sync-daily-review.sh:224](sync-daily-review.sh#L224):

```bash
"max_tokens": 2048,  # for longer reports
```

---

## Examples

### Example AI Report Output

```markdown
## Summary
Today's work focused on implementing AI-powered report generation for the daily review CLI tool. The development involved integrating Claude API, updating the sync script to generate insightful reports, and ensuring backward compatibility with existing workflows.

## Key Achievements
- Successfully integrated Claude 3.5 Sonnet API for report generation
- Updated sync-daily-review.sh with AI report logic
- Modified setup script to support optional Claude API key configuration
- Maintained graceful fallback when AI generation is unavailable

## Technical Highlights
- Implemented robust error handling for API failures
- Used Python for JSON parsing and data manipulation
- Added secure API key storage with proper file permissions
- Ensured backward compatibility with existing backend schema

## Recommendations
- Consider adding user preference for report detail level
- Implement caching to reduce API calls for repeated analyses
- Add report templates for different development workflows
- Create frontend UI components to beautifully display AI reports
```

---

**Created:** 2025-11-13
**Version:** 1.0.0
**Status:** Production Ready
