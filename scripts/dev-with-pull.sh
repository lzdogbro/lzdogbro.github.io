#!/usr/bin/env zsh
#
# dev-with-pull.sh — 启动 vitepress dev，同时把 scripts/auto-pull.sh 挂到后台
#
# 目的：`npm run dev` 一条命令同时起「开发服务器」和「每小时拉取最新代码」。
#       退出（Ctrl-C、关终端、npm 结束）时自动把拉取进程收掉，不留孤儿进程。
#
# 用法：
#   npm run dev                    # 一起启动
#   AUTO_PULL=0 npm run dev        # 只起 dev，不拉代码
#   INTERVAL=600 npm run dev       # 改成每 10 分钟检查一次
#   npm run dev -- --port 5174     # 参数透传给 vitepress
#
# 说明：dev 模式下拉取脚本以 BUILD=0 运行——VitePress dev 自己会热更新，
#       不需要 npm run build，也避免在 dev 运行中途 npm ci 把依赖换掉。
#       拉到 package.json / package-lock.json 的变更只会在日志里提示，
#       需要手动 npm ci 后重启 dev。

emulate -L zsh
setopt NO_UNSET PIPE_FAIL

ROOT=$(git -C "${0:A:h}" rev-parse --show-toplevel 2>/dev/null)
if [[ -z $ROOT ]]; then
  print -ru2 -- "dev-with-pull: 找不到 git 仓库根目录"
  exit 1
fi

PULL_SCRIPT="$ROOT/scripts/auto-pull.sh"
VITEPRESS="$ROOT/node_modules/.bin/vitepress"
PULL_PID=""
DEV_PID=""

cleanup() {
  local p
  for p in "$PULL_PID" "$DEV_PID"; do
    [[ -n $p ]] && kill -0 "$p" 2>/dev/null && kill "$p" 2>/dev/null
  done
  # 给一点时间让 zsh/Node 自己收尾，再补刀
  sleep 0.3
  for p in "$PULL_PID" "$DEV_PID"; do
    [[ -n $p ]] && kill -0 "$p" 2>/dev/null && kill -9 "$p" 2>/dev/null
  done
  PULL_PID=""
  DEV_PID=""
}

on_signal() {
  cleanup
  exit 130
}

trap cleanup EXIT
trap on_signal INT TERM

if [[ ${AUTO_PULL:-1} == 0 ]]; then
  print -r -- "→ AUTO_PULL=0，本次只启动 dev，不拉取代码"
elif [[ ! -x $PULL_SCRIPT ]]; then
  print -ru2 -- "! $PULL_SCRIPT 不存在或不可执行，跳过自动拉取"
else
  BUILD=0 "$PULL_SCRIPT" >/dev/null 2>&1 &
  PULL_PID=$!
  print -r -- "→ auto-pull 已随 dev 启动（pid $PULL_PID，每 ${INTERVAL:-3600}s 检查一次）"
  print -r -- "  日志：$ROOT/.git/auto-pull.log"
fi

if [[ ! -x $VITEPRESS ]]; then
  print -ru2 -- "! 找不到 $VITEPRESS，先执行 npm install"
  exit 1
fi

"$VITEPRESS" dev "$@" &
DEV_PID=$!
wait "$DEV_PID"
