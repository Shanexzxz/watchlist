#!/usr/bin/env bash
# watchlist 启动脚本
# 用法：
#   ./start.sh           # 前台启动（Ctrl+C 退出）
#   ./start.sh -d        # 后台启动（detached）
#   ./start.sh stop      # 停止后台实例
#   ./start.sh restart   # 重启
#   ./start.sh status    # 查看状态
#   ./start.sh logs      # tail -f 日志

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

PORT="${PORT:-8003}"
HOST="${HOST:-0.0.0.0}"
LOG="$SCRIPT_DIR/server.log"
PID_FILE="$SCRIPT_DIR/.server.pid"
HEALTH_PATH="${HEALTH_PATH:-/}"
# 用于 pkill 兜底匹配的关键字（足够独特，避免误杀）
PROC_PATTERN="directory='/data/workspace/watchlist'"

# 载入 .env（如果存在）
if [[ -f "$SCRIPT_DIR/.env" ]]; then
  set -a
  # shellcheck source=/dev/null
  source "$SCRIPT_DIR/.env"
  set +a
fi

# 把常见 node / python 安装路径加入 PATH
for p in /usr/local/bin /root/.workbuddy/binaries/node/versions/*/bin /root/.workbuddy/binaries/python/versions/*/bin "$HOME/.nvm/versions/node/*/bin"; do
  for dir in $p; do
    [[ -d "$dir" ]] && PATH="$dir:$PATH"
  done
done
export PATH PORT HOST

_running_pid() {
  [[ -f "$PID_FILE" ]] || return 1
  local pid
  pid=$(cat "$PID_FILE" 2>/dev/null || echo "")
  [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null && { echo "$pid"; return 0; }
  rm -f "$PID_FILE"
  return 1
}

# 真正启动服务的命令（Recipe C：纯静态目录）
_run_cmd() {
SERVE_DIR="${SERVE_DIR:-$SCRIPT_DIR}"
cat <<INNER
python3 -u -c "
import sys
from functools import partial
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
handler = partial(SimpleHTTPRequestHandler, directory='$SERVE_DIR')
srv = ThreadingHTTPServer(('$HOST', $PORT), handler)
print(f'Serving $SERVE_DIR on http://$HOST:$PORT', flush=True)
srv.serve_forever()
"
INNER
}

_ensure_deps() {
  :  # 无依赖：使用 python3 内置 http.server
}

_spawn() {
  # 滚动旧日志，保留崩溃现场（最多保留 5 份）
  if [[ -f "$LOG" && -s "$LOG" ]]; then
    for i in 4 3 2 1; do
      [[ -f "$LOG.$i" ]] && mv "$LOG.$i" "$LOG.$((i+1))"
    done
    mv "$LOG" "$LOG.1"
  fi
  # 完全脱离当前 shell/session：setsid 新会话 + nohup 忽略 HUP + 标准描述符重定向
  setsid nohup bash -c "$(_run_cmd)" > "$LOG" 2>&1 < /dev/null &
  local pid=$!
  echo "$pid" > "$PID_FILE"
  disown 2>/dev/null || true
  # 等服务 ready（最多 10 秒）
  for i in 1 2 3 4 5 6 7 8 9 10; do
    sleep 1
    if kill -0 "$pid" 2>/dev/null && ss -tlnp 2>/dev/null | grep -q ":$PORT "; then
      return 0
    fi
  done
}

cmd_start_fg() {
  _ensure_deps
  echo ">>> 前台启动 watchlist on $HOST:$PORT"
  exec bash -c "$(_run_cmd)"
}

cmd_start_bg() {
  if pid=$(_running_pid); then
    echo "⚠️  已在运行 (pid=$pid)。用 ./start.sh restart 重启。"
    exit 0
  fi
  if ss -tlnp 2>/dev/null | grep -q ":$PORT "; then
    echo "❌ 端口 $PORT 已被占用："
    ss -tlnp 2>/dev/null | grep ":$PORT "
    exit 1
  fi
  _ensure_deps
  echo ">>> 后台启动 watchlist on $HOST:$PORT"
  _spawn
  if pid=$(_running_pid); then
    echo "✅ pid=$pid · log: $LOG"
    sleep 1
    tail -n 10 "$LOG" 2>/dev/null || true
  else
    echo "❌ 启动失败，请查看日志：$LOG"
    tail -n 30 "$LOG" 2>/dev/null || true
    exit 1
  fi
}

cmd_stop() {
  if pid=$(_running_pid); then
    echo ">>> 停止 pid=$pid"
    kill "$pid" 2>/dev/null || true
    sleep 2
    kill -0 "$pid" 2>/dev/null && kill -9 "$pid" 2>/dev/null || true
    rm -f "$PID_FILE"
    [[ -n "$PROC_PATTERN" ]] && pkill -9 -f "$PROC_PATTERN" 2>/dev/null || true
    echo "✅ 已停止"
  else
    if [[ -n "$PROC_PATTERN" ]] && pgrep -f "$PROC_PATTERN" >/dev/null; then
      pkill -9 -f "$PROC_PATTERN" 2>/dev/null || true
      echo "✅ 已清理孤儿进程"
    else
      echo "未在运行"
    fi
  fi
}

cmd_status() {
  if pid=$(_running_pid); then
    echo "✅ 运行中 (pid=$pid)"
    ss -tlnp 2>/dev/null | grep ":$PORT " || netstat -tlnp 2>/dev/null | grep ":$PORT " || true
    curl -sS -o /dev/null -w "   health: HTTP %{http_code}\n" --max-time 3 "http://127.0.0.1:$PORT$HEALTH_PATH" 2>&1 || true
  else
    echo "❌ 未运行"
  fi
}

cmd_logs() {
  [[ -f "$LOG" ]] || { echo "没有日志文件: $LOG"; exit 1; }
  tail -n 100 -f "$LOG"
}

case "${1:-}" in
  ""|start)         cmd_start_fg ;;
  -d|--detach|bg)   cmd_start_bg ;;
  stop)             cmd_stop ;;
  restart)          cmd_stop; cmd_start_bg ;;
  status)           cmd_status ;;
  logs|log)         cmd_logs ;;
  *)
    cat <<EOF
Usage: $0 [command]

Commands:
  (no arg) | start   前台启动
  -d       | bg      后台启动（独立进程）
  stop               停止后台实例
  restart            重启（= stop + bg）
  status             查看运行状态
  logs               tail -f 日志

环境变量（可在 .env 中配置）：
  PORT=8003          监听端口
  HOST=0.0.0.0       监听地址
  HEALTH_PATH=/      健康检查路径（用于 status）
  SERVE_DIR=...      静态文件根目录（默认项目根）
EOF
    exit 1
    ;;
esac
