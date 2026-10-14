# options.zsh - shell options (setopt)
# Loaded 1st. Navigation/interaction setopts live here, e.g.:
#   autocd  interactivecomments  rm_star_silent  prompt_subst  +o nomatch
# History-related setopts belong in history.zsh, not here.

# ==================== 纯 ASCII zsh 提示符 ====================
# 不使用 prompt_subst，在 precmd 里动态组装 PS1，避免实时展开性能损耗
setopt no_prompt_subst

# ---------- 1. Git 状态函数 ----------
git_prompt() {
  local branch
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || return

  # 如果是 detached HEAD，显示 commit 短哈希
  if [[ "$branch" == "HEAD" ]]; then
    branch=$(git rev-parse --short HEAD 2>/dev/null)
    [[ -z "$branch" ]] && return
  fi

  local st
  st=$(git status --porcelain=v1 2>/dev/null)

  local flags=""
  local -i has_conflict=0 has_staged=0 has_unstaged=0 has_untracked=0

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    local X="${line[1]}"
    local Y="${line[2]}"

    # 冲突
    if [[ "$X" == "U" || "$Y" == "U" ]] || [[ "$X" =~ [AD] && "$Y" =~ [AD] ]]; then
      has_conflict=1
    fi
    # 已暂存
    [[ "$X" != " " && "$X" != "?" && "$X" != "!" ]] && has_staged=1
    # 未暂存
    [[ "$Y" != " " && "$Y" != "?" && "$Y" != "!" ]] && has_unstaged=1
    # 未跟踪
    [[ "$line" == "??"* ]] && has_untracked=1
  done <<< "$st"

  # 判断是否处于 merge / rebase / cherry-pick 中
  local action=""
  if [[ -d "$(git rev-parse --git-path rebase-merge 2>/dev/null)" || -d "$(git rev-parse --git-path rebase-apply 2>/dev/null)" ]]; then
    action='|REBASE'
  elif [[ -f "$(git rev-parse --git-path MERGE_HEAD 2>/dev/null)" ]]; then
    action='|MERGING'
  elif [[ -f "$(git rev-parse --git-path CHERRY_PICK_HEAD 2>/dev/null)" ]]; then
    action='|CHERRY'
  fi

  [[ $has_conflict -eq 1 ]]   && flags+='!'
  [[ $has_staged -eq 1 ]]     && flags+='+'
  [[ $has_unstaged -eq 1 ]]   && flags+='*'
  [[ $has_untracked -eq 1 ]]  && flags+='?'

  echo "[${branch}${flags}${action}]"
}

# ---------- 2. Python / Conda 环境显示函数 ----------
python_prompt() {
  local env_type="" env_name=""

  # 优先检测 Conda
  if [[ -n "$CONDA_DEFAULT_ENV" ]]; then
    env_type="conda"
    env_name="$CONDA_DEFAULT_ENV"
  # 然后检测 venv / virtualenv
  elif [[ -n "$VIRTUAL_ENV" ]]; then
    env_type="venv"
    env_name=$(basename "$VIRTUAL_ENV")
  else
    return
  fi

  # 获取当前 Python 版本
  local pyver
  pyver=$(python --version 2>&1 | awk '{print $2}')
  if [[ -z "$pyver" ]]; then
    pyver="?"
  fi

  # 输出：via py v3.14.7 (venv:venv)
  echo "via py v${pyver} (${env_type}:${env_name})"
}

# ---------- 3. 组装提示符 ----------
autoload -Uz add-zsh-hook

_update_prompt() {
  local exit_code=$?   # 必须在最前面捕获，否则会被其他命令覆盖

  # --- 命令执行状态标记 ---
  local marker
  if (( exit_code == 0 )); then
    marker="%F{green}[ok]%f"
  else
    marker="%F{red}[${exit_code}]%f"
  fi

  # --- 基础部分：用户、主机、目录 ---
  local base_part
  base_part="$marker %F{cyan}%n@%m%f %F{green}%~%f"

  # --- Git 分支部分 ---
  local git_part
  git_part=$(git_prompt)

  # --- Python 环境部分 ---
  local py_part
  py_part=$(python_prompt)

  # 拼接第一行内容
  local prompt_str
  prompt_str="${base_part}"

  # Git 信息非空时，加一个空格再拼上
  if [[ -n "$git_part" ]]; then
    prompt_str+=" %F{blue}${git_part}%f"
  fi

  # Python 信息非空时，放在 git 后面
  if [[ -n "$py_part" ]]; then
    # via 用 magenta，其余内容用 yellow
    if [[ "$py_part" == "via "* ]]; then
      prompt_str+=" %F{magenta}via%f %F{yellow}${py_part#via }%f"
    else
      prompt_str+=" %F{yellow}${py_part}%f"
    fi
  fi

  # --- 第二行输入提示符 ---
  if (( EUID == 0 )); then
    prompt_str+=$'\n%F{red}#%f '
  else
    prompt_str+=$'\n%F{green}>%f '
  fi

  PS1="$prompt_str"
}

add-zsh-hook precmd _update_prompt