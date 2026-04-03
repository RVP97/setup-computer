#!/bin/bash

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Starting machine setup..."
echo "→ Repo: $REPO_ROOT"

# ------------------------------
# Homebrew: Apple Silicon only (/opt/homebrew)
# ------------------------------
load_brew_shellenv() {
  if command -v brew >/dev/null 2>&1; then
    eval "$(brew shellenv)"
    return 0
  fi
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    return 0
  fi
  return 1
}

if ! load_brew_shellenv; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if ! load_brew_shellenv; then
  echo "Homebrew is installed but not on PATH yet. Open a new terminal, then run this script again." >&2
  exit 1
fi

# Idempotent: do not duplicate shellenv line on re-runs
ZPROFILE="${HOME}/.zprofile"
if [[ -f "$ZPROFILE" ]] && grep -q 'brew shellenv' "$ZPROFILE"; then
  :
else
  echo "eval \"\$($(brew --prefix)/bin/brew shellenv)\"" >>"$ZPROFILE"
fi

# ------------------------------
# Update & install packages
# ------------------------------
echo "Updating Homebrew..."
brew update

echo "Installing Brew packages..."
brew bundle --file="${REPO_ROOT}/Brewfile"

# ------------------------------
# Oh My Zsh (not in Homebrew — official installer + theme/plugins for .zshrc)
# ------------------------------
OMZ_DIR="${HOME}/.oh-my-zsh"
if [[ ! -f "${OMZ_DIR}/oh-my-zsh.sh" ]]; then
  echo "Installing Oh My Zsh (official script; Homebrew does not ship it)..."
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

ZSH_CUSTOM="${OMZ_DIR}/custom"
mkdir -p "${ZSH_CUSTOM}/themes" "${ZSH_CUSTOM}/plugins"

P10K_THEME="${ZSH_CUSTOM}/themes/powerlevel10k"
if [[ ! -d "${P10K_THEME}/.git" ]] && [[ ! -f "${P10K_THEME}/powerlevel10k.zsh-theme" ]]; then
  echo "Installing Powerlevel10k theme..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${P10K_THEME}"
fi

ZAS="${ZSH_CUSTOM}/plugins/zsh-autosuggestions"
if [[ ! -d "${ZAS}/.git" ]]; then
  echo "Installing zsh-autosuggestions..."
  git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "${ZAS}"
fi

ZSH_SYNTAX="${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"
if [[ ! -d "${ZSH_SYNTAX}/.git" ]]; then
  echo "Installing zsh-syntax-highlighting..."
  git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_SYNTAX}"
fi

# ------------------------------
# Dotfiles setup
# ------------------------------
echo "Linking dotfiles..."

mkdir -p "${HOME}/.ssh"

ln -sf "${REPO_ROOT}/dotfiles/.zshrc" "${HOME}/.zshrc"
ln -sf "${REPO_ROOT}/dotfiles/.gitconfig" "${HOME}/.gitconfig"
ln -sf "${REPO_ROOT}/dotfiles/.ssh/config" "${HOME}/.ssh/config"

chmod 600 "${HOME}/.ssh/config"

# ------------------------------
# ~/dev — repos listed in dev-repos (optional file)
# ------------------------------
DEV_ROOT="${SETUP_COMPUTER_DEV_ROOT:-${HOME}/dev}"
DEV_LIST="${REPO_ROOT}/dev-repos"
# Advanced: SETUP_COMPUTER_GITHUB_HOST=github.company.com for GitHub Enterprise
GITHUB_SSH_HOST="${SETUP_COMPUTER_GITHUB_HOST:-github.com}"
if [[ -f "${DEV_LIST}" ]]; then
  echo "Dev projects → ${DEV_ROOT}"
  mkdir -p "${DEV_ROOT}"
  # Wait for 1Password (SSH agent) if ~/.ssh/config uses it — clones need unlocked keys
  dev_repos_has_entries=0
  while IFS= read -r _dr_line || [[ -n "${_dr_line}" ]]; do
    [[ -z "${_dr_line// }" || "${_dr_line}" =~ ^[[:space:]]*# ]] && continue
    dev_repos_has_entries=1
    break
  done <"${DEV_LIST}"
  if [[ "${dev_repos_has_entries}" -eq 1 ]] && [[ -t 0 ]] && [[ -z "${SETUP_COMPUTER_SKIP_DEV_PAUSE:-}" ]]; then
    echo ""
    echo "──────────────────────────────────────────────────────────────────────"
    echo "  Unlock 1Password before cloning (SSH uses ~/.1password/agent.sock)."
    echo "──────────────────────────────────────────────────────────────────────"
    read -r -p "Press Enter when 1Password is unlocked… "
  fi
  # Safe relative path: segments must be alphanumeric._- only (allows webdev/paginas/…)
  dev_subpath_ok() {
    local p="$1"
    [[ -z "${p}" || "${p}" == /* || "${p}" == *..* || "${p}" == "." ]] && return 1
    local -a segs
    IFS=/ read -ra segs <<<"${p}"
    local s
    for s in "${segs[@]}"; do
      [[ -z "${s}" || "${s}" == "." || "${s}" == ".." ]] && return 1
      [[ "${s}" =~ ^[a-zA-Z0-9_.-]+$ ]] || return 1
    done
    return 0
  }
  while IFS= read -r line || [[ -n "${line}" ]]; do
    [[ -z "${line// }" ]] && continue
    [[ "${line}" =~ ^[[:space:]]*# ]] && continue
    line_trimmed="${line#"${line%%[![:space:]]*}"}"
    line_trimmed="${line_trimmed%"${line_trimmed##*[![:space:]]}"}"

    read -ra toks <<<"${line_trimmed}"
    [[ ${#toks[@]} -eq 0 ]] && continue

    group=""
    spec=""
    local_name=""
    # webdev/paginas  owner/repo [folder]  →  ~/dev/webdev/paginas/…
    if [[ ${#toks[@]} -ge 2 ]] && [[ ! "${toks[0]}" =~ ^(https?://|git@) ]] &&
      [[ "${toks[1]}" =~ ^(https?://|git@|[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)$ ]]; then
      group="${toks[0]}"
      spec="${toks[1]}"
      local_name="${toks[2]:-}"
    else
      spec="${toks[0]}"
      local_name="${toks[1]:-}"
    fi

    if [[ -n "${group}" ]] && ! dev_subpath_ok "${group}"; then
      echo "  • skip bad path: ${group}" >&2
      continue
    fi

    if [[ -n "${local_name}" ]] && { [[ "${local_name}" == */* ]] || [[ "${local_name}" == *..* ]] || [[ "${local_name}" == "." ]]; }; then
      echo "  • skip bad folder name: ${local_name}" >&2
      continue
    fi

    if [[ "${spec}" =~ ^(https?://|git@) ]]; then
      clone_url="${spec}"
    elif [[ "${spec}" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; then
      clone_url="git@${GITHUB_SSH_HOST}:${spec}.git"
    else
      echo "  • skip line: ${line}" >&2
      continue
    fi

    url_stripped="${clone_url%.git}"
    if [[ "${url_stripped}" == git@*:* ]]; then
      default_dir="${url_stripped##*:}"
      default_dir="${default_dir##*/}"
    else
      default_dir="${url_stripped##*/}"
    fi

    dir_name="${local_name:-${default_dir}}"
    if [[ -n "${group}" ]]; then
      mkdir -p "${DEV_ROOT}/${group}"
      target="${DEV_ROOT}/${group}/${dir_name}"
      rel_path="${group}/${dir_name}"
    else
      target="${DEV_ROOT}/${dir_name}"
      rel_path="${dir_name}"
    fi
    if [[ -d "${target}/.git" ]]; then
      echo "  • ${rel_path} (update)"
      git -C "${target}" pull --ff-only 2>/dev/null || true
    elif [[ -e "${target}" ]]; then
      echo "  • ${rel_path} (skip — not a git folder)" >&2
    else
      echo "  • ${rel_path} (clone)"
      git clone --depth 1 "${clone_url}" "${target}"
    fi
  done <"${DEV_LIST}"
fi

# ------------------------------
# macOS defaults (optional script in repo)
# ------------------------------
if [[ -x "${REPO_ROOT}/macos.sh" ]]; then
  echo "Applying macOS defaults..."
  "${REPO_ROOT}/macos.sh"
fi

# ------------------------------
# Done
# ------------------------------
echo "Setup complete."

# Interactive terminal: replace this shell with login zsh so ~/.zprofile + ~/.zshrc load (PATH, Oh My Zsh, etc.)
# Skip with SETUP_COMPUTER_SKIP_ZSH_REEXEC=1 (e.g. CI) or when stdout is not a TTY.
if [[ -t 1 ]] && [[ -z "${SETUP_COMPUTER_SKIP_ZSH_REEXEC:-}" ]] && command -v zsh >/dev/null 2>&1; then
  echo "→ Starting login zsh with your updated configuration (type exit to return to the previous shell)."
  exec zsh -l
fi

echo "→ Open a new terminal or run: zsh -l"
