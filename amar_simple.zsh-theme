# Simple zsh theme, with git and error status
# Based off of agnoster's theme, but without the colored backgrounds

CURRENT_BG='NONE'

() {
  SEGMENT_RSEP=$'|'
}

# Begin a segment for right prompt
# Similar to prompt_segment, but:
#		- segment sepearators have to show on left instead
#		- rprompt starts drawing when $CURRENT_BG='NONE'
# TODO: this function isn't completley right: inner arrows might not get set to correct colors
rprompt_segment() {
  local fg
  [[ -n $1 ]] && fg="%F{$1}" || fg="%f"
  if [[ $CURRENT_BG == 'NONE' ]]; then
    # don't print sepearator for first segment
    # TODO doesn't work ???
    echo -n " %{%f%b%k%}%{$fg%} "
	CURRENT_BG="SET"
  else
    echo -n " %{%f%}$SEGMENT_RSEP%{$fg%} "
  fi
  [[ -n $2 ]] && echo -n $2
}

# Git: branch/detached head, dirty status
prompt_git() {
  (( $+commands[git] )) || return
  local PL_BRANCH_CHAR
  () {
    local LC_ALL="" LC_CTYPE="en_US.UTF-8"
    PL_BRANCH_CHAR=$'\ue0a0'         # 
  }
  local ref dirty mode repo_path
  repo_path=$(git rev-parse --git-dir 2>/dev/null)

  if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
    dirty=$(parse_git_dirty)
    ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="➦ $(git rev-parse --short HEAD 2> /dev/null)"
    if [[ -n $dirty ]]; then
      rprompt_segment yellow
    else
      rprompt_segment green
    fi

    if [[ -e "${repo_path}/BISECT_LOG" ]]; then
      mode=" <B>"
    elif [[ -e "${repo_path}/MERGE_HEAD" ]]; then
      mode=" >M<"
    elif [[ -e "${repo_path}/rebase" || -e "${repo_path}/rebase-apply" || -e "${repo_path}/rebase-merge" || -e "${repo_path}/../.dotest" ]]; then
      mode=" >R>"
    fi

    setopt promptsubst
    autoload -Uz vcs_info

		# ◒ 
    zstyle ':vcs_info:*' enable git
    zstyle ':vcs_info:*' get-revision true
    zstyle ':vcs_info:*' check-for-changes true
    zstyle ':vcs_info:*' stagedstr '○' # '⍜' # '✚'
    zstyle ':vcs_info:*' unstagedstr '●' # '●'
    zstyle ':vcs_info:*' formats ' %u%c'
    zstyle ':vcs_info:*' actionformats ' %u%c'
    vcs_info
    #echo -n "${ref/refs\/heads\//$PL_BRANCH_CHAR }${vcs_info_msg_0_%% }${mode}"
    #echo -n "${vcs_info_msg_0_%% }${ref/refs\/heads\// }${mode}"
    echo -n "${vcs_info_msg_0_%% }%{%B%}${ref/refs\/heads\// }%{%b%}${mode}"
  fi
}

prompt_ssh() {
  if [[ -n $SSH_CONNECTION ]]; then
    rprompt_segment blue
    echo -n "$(hostname)"
  fi
}

# Status:
# was there an error?
prompt_status() {
  local symbols
  symbols=()
	[[ $RETVAL -ne 0 ]] && symbols+="%{%B%F{red}%}$RETVAL%{%b%}"

	[[ -n "$symbols" ]] && rprompt_segment default "$symbols"
}

build_rprompt() {
  RETVAL=$?
  prompt_git
  prompt_ssh
  prompt_status
}


PROMPT='%{$fg_bold[green]%}%2~ %{$reset_color%}%(!.#.$) '
RPROMPT='%{%f%b%k%}$(build_rprompt) '
