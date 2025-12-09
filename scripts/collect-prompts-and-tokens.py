#!/usr/bin/env python3
"""
Claude Code 세션 로그에서 프롬프트와 토큰 사용량을 수집하는 스크립트

Usage:
    export REPO_PATH=$(git rev-parse --show-toplevel)
    export TARGET_DATE="2025-12-09"
    python3 collect-prompts-and-tokens.py /tmp/claude_prompts_$$.jsonl
"""

import json
import re
import os
import sys


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 collect-prompts-and-tokens.py <jsonl_file>", file=sys.stderr)
        sys.exit(1)

    repo_path = os.environ.get('REPO_PATH', '')
    target_date = os.environ.get('TARGET_DATE', '')
    jsonl_file = sys.argv[1]

    # 민감한 데이터 마스킹 패턴
    sensitive_patterns = [
        (r'sk-[a-zA-Z0-9_-]{20,}', '***API_KEY***'),
        (r'password[\"\']?\s*[:=]\s*[\"\']?[^\"\s]+', 'password: ***'),
        (r'api[_-]?key[\"\']?\s*[:=]\s*[\"\']?[^\"\s]+', 'api_key: ***'),
        (r'Bearer\s+[a-zA-Z0-9._-]+', 'Bearer ***'),
    ]

    def mask_sensitive(text):
        """민감한 정보 마스킹"""
        for pattern, replacement in sensitive_patterns:
            text = re.sub(pattern, replacement, text, flags=re.IGNORECASE)
        return text

    def extract_text(content):
        """content에서 텍스트 추출 (문자열 또는 리스트)"""
        if isinstance(content, str):
            return content
        elif isinstance(content, list):
            texts = []
            for item in content:
                if isinstance(item, dict) and item.get('type') == 'text':
                    texts.append(item.get('text', ''))
            return ' '.join(texts)
        return ''

    # 수집 데이터
    prompts = []
    total_input_tokens = 0
    total_output_tokens = 0
    total_cache_creation_tokens = 0
    total_cache_read_tokens = 0

    # JSONL 파일 처리
    try:
        with open(jsonl_file, 'r') as f:
            for line in f:
                try:
                    d = json.loads(line)
                    msg_type = d.get('type')
                    cwd = d.get('cwd') or ''

                    # 프로젝트 경로 필터링
                    if not repo_path or not cwd.startswith(repo_path):
                        continue

                    # 날짜 필터링
                    ts = (d.get('timestamp') or '')[:10]
                    if ts != target_date:
                        continue

                    # 사용자 프롬프트 수집
                    if msg_type == 'user':
                        msg = d.get('message') or {}
                        content = msg.get('content', '')
                        text = extract_text(content)
                        # 의미있는 프롬프트만 수집 (50자 이상, 단순 응답 제외)
                        if len(text) > 50 and text.strip() not in ['응', 'ㅇㅇ', '확인', 'ok', 'yes', 'no']:
                            prompts.append(mask_sensitive(text))

                    # 어시스턴트 응답에서 토큰 사용량 수집
                    elif msg_type == 'assistant':
                        msg = d.get('message') or {}
                        usage = msg.get('usage') or {}

                        total_input_tokens += usage.get('input_tokens', 0)
                        total_output_tokens += usage.get('output_tokens', 0)
                        total_cache_creation_tokens += usage.get('cache_creation_input_tokens', 0)
                        total_cache_read_tokens += usage.get('cache_read_input_tokens', 0)

                except json.JSONDecodeError:
                    continue
                except Exception:
                    continue
    except FileNotFoundError:
        pass

    # 프롬프트 출력 (최대 30개)
    for p in prompts[-30:]:
        print('---PROMPT---')
        print(p[:1000])

    # 토큰 사용량 출력
    print('---TOKEN_USAGE---')
    print(json.dumps({
        'inputTokens': total_input_tokens,
        'outputTokens': total_output_tokens,
        'cacheCreationTokens': total_cache_creation_tokens,
        'cacheReadTokens': total_cache_read_tokens
    }))


if __name__ == '__main__':
    main()
