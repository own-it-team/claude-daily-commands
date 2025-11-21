# Backend & Frontend Integration Guide

AI Report feature를 완성하기 위한 Backend와 Frontend 작업 가이드입니다.

---

## 📋 Overview

CLI에서 이제 `aiReport` 필드를 JSON 데이터와 함께 전송합니다.
Backend와 Frontend에서 이 필드를 받아서 저장하고 표시해야 합니다.

---

## 🔧 Backend Tasks

### 1. Database Schema Update

#### Drizzle Schema (예상 위치: `apps/api/src/db/schema.ts`)

```typescript
// daily_reviews 테이블에 필드 추가
export const dailyReviews = pgTable("daily_reviews", {
  // ... 기존 필드들
  id: serial("id").primaryKey(),
  userId: integer("user_id").references(() => users.id),
  date: date("date").notNull(),
  repositoryId: integer("repository_id"),
  commits: integer("commits"),
  files: integer("files"),
  additions: integer("additions"),
  deletions: integer("deletions"),
  data: json("data"),

  // ✨ 새로운 필드
  aiReport: text("ai_report"),  // AI-generated report text

  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

// anonymous_reviews 테이블에도 동일하게 추가
export const anonymousReviews = pgTable("anonymous_reviews", {
  // ... 기존 필드들
  id: varchar("id", { length: 255 }).primaryKey(),
  date: date("date").notNull(),
  commits: integer("commits"),
  files: integer("files"),
  additions: integer("additions"),
  deletions: integer("deletions"),
  data: json("data"),

  // ✨ 새로운 필드
  aiReport: text("ai_report"),  // AI-generated report text

  expiresAt: timestamp("expires_at").notNull(),
  viewCount: integer("view_count").default(0),
  createdAt: timestamp("created_at").defaultNow(),
});
```

#### Migration 생성

```bash
cd apps/api
pnpm db:generate
pnpm db:migrate
```

---

### 2. TypeScript Types Update

#### Types 파일 (예상 위치: `apps/api/src/types/reviews.ts`)

```typescript
export interface DailyReviewData {
  date: string;
  stats: {
    commits: number;
    files: number;
    additions: number;
    deletions: number;
  };
  commits: Array<{
    sha: string;
    time: string;
    message: string;
    author: string;
    files: string[];
    additions: number;
    deletions: number;
  }>;
  analysis: {
    mainAreas: string[];
    fileChanges: Record<string, number>;
  };
  repository?: {
    path: string;
    remote: string;
  };

  // ✨ 새로운 필드
  aiReport?: string;  // AI-generated markdown report
}

export interface CreateDailyReviewDTO {
  date: string;
  repositoryId?: number;
  stats: ReviewStats;
  data: DailyReviewData;

  // ✨ 새로운 필드
  aiReport?: string;
}
```

---

### 3. API Endpoint Updates

#### `/api/daily-reviews/sync` (인증 모드)

```typescript
// 예상 위치: apps/api/src/routes/daily-reviews.ts

router.post("/sync", authenticate, async (req, res) => {
  try {
    const { date, stats, commits, analysis, repository, aiReport } = req.body;

    // Validation
    const schema = z.object({
      date: z.string(),
      stats: z.object({
        commits: z.number(),
        files: z.number(),
        additions: z.number(),
        deletions: z.number(),
      }),
      commits: z.array(z.any()),
      analysis: z.object({
        mainAreas: z.array(z.string()),
        fileChanges: z.record(z.number()),
      }),
      repository: z.object({
        path: z.string(),
        remote: z.string(),
      }).optional(),

      // ✨ 새로운 필드
      aiReport: z.string().optional(),
    });

    const validated = schema.parse(req.body);

    // Upsert logic
    const review = await db
      .insert(dailyReviews)
      .values({
        userId: req.user.id,
        date: validated.date,
        repositoryId: repository?.id,
        commits: validated.stats.commits,
        files: validated.stats.files,
        additions: validated.stats.additions,
        deletions: validated.stats.deletions,
        data: validated,
        aiReport: validated.aiReport,  // ✨ 저장
      })
      .onConflictDoUpdate({
        target: [dailyReviews.userId, dailyReviews.date],
        set: {
          commits: validated.stats.commits,
          files: validated.stats.files,
          additions: validated.stats.additions,
          deletions: validated.stats.deletions,
          data: validated,
          aiReport: validated.aiReport,  // ✨ 업데이트
          updatedAt: new Date(),
        },
      })
      .returning();

    res.json({
      success: true,
      data: review[0],
    });
  } catch (error) {
    console.error("Sync error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to sync daily review",
    });
  }
});
```

#### `/api/anonymous-reviews` (익명 모드)

```typescript
// 예상 위치: apps/api/src/routes/anonymous-reviews.ts

router.post("/", async (req, res) => {
  try {
    const { date, stats, commits, analysis, aiReport } = req.body;

    // Validation
    const schema = z.object({
      date: z.string(),
      stats: z.object({
        commits: z.number(),
        files: z.number(),
        additions: z.number(),
        deletions: z.number(),
      }),
      commits: z.array(z.any()),
      analysis: z.object({
        mainAreas: z.array(z.string()),
        fileChanges: z.record(z.number()),
      }),

      // ✨ 새로운 필드
      aiReport: z.string().optional(),
    });

    const validated = schema.parse(req.body);

    // Generate unique ID
    const id = nanoid(12);

    // Set expiration (24 hours)
    const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000);

    // Create anonymous review
    const review = await db
      .insert(anonymousReviews)
      .values({
        id,
        date: validated.date,
        commits: validated.stats.commits,
        files: validated.stats.files,
        additions: validated.stats.additions,
        deletions: validated.stats.deletions,
        data: validated,
        aiReport: validated.aiReport,  // ✨ 저장
        expiresAt,
        viewCount: 0,
      })
      .returning();

    const reviewUrl = `${process.env.WEB_URL}/reviews/${id}`;

    res.status(201).json({
      success: true,
      data: {
        id,
        url: reviewUrl,
        expiresAt: expiresAt.toISOString(),
      },
    });
  } catch (error) {
    console.error("Anonymous review error:", error);
    res.status(500).json({
      success: false,
      error: "Failed to create anonymous review",
    });
  }
});
```

---

### 4. Response DTO Update

조회 API에서도 `aiReport` 필드를 포함하도록:

```typescript
// GET /api/daily-reviews/:id
router.get("/:id", authenticate, async (req, res) => {
  const review = await db
    .select()
    .from(dailyReviews)
    .where(
      and(
        eq(dailyReviews.id, parseInt(req.params.id)),
        eq(dailyReviews.userId, req.user.id)
      )
    )
    .limit(1);

  if (review.length === 0) {
    return res.status(404).json({
      success: false,
      message: "Review not found",
    });
  }

  res.json({
    success: true,
    data: {
      ...review[0],
      // aiReport 필드 자동 포함
    },
  });
});

// GET /api/anonymous-reviews/:id
router.get("/:id", async (req, res) => {
  const review = await db
    .select()
    .from(anonymousReviews)
    .where(eq(anonymousReviews.id, req.params.id))
    .limit(1);

  if (review.length === 0) {
    return res.status(404).json({
      success: false,
      error: "Review not found or expired",
    });
  }

  // Increment view count
  await db
    .update(anonymousReviews)
    .set({ viewCount: review[0].viewCount + 1 })
    .where(eq(anonymousReviews.id, req.params.id));

  res.json({
    success: true,
    data: {
      ...review[0],
      // aiReport 필드 자동 포함
    },
  });
});
```

---

## 🎨 Frontend Tasks

### 1. Type Definitions

#### Types 파일 (예상 위치: `apps/web/types/reviews.ts`)

```typescript
export interface DailyReview {
  id: number;
  userId: number;
  date: string;
  repositoryId?: number;
  commits: number;
  files: number;
  additions: number;
  deletions: number;
  data: {
    date: string;
    stats: ReviewStats;
    commits: Commit[];
    analysis: Analysis;
    repository?: Repository;
    aiReport?: string;  // ✨ 새로운 필드
  };
  aiReport?: string;  // ✨ 새로운 필드 (top-level)
  createdAt: string;
  updatedAt: string;
}

export interface AnonymousReview {
  id: string;
  date: string;
  commits: number;
  files: number;
  additions: number;
  deletions: number;
  data: {
    // ... 위와 동일
    aiReport?: string;  // ✨ 새로운 필드
  };
  aiReport?: string;  // ✨ 새로운 필드 (top-level)
  expiresAt: string;
  viewCount: number;
  createdAt: string;
}
```

---

### 2. AI Report Component

#### 새 컴포넌트 생성 (`apps/web/components/reviews/AIReportCard.tsx`)

```tsx
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Copy, Sparkles } from "lucide-react";
import { useState } from "react";
import ReactMarkdown from "react-markdown";

interface AIReportCardProps {
  report: string;
}

export function AIReportCard({ report }: AIReportCardProps) {
  const [copied, setCopied] = useState(false);

  const handleCopy = async () => {
    await navigator.clipboard.writeText(report);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <Card className="border-primary/20">
      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-4">
        <CardTitle className="flex items-center gap-2">
          <Sparkles className="h-5 w-5 text-primary" />
          AI-Generated Report
        </CardTitle>
        <Button
          variant="ghost"
          size="sm"
          onClick={handleCopy}
          className="text-muted-foreground hover:text-foreground"
        >
          {copied ? "Copied!" : <Copy className="h-4 w-4" />}
        </Button>
      </CardHeader>
      <CardContent>
        <div className="prose prose-sm dark:prose-invert max-w-none">
          <ReactMarkdown>{report}</ReactMarkdown>
        </div>
      </CardContent>
    </Card>
  );
}
```

---

### 3. Review Detail Page Update

#### 인증 모드 (`apps/web/app/dashboard/reviews/[id]/page.tsx`)

```tsx
import { AIReportCard } from "@/components/reviews/AIReportCard";

export default async function ReviewDetailPage({ params }: { params: { id: string } }) {
  const review = await getReview(params.id);

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="max-w-4xl mx-auto space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <h1 className="text-3xl font-bold">Daily Review</h1>
          <p className="text-muted-foreground">{review.date}</p>
        </div>

        {/* Stats */}
        <Card>
          <CardContent className="pt-6">
            <div className="grid grid-cols-4 gap-4">
              <StatItem label="Commits" value={review.commits} />
              <StatItem label="Files" value={review.files} />
              <StatItem label="Additions" value={`+${review.additions}`} />
              <StatItem label="Deletions" value={`-${review.deletions}`} />
            </div>
          </CardContent>
        </Card>

        {/* ✨ AI Report */}
        {review.aiReport && (
          <AIReportCard report={review.aiReport} />
        )}

        {/* Timeline */}
        <Card>
          <CardHeader>
            <CardTitle>Commit Timeline</CardTitle>
          </CardHeader>
          <CardContent>
            <CommitTimeline commits={review.data.commits} />
          </CardContent>
        </Card>

        {/* Analysis */}
        <Card>
          <CardHeader>
            <CardTitle>Analysis</CardTitle>
          </CardHeader>
          <CardContent>
            <AnalysisView analysis={review.data.analysis} />
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
```

#### 익명 모드 (`apps/web/app/reviews/[id]/page.tsx`)

```tsx
import { AIReportCard } from "@/components/reviews/AIReportCard";

export default async function AnonymousReviewPage({ params }: { params: { id: string } }) {
  const review = await getAnonymousReview(params.id);

  return (
    <div className="container mx-auto px-4 py-8">
      {/* Top CTA Banner */}
      <CTABanner />

      <div className="max-w-4xl mx-auto space-y-6 mt-8">
        {/* Header */}
        <div className="flex items-center justify-between">
          <h1 className="text-3xl font-bold">Daily Review</h1>
          <div className="flex flex-col items-end gap-1">
            <p className="text-muted-foreground">{review.date}</p>
            <p className="text-xs text-yellow-600">
              Expires in {calculateTimeLeft(review.expiresAt)}
            </p>
          </div>
        </div>

        {/* Stats */}
        <StatsCard review={review} />

        {/* ✨ AI Report */}
        {review.aiReport && (
          <>
            <AIReportCard report={review.aiReport} />
            {/* CTA after AI report */}
            <Card className="bg-primary/5 border-primary/20">
              <CardContent className="pt-6">
                <p className="text-center text-sm text-muted-foreground mb-4">
                  AI 리포트가 마음에 드시나요? 회원가입하면 모든 리뷰를 영구 보관할 수 있습니다!
                </p>
                <div className="flex justify-center">
                  <Button asChild>
                    <a href="/auth/github-app">GitHub로 시작하기</a>
                  </Button>
                </div>
              </CardContent>
            </Card>
          </>
        )}

        {/* Timeline */}
        <CommitTimelineCard commits={review.data.commits} />

        {/* Analysis */}
        <AnalysisCard analysis={review.data.analysis} />
      </div>

      {/* Bottom CTA Banner */}
      <CTABanner />
    </div>
  );
}
```

---

### 4. Dashboard List View

대시보드에서 AI 리포트가 있는 리뷰 표시:

```tsx
// apps/web/app/dashboard/page.tsx

<div className="grid gap-4">
  {reviews.map((review) => (
    <Card key={review.id}>
      <CardContent className="pt-6">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4">
            <div>
              <h3 className="font-semibold">{review.date}</h3>
              <p className="text-sm text-muted-foreground">
                {review.commits} commits · {review.files} files
              </p>
            </div>

            {/* ✨ AI Report Badge */}
            {review.aiReport && (
              <div className="flex items-center gap-1 px-2 py-1 rounded-full bg-primary/10 text-primary text-xs">
                <Sparkles className="h-3 w-3" />
                AI Report
              </div>
            )}
          </div>

          <Button variant="ghost" asChild>
            <Link href={`/dashboard/reviews/${review.id}`}>
              View →
            </Link>
          </Button>
        </div>
      </CardContent>
    </Card>
  ))}
</div>
```

---

### 5. Dependencies 추가

```bash
cd apps/web

# Markdown 렌더링
pnpm add react-markdown remark-gfm

# 아이콘
pnpm add lucide-react
```

---

## ✅ Checklist

### Backend
- [ ] Database schema에 `aiReport` 필드 추가 (text)
- [ ] Migration 생성 및 실행
- [ ] TypeScript types 업데이트
- [ ] POST `/api/daily-reviews/sync` - `aiReport` 받아서 저장
- [ ] POST `/api/anonymous-reviews` - `aiReport` 받아서 저장
- [ ] GET endpoints - `aiReport` 포함해서 응답
- [ ] Validation schema에 `aiReport` 추가 (optional)

### Frontend
- [ ] Type definitions 업데이트
- [ ] `AIReportCard` 컴포넌트 생성
- [ ] Review detail page - AI report 표시
- [ ] Anonymous review page - AI report + CTA
- [ ] Dashboard list - AI report badge
- [ ] `react-markdown` dependency 설치
- [ ] Copy button 기능 구현
- [ ] Responsive design 확인

---

## 🧪 Testing

### Backend Test

```bash
# API 테스트 (with aiReport)
curl -X POST http://localhost:4000/api/daily-reviews/sync \
  -H "Authorization: Bearer own_it_sk_xxx" \
  -H "Content-Type: application/json" \
  -d '{
    "date": "2025-11-13",
    "stats": {
      "commits": 3,
      "files": 12,
      "additions": 245,
      "deletions": 87
    },
    "commits": [],
    "analysis": {
      "mainAreas": ["scripts"],
      "fileChanges": {}
    },
    "aiReport": "## Summary\nTest report...\n\n## Key Achievements\n- Feature 1\n- Feature 2"
  }'

# 응답 확인
{
  "success": true,
  "data": {
    "id": 123,
    "aiReport": "## Summary\nTest report...",
    ...
  }
}
```

### Frontend Test

1. CLI에서 Claude API 키 설정
2. `/dailyreview-sync` 실행
3. 브라우저에서 리뷰 페이지 확인
4. AI Report 섹션이 표시되는지 확인
5. Copy 버튼 동작 확인
6. 익명/인증 모드 모두 테스트

---

## 📝 Notes

### Optional 필드

`aiReport`는 optional입니다:
- Claude API 키가 없으면 생성 안 됨
- API 호출 실패 시 생성 안 됨
- 기존 리뷰는 `aiReport: null`

### Backward Compatibility

- 기존 데이터: `aiReport: null` or `undefined`
- 새 데이터: `aiReport: string` or `null`
- Frontend에서 조건부 렌더링으로 처리

### Performance

- AI report는 text 타입 (무제한)
- 실제로는 ~800 words (2-3KB)
- 인덱싱 불필요 (검색 대상 아님)

---

**작성일:** 2025-11-13
**CLI 완료 상태:** ✅ 완료
**Backend 작업 필요:** ⏳ 대기 중
**Frontend 작업 필요:** ⏳ 대기 중
