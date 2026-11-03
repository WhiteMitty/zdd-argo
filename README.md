# zdd-argo
### version 0.2.0 
### 2026-09-14
### 说明
- 推荐用 Xray 模式搭建
- 默认端口：443，可根据喜好修改
- 默认优选：saas.sin.fan，可根据喜好修改
- 临时隧道由 tmux 保持，断开 SSH 后仍可运行
- 若 VPS 重启或重装 Argo，原临时 Argo 会失效
- 支持 VMess / WS / TLS 与 VLESS-ENC / WS / TLS
- 使用 HTTP/1.1 和 WS 是为了临时 Argo 隧道的稳定
- 仅 Xray 语法下订阅加入了 ECH，默认填写 cloudflare-ech.com+udp://119.29.29.29:53
### 要求
- root 权限
- Debian / Ubuntu / Alpine
### 安装
```bash
curl -fsSL -o zdd-argo.sh https://raw.githubusercontent.com/WhiteMitty/zdd-argo/main/zdd-argo.sh \
  && bash zdd-argo.sh
```
或者：
```bash
wget -qO zdd-argo.sh https://raw.githubusercontent.com/WhiteMitty/zdd-argo/main/zdd-argo.sh \
  && bash zdd-argo.sh
```
### 卸载
```bash
zargo
```
选择完整卸载。
### License
MIT
