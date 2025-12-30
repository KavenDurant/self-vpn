# Self-VPN 部署项目

🔐 基于 WireGuard 的个人 VPN 解决方案

## 📊 服务器配置

- **提供商**: DigitalOcean
- **配置**: $4/月 (512MB RAM / 1 CPU / 10GB SSD / 500GB 流量)
- **系统**: Ubuntu 22.04 LTS x64
- **区域**: 推荐 San Francisco (SFO3) 或 Singapore (SGP1)
- **预算**: $30 (可用约 7.5 个月)

## 🎯 功能特性

- ✅ 支持 4 台设备同时配置
- ✅ 一键自动部署 WireGuard
- ✅ 安全加固（防火墙、SSH 配置）
- ✅ 流量监控和告警
- ✅ 健康检查脚本
- ✅ 客户端配置生成（含二维码）

## 📁 项目结构

```
self-vpn/
├── README.md                 # 项目文档
├── config/
│   ├── server.conf.template  # 服务端配置模板
│   └── client.conf.template  # 客户端配置模板
├── scripts/
│   ├── deploy.sh            # 一键部署脚本
│   ├── add-client.sh        # 添加客户端
│   ├── monitor.sh           # 流量监控
│   └── security.sh          # 安全加固
├── clients/                 # 客户端配置文件（生成后）
└── .env.example            # 环境变量示例
```

## 🚀 快速开始

### 1. 创建服务器后，获取 IP 地址

```bash
# 测试连接
ssh -i ~/.ssh/id_ed25519 root@YOUR_SERVER_IP
```

### 2. 配置环境变量

```bash
cp .env.example .env
# 编辑 .env，填入服务器 IP
```

### 3. 一键部署

```bash
./scripts/deploy.sh
```

### 4. 生成客户端配置

```bash
./scripts/add-client.sh iphone
./scripts/add-client.sh macbook
./scripts/add-client.sh ipad
./scripts/add-client.sh windows
```

## 📱 客户端使用

### iOS/macOS
1. 安装 WireGuard 官方 App
2. 扫描生成的二维码或导入配置文件

### Windows
1. 下载 WireGuard: https://www.wireguard.com/install/
2. 导入配置文件

### Android
1. 安装 WireGuard App
2. 扫描二维码

## 📊 监控和维护

### 查看流量使用
```bash
./scripts/monitor.sh
```

### 查看连接状态
```bash
ssh root@YOUR_SERVER_IP "wg show"
```

## 🔒 安全建议

- ✅ 使用 SSH 密钥认证（已配置）
- ✅ 禁用 SSH 密码登录（自动配置）
- ✅ 配置防火墙仅开放必要端口（自动配置）
- ✅ 定期更新系统（每月执行）
- ⚠️ 不要分享配置文件
- ⚠️ 定期检查流量使用（避免超限）

## 💰 成本控制

- **每月流量**: 500GB
- **预估使用**: 每天 2-3 小时，月流量约 100-200GB
- **告警阈值**: 400GB（80%）

## 🆘 故障排查

### 无法连接
1. 检查服务器防火墙：`ufw status`
2. 检查 WireGuard 状态：`systemctl status wg-quick@wg0`
3. 检查端口：`ss -tulpn | grep 51820`

### 速度慢
1. 更换服务器区域
2. 检查本地网络
3. 尝试更换端口

## 📞 联系方式

- Email: luojiaxin888@gmail.com

## 📄 License

MIT License
