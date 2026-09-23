#!/usr/bin/env bash

set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
article_path="${1:-${project_dir}/../business-notes/content/tiktok/file-types/blogpost.md}"
ssh_key="${HOME}/.ssh/tacit7"
remote_host="deploy@167.172.194.233"
remote_article="/tmp/urielm-agent-files-blog-${$}.md"

if [[ ! -f "${article_path}" ]]; then
  echo "Article not found: ${article_path}" >&2
  exit 1
fi

if [[ ! -f "${ssh_key}" ]]; then
  echo "SSH key not found: ${ssh_key}" >&2
  exit 1
fi

echo "Uploading article to ${remote_host}..."
scp -q -i "${ssh_key}" "${article_path}" "${remote_host}:${remote_article}"

echo "Publishing https://urielm.dev/blog/markdown-agents-md-skills-plugins..."
ssh -i "${ssh_key}" "${remote_host}" \
  python3 - "${remote_article}" <<'PY'
import os
import shlex
import subprocess
import sys

article_path = sys.argv[1]

try:
    raw = subprocess.check_output(
        ["systemctl", "show", "urielm", "-p", "Environment", "--value"],
        text=True,
    )
    env = os.environ.copy()

    for item in shlex.split(raw):
        key, separator, value = item.partition("=")
        if separator:
            env[key] = value

    env["MIX_ENV"] = "prod"
    subprocess.run(
        [
            "mix",
            "blog.publish",
            article_path,
            "--author",
            "urielm",
            "--hero-image",
            "/images/blog/markdown-agents-skills-plugins-hero.jpg",
        ],
        cwd="/home/deploy/urielm",
        env=env,
        check=True,
    )
finally:
    try:
        os.remove(article_path)
    except FileNotFoundError:
        pass
PY

echo "Published successfully."
