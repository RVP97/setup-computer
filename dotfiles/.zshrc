# ------------------------------
# Powerlevel10k instant prompt (must be first)
# ------------------------------
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ------------------------------
# Skip heavy config for non-interactive shells (Cursor optimization)
# ------------------------------
[[ $- != *i* ]] && return

# ------------------------------
# Oh My Zsh + Theme
# ------------------------------
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
  git
  brew
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# ------------------------------
# PATH (order matters) — Apple Silicon Homebrew: /opt/homebrew
# ------------------------------
export PATH="/opt/homebrew/bin:$PATH"
export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"
export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# ------------------------------
# Bun
# ------------------------------
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# ------------------------------
# Aliases
# ------------------------------
alias zshconfig="cursor ~/.zshrc"
alias editz="cursor ~/.zshrc"
alias reload="source ~/.zshrc"
alias gs="git status"
alias gp="git push"
alias gc="git commit"
alias ts="tailscale status"

# ------------------------------
# History optimization
# ------------------------------
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt appendhistory
setopt sharehistory
setopt hist_ignore_dups
setopt hist_ignore_space
setopt hist_expire_dups_first
setopt hist_find_no_dups
setopt hist_save_no_dups

# ------------------------------
# General shell improvements
# ------------------------------
setopt autocd
setopt interactivecomments

# ------------------------------
# Load Powerlevel10k config
# ------------------------------
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
