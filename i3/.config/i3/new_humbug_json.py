#!/usr/bin/env python3

import argparse
import json
import os
import re
import subprocess
import sys
import uuid
from faker import Faker


def join_wrapped_json_strings(content: str) -> str:
    result = []
    in_string = False
    escaped = False
    for char in content:
        # A terminal wrap can even split a backslash from the character it escapes.
        if in_string and char in "\r\n":
            continue
        result.append(char)
        if escaped:
            escaped = False
        elif in_string and char == "\\":
            escaped = True
        elif char == '"':
            in_string = not in_string
    return "".join(result)


def parse_json(content: str) -> tuple[object, bool]:
    try:
        return json.loads(content), False
    except json.JSONDecodeError:
        joined = join_wrapped_json_strings(content)
        if joined == content:
            raise
        return json.loads(joined), True


def format_json(content: str) -> str:
    try:
        value, repaired = parse_json(content)
    except json.JSONDecodeError:
        return content

    # Unwrap JSON-encoded objects and arrays, but keep ordinary JSON strings intact.
    nested = value
    while isinstance(nested, str):
        try:
            nested, _ = parse_json(nested)
        except json.JSONDecodeError:
            break
        if isinstance(nested, (dict, list)):
            value = nested
            break

    # Only repair malformed input when it ultimately produces structured JSON.
    if repaired and not isinstance(value, (dict, list)):
        return content

    return json.dumps(value, indent=2, ensure_ascii=False) + "\n"


def main() -> None:
    parser = argparse.ArgumentParser(description="Create a randomly named JSON scratch file in /tmp/jsons.")
    parser.add_argument("--stdin", action="store_true", help="Use standard input as the file contents.")
    parser.add_argument(
        "--clipboard-fallback",
        action="store_true",
        help="Read the system clipboard when standard input is empty (for tmux selections).",
    )
    args = parser.parse_args()

    content = sys.stdin.read() if args.stdin else ""
    if not content and args.clipboard_fallback:
        content = subprocess.run(
            ["xclip", "-selection", "clipboard", "-out"],
            check=True,
            capture_output=True,
            text=True,
        ).stdout

    content = format_json(content)

    faker = Faker()
    phrase = faker.catch_phrase().lower()
    slug = re.sub(r"[^a-z0-9]+", "-", phrase).strip("-") or "humbug"
    name = f"{slug}-{uuid.uuid4().hex[:6]}.json"

    target_dir = "/tmp/jsons"
    os.makedirs(target_dir, exist_ok=True)

    path = os.path.join(target_dir, name)
    with open(path, "x", encoding="utf-8") as fh:
        fh.write(content)

    subprocess.run(["kitty", "nvim", path], check=False)


if __name__ == "__main__":
    main()
