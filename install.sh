#!/bin/bash
# Fetch this repo and run bootstrap.
#
# Recommended for most users: git clone + ./bootstrap.sh (see README).
#
# Quick install — public repo (no token):
#   curl -fsSL https://raw.githubusercontent.com/RVP97/setup-computer/main/install.sh | bash
#
# Private repo or no raw access: export GITHUB_TOKEN, then pipe from the API:
#   export GITHUB_TOKEN=ghp_xxx
#   curl -fsSL -H "Authorization: Bearer ${GITHUB_TOKEN}" -H "Accept: application/vnd.github.raw" \
#     "https://api.github.com/repos/RVP97/setup-computer/contents/install.sh?ref=main" | bash
#
# Optional env:
#   SETUP_COMPUTER_DIR       clone/extract destination (default: ~/setup-computer)
#   SETUP_COMPUTER_BRANCH    (default: main)
#   SETUP_COMPUTER_GITHUB    owner/repo slug (default: RVP97/setup-computer)
#   SETUP_COMPUTER_CLONE_URL full clone URL (overrides defaults)
#   GITHUB_TOKEN             set for private repos (authenticated clone + API tarball fallback)

set -e

GITHUB_SLUG="${SETUP_COMPUTER_GITHUB:-RVP97/setup-computer}"
OWNER="${GITHUB_SLUG%%/*}"
REPO="${GITHUB_SLUG#*/}"
BRANCH="${SETUP_COMPUTER_BRANCH:-main}"
TARGET="${SETUP_COMPUTER_DIR:-${HOME}/setup-computer}"

if [[ -n "${SETUP_COMPUTER_CLONE_URL}" ]]; then
  CLONE_URL="${SETUP_COMPUTER_CLONE_URL}"
elif [[ -n "${GITHUB_TOKEN}" ]]; then
  CLONE_URL="https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_SLUG}.git"
else
  CLONE_URL="https://github.com/${GITHUB_SLUG}.git"
fi

if [[ -n "${GITHUB_TOKEN}" ]]; then
  ARCHIVE_URL="${SETUP_COMPUTER_ARCHIVE_URL:-https://api.github.com/repos/${OWNER}/${REPO}/tarball/${BRANCH}}"
  ARCHIVE_NEEDS_AUTH=1
else
  ARCHIVE_URL="${SETUP_COMPUTER_ARCHIVE_URL:-https://github.com/${GITHUB_SLUG}/archive/refs/heads/${BRANCH}.tar.gz}"
  ARCHIVE_NEEDS_AUTH=
fi

install_from_archive() {
  echo "Fetching tarball..."
  local tmp extracted
  tmp=$(mktemp -d)
  trap 'rm -rf "${tmp}"' RETURN
  if [[ -n "${ARCHIVE_NEEDS_AUTH}" ]]; then
    curl -fsSL -L \
      -H "Authorization: Bearer ${GITHUB_TOKEN}" \
      -H "Accept: application/vnd.github+json" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "${ARCHIVE_URL}" -o "${tmp}/repo.tar.gz"
  else
    curl -fsSL "${ARCHIVE_URL}" -o "${tmp}/repo.tar.gz"
  fi
  tar -xzf "${tmp}/repo.tar.gz" -C "${tmp}"
  extracted=$(find "${tmp}" -mindepth 1 -maxdepth 1 -type d | head -1)
  if [[ -z "${extracted}" || ! -d "${extracted}" ]]; then
    echo "Error: unexpected archive layout under ${tmp}" >&2
    exit 1
  fi
  mv "${extracted}" "${TARGET}"
}

echo "→ Target directory: ${TARGET}"
echo "→ Branch: ${BRANCH}"

if [[ -d "${TARGET}/.git" ]]; then
  echo "Updating existing clone..."
  git -C "${TARGET}" fetch origin "${BRANCH}"
  git -C "${TARGET}" checkout "${BRANCH}"
  git -C "${TARGET}" pull --ff-only origin "${BRANCH}"
elif [[ -e "${TARGET}" ]]; then
  echo "Error: ${TARGET} already exists and is not a git clone. Remove it or set SETUP_COMPUTER_DIR." >&2
  exit 1
elif command -v git >/dev/null 2>&1; then
  if ! git clone --branch "${BRANCH}" --depth 1 "${CLONE_URL}" "${TARGET}"; then
    rm -rf "${TARGET}"
    echo "git clone failed, falling back to tarball..."
    install_from_archive
  fi
else
  install_from_archive
fi

if [[ ! -f "${TARGET}/bootstrap.sh" ]]; then
  echo "Error: bootstrap.sh missing under ${TARGET}" >&2
  exit 1
fi

chmod +x "${TARGET}/bootstrap.sh" 2>/dev/null || true
[[ -f "${TARGET}/macos.sh" ]] && chmod +x "${TARGET}/macos.sh"

exec bash "${TARGET}/bootstrap.sh"
