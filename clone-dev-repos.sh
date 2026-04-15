#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEV_LIST="${1:-${REPO_ROOT}/dev-repos}"
DEV_ROOT="${SETUP_COMPUTER_DEV_ROOT:-${HOME}/dev}"
GITHUB_SSH_HOST="${SETUP_COMPUTER_GITHUB_HOST:-github.com}"

if [[ ! -f "${DEV_LIST}" ]]; then
  echo "Error: dev-repos file not found: ${DEV_LIST}" >&2
  echo "Usage: $(basename "$0") [path-to-dev-repos-file]" >&2
  exit 1
fi

mkdir -p "${DEV_ROOT}"
echo "Dev projects -> ${DEV_ROOT}"
echo "Using list    -> ${DEV_LIST}"

while IFS= read -r line || [[ -n "${line}" ]]; do
  [[ -z "${line// }" || "${line}" =~ ^[[:space:]]*# ]] && continue

  read -ra toks <<<"${line}"
  [[ ${#toks[@]} -eq 0 ]] && continue

  group=""
  spec=""
  local_name=""

  # group/path owner/repo [folder] -> ~/dev/group/path/folder-or-repo-name
  if [[ ${#toks[@]} -ge 2 ]] && [[ ! "${toks[0]}" =~ ^(https?://|git@) ]] &&
    [[ "${toks[1]}" =~ ^(https?://|git@|[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)$ ]]; then
    group="${toks[0]}"
    spec="${toks[1]}"
    local_name="${toks[2]:-}"
  else
    spec="${toks[0]}"
    local_name="${toks[1]:-}"
  fi

  if [[ "${spec}" =~ ^(https?://|git@) ]]; then
    clone_url="${spec}"
  elif [[ "${spec}" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; then
    clone_url="git@${GITHUB_SSH_HOST}:${spec}.git"
  else
    echo "  - skip invalid line: ${line}"
    continue
  fi

  default_dir="${clone_url%.git}"
  if [[ "${default_dir}" == git@*:* ]]; then
    default_dir="${default_dir##*:}"
  fi
  default_dir="${default_dir##*/}"

  dir_name="${local_name:-${default_dir}}"
  target="${DEV_ROOT}/${group:+${group}/}${dir_name}"

  mkdir -p "$(dirname "${target}")"

  if [[ -d "${target}/.git" ]]; then
    echo "  - update: ${group:+${group}/}${dir_name}"
    git -C "${target}" pull --ff-only || true
  elif [[ -e "${target}" ]]; then
    echo "  - skip (exists, not git): ${group:+${group}/}${dir_name}"
  else
    echo "  - clone: ${group:+${group}/}${dir_name}"
    git clone --depth 1 "${clone_url}" "${target}"
  fi
done <"${DEV_LIST}"
