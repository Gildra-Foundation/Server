#!/usr/bin/env python3
"""Validate the machine-checkable shape of a Codex delivery summary."""

from __future__ import annotations

import argparse
from pathlib import Path
import re
import sys


OUTCOME_RE = re.compile(
    r"^(?:Готово|Частично готово|Заблокировано|Done|Partially complete|Blocked)\b",
    re.IGNORECASE,
)
STATUS_RE = re.compile(
    r"^\s*(?:[-*]\s*)?(?:\*\*)?(Push|Deploy)(?:\*\*)?\s*:\s*"
    r"(?:да|нет|yes|no)\b",
    re.IGNORECASE,
)
NEXT_HEADING_RE = re.compile(
    r"^\s{0,3}(?:#{1,6}\s*)?(?:Дальше|Next(?:\s+steps)?)\s*:?\s*$",
    re.IGNORECASE,
)
NEXT_ITEM_RE = re.compile(r"^\s*\d+[.)]\s+\S+")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Check the concise Codex delivery-summary format."
    )
    parser.add_argument(
        "file",
        nargs="?",
        help="UTF-8 response file; omit it or use '-' to read stdin",
    )
    parser.add_argument(
        "--max-lines",
        type=int,
        default=30,
        help="maximum total lines (default: 30)",
    )
    parser.add_argument(
        "--min-next-steps",
        type=int,
        default=2,
        help="minimum numbered next steps (default: 2)",
    )
    parser.add_argument(
        "--max-next-steps",
        type=int,
        default=3,
        help="maximum numbered next steps (default: 3)",
    )
    return parser.parse_args()


def read_response(path: str | None) -> str:
    if path and path != "-":
        try:
            return Path(path).read_text(encoding="utf-8")
        except OSError as exc:
            raise SystemExit(f"INVALID: cannot read response file: {exc}") from exc
    return sys.stdin.read()


def validate(text: str, max_lines: int, min_steps: int, max_steps: int) -> list[str]:
    errors: list[str] = []
    lines = text.splitlines()
    nonempty = [(index, line.strip()) for index, line in enumerate(lines, 1) if line.strip()]

    if not nonempty:
        return ["response is empty"]
    if max_lines < 1:
        return ["--max-lines must be positive"]
    if len(lines) > max_lines:
        errors.append(f"response has {len(lines)} lines; maximum is {max_lines}")
    if not OUTCOME_RE.match(nonempty[0][1]):
        errors.append("first non-empty line must start with Готово, Частично готово, Заблокировано, Done, Partially complete, or Blocked")

    statuses = {match.group(1).lower() for line in lines if (match := STATUS_RE.match(line))}
    for required in ("push", "deploy"):
        if required not in statuses:
            errors.append(f"missing explicit {required.title()}: да/нет status")

    heading_index = next(
        (index for index, line in enumerate(lines) if NEXT_HEADING_RE.match(line)),
        None,
    )
    if heading_index is None:
        errors.append("missing Дальше: or Next steps: section")
    else:
        steps = sum(1 for line in lines[heading_index + 1 :] if NEXT_ITEM_RE.match(line))
        if not min_steps <= steps <= max_steps:
            errors.append(
                f"next-step section has {steps} numbered options; expected {min_steps}-{max_steps}"
            )
    return errors


def main() -> int:
    args = parse_args()
    if args.min_next_steps < 0 or args.max_next_steps < args.min_next_steps:
        print("INVALID: next-step bounds are inconsistent", file=sys.stderr)
        return 1
    errors = validate(
        read_response(args.file),
        args.max_lines,
        args.min_next_steps,
        args.max_next_steps,
    )
    if errors:
        print("INVALID response format:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1
    print("OK: concise response format valid")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
