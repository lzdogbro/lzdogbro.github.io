#!/usr/bin/env zsh
#
# auto-pull.sh — lzdogbro.github.io 服务器端的定时拉取脚本
#
# 用途：在克隆好的项目目录里（任意子目录也可以）每小时拉取一次最新代码，
#       有新提交时重建 VitePress 站点；可用 --once 交给 cron / systemd timer 调。
#
# 用法：
#   ./auto-pull.sh                 # 常驻，每 INTERVAL 秒拉一次（默认 3600）
#   ./auto-pull.sh --once          # 只跑一轮就退出，适合 cron
#   ./auto-pull.sh --help
#
# 可调环境变量：
#   BRANCH=main                   跟踪分支
#   REMOTE=origin                 远端名
#   INTERVAL=3600                 常驻模式的间隔秒数
#   BUILD=1                       拉到新提交后是否 npm ci / npm run build（0 关闭）
#   POST_PULL_CMD=''              构建成功后执行的命令，例如 'sudo systemctl reload nginx'
#
# 日志与锁都放在 .git/ 里，不会弄脏工作区：
#   .git/auto-pull.log            运行日志（超过 2MB 自动轮转成 .1）
#   .git/auto-pull.lock/          互斥锁，防止上一轮没跑完又启动一轮
#
# 首次在新服务器上部署（只做一次）：
#   git clone https://github.com/lzdogbro/lzdogbro.github.io.git ~/site
#   cd ~/site && npm ci && npm run build
#   # 常驻：nohup ~/site/scripts/auto-pull.sh >/dev/null 2>&1 &
#   # 或 cron：0 * * * * ~/site/scripts/auto-pull.sh --once >/dev/null 2>&1
#   # dev 时自动带上：npm run dev（见 scripts/dev-with-pull.sh）
#
# 注意：脚本只做 fast-forward，服务器上不要手改被跟踪的文件；
#       dist 等构建产物是 gitignore 的，随便重建。

emulate -L zsh
setopt NO_UNSET PIPE_FAIL

BRANCH=${BRANCH:-main}
REMOTE=${REMOTE:-origin}
INTERVAL=${INTERVAL:-3600}
BUILD=${BUILD:-1}
POST_PULL_CMD=${POST_PULL_CMD:-}

SCRIPT_DIR=${0:A:h}
# 优先按脚本所在目录定位仓库；脚本放在仓库外但当前目录是仓库时也能跑
REPO_DIR=$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null)
if [[ -z $REPO_DIR ]]; then
  REPO_DIR=$(git rev-parse --show-toplevel 2>/dev/null)
fi
if [[ -z $REPO_DIR ]]; then
  print -ru2 -- "auto-pull: $SCRIPT_DIR 不在 git 仓库里，退出"
  exit 1
fi

LOG_FILE="$REPO_DIR/.git/auto-pull.log"
LOCK_DIR="$REPO_DIR/.git/auto-pull.lock"
LOG_MAX_BYTES=2097152

# ---------- 基础工具 ----------

log() {
  local ts
  ts=$(date '+%Y-%m-%d %H:%M:%S')
  print -r -- "[$ts] $*" >>"$LOG_FILE"
  print -r -- "[$ts] $*"
}

rotate_log() {
  [[ -f $LOG_FILE ]] || return 0
  local size
  size=$(wc -c <"$LOG_FILE" 2>/dev/null || print 0)
  if (( size > LOG_MAX_BYTES )); then
    mv -f "$LOG_FILE" "$LOG_FILE.1"
  fi
}

# 有 timeout 命令就用（Linux 自带，macOS 一般没有），没有就直接跑
run_with_timeout() {
  local secs=$1
  shift
  if command -v timeout >/dev/null 2>&1; then
    timeout "$secs" "$@"
  else
    "$@"
  fi
}

acquire_lock() {
  local pid
  if mkdir "$LOCK_DIR" 2>/dev/null; then
    print -r -- $$ >"$LOCK_DIR/pid"
    return 0
  fi
  # 锁已存在：判断持有者是否还活着，活着就跳过本轮，死了就接管
  pid=$(cat "$LOCK_DIR/pid" 2>/dev/null)
  if [[ -n $pid ]] && kill -0 "$pid" 2>/dev/null; then
    return 1
  fi
  rm -rf -- "$LOCK_DIR"
  mkdir "$LOCK_DIR" 2>/dev/null || return 1
  print -r -- $$ >"$LOCK_DIR/pid"
}

release_lock() {
  [[ -d $LOCK_DIR ]] && rm -rf -- "$LOCK_DIR"
}

# ---------- 核心流程 ----------

build_site() {
  local old=$1 new=$2
  local need_install=0

  if ! command -v npm >/dev/null 2>&1; then
    log "找不到 npm，跳过构建（请先安装 Node.js 20+）"
    return 1
  fi

  if [[ ! -d "$REPO_DIR/node_modules" ]]; then
    need_install=1
  elif [[ -n $(git -C "$REPO_DIR" diff --name-only "$old" "$new" -- package.json package-lock.json) ]]; then
    need_install=1
  fi

  if (( need_install )); then
    log "依赖有变化，执行 npm ci"
    if ! npm --prefix "$REPO_DIR" ci --no-audit --no-fund >>"$LOG_FILE" 2>&1; then
      log "npm ci 失败，保留上一版 dist"
      return 1
    fi
  fi

  log "执行 npm run build"
  if ! npm --prefix "$REPO_DIR" run build >>"$LOG_FILE" 2>&1; then
    log "构建失败，保留上一版 dist"
    return 1
  fi

  log "构建完成（产物：$REPO_DIR/.vitepress/dist）"
  return 0
}

pull_once() {
  local current_branch old new subject

  current_branch=$(git -C "$REPO_DIR" symbolic-ref --short -q HEAD)
  if [[ -z $current_branch ]]; then
    log "当前是 detached HEAD，跳过（先 git checkout $BRANCH）"
    return 1
  fi
  if [[ $current_branch != $BRANCH ]]; then
    log "当前分支是 $current_branch，不是 $BRANCH，跳过"
    return 1
  fi

  if [[ -n $(git -C "$REPO_DIR" status --porcelain --untracked-files=no) ]]; then
    log "警告：工作区有未提交的改动，仍会尝试 --ff-only"
  fi

  if ! run_with_timeout 120 git -C "$REPO_DIR" \
      -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=30 \
      fetch --prune --quiet "$REMOTE" "+refs/heads/${BRANCH}:refs/remotes/${REMOTE}/${BRANCH}"; then
    log "fetch 失败（网络或权限问题），下一轮再试"
    return 1
  fi

  old=$(git -C "$REPO_DIR" rev-parse HEAD)
  new=$(git -C "$REPO_DIR" rev-parse "$REMOTE/$BRANCH")

  if [[ $old == $new ]]; then
    log "已是最新：${old[1,7]}"
    return 0
  fi

  log "发现新提交：${old[1,7]} -> ${new[1,7]}"
  if ! git -C "$REPO_DIR" merge --ff-only --quiet "$REMOTE/$BRANCH"; then
    log "快进合并失败（服务器上有本地改动或分支分叉），跳过本轮"
    return 1
  fi

  subject=$(git -C "$REPO_DIR" log -1 --format='%h %s')
  log "拉取成功：$subject"

  if (( BUILD )); then
    build_site "$old" "$new"
    if (( $? != 0 )); then
      return 1
    fi
  else
    log "BUILD=0，跳过构建"
  fi

  if [[ -n $POST_PULL_CMD ]]; then
    log "执行 POST_PULL_CMD：$POST_PULL_CMD"
    if eval "$POST_PULL_CMD" >>"$LOG_FILE" 2>&1; then
      log "POST_PULL_CMD 执行成功"
    else
      log "POST_PULL_CMD 执行失败"
      return 1
    fi
  fi

  return 0
}

run_guarded() {
  local rc
  rotate_log
  if ! acquire_lock; then
    log "上一轮还在运行，跳过本轮"
    return 0
  fi
  pull_once
  rc=$?
  release_lock
  return $rc
}

usage() {
  cat <<'USAGE'
auto-pull.sh — 定时拉取 lzdogbro.github.io 并重建站点

用法：
  ./auto-pull.sh                常驻，每 INTERVAL 秒检查一次
  ./auto-pull.sh --once         只跑一轮，适合 cron / systemd timer
  ./auto-pull.sh --help

环境变量：
  BRANCH=main      REMOTE=origin      INTERVAL=3600
  BUILD=1          拉到新提交后 npm ci + npm run build（0 关闭）
  POST_PULL_CMD='' 构建成功后的命令，如 'sudo systemctl reload nginx'
USAGE
}

# ---------- 入口 ----------

once=0
for arg in "$@"; do
  case $arg in
    --once) once=1 ;;
    -h|--help) usage; exit 0 ;;
    *) print -ru2 -- "auto-pull: 未知参数 $arg"; usage; exit 2 ;;
  esac
done

export GIT_TERMINAL_PROMPT=0
export GIT_SSH_COMMAND=${GIT_SSH_COMMAND:-"ssh -o BatchMode=yes -o ConnectTimeout=15"}

trap 'release_lock; exit 0' INT TERM
trap 'release_lock' EXIT

log "启动：repo=$REPO_DIR branch=$BRANCH interval=${INTERVAL}s build=$BUILD"

if (( once )); then
  run_guarded
  exit $?
fi

while true; do
  run_guarded
  sleep "$INTERVAL"
done
