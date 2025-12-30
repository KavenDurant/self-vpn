# 🔐 Self-VPN

基于 WireGuard 的个人 VPN 解决方案，一键部署，支持多设备。

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![WireGuard](https://img.shields.io/badge/VPN-WireGuard-blue.svg)](https://www.wireguard.com/)

---

## ✨ 特性

- 🚀 **一键部署** - 自动化脚本，3-5 分钟完成部署
- 🔒 **安全可靠** - 基于 WireGuard 现代加密技术
- 📱 **多设备支持** - 支持 4 台设备（iPhone、iPad、MacBook、Windows）
- 💰 **成本低廉** - 月费仅 $4，预算 $30 可用 7.5 个月
- 📊 **流量监控** - 内置流量监控和告警功能
- 🛡️ **安全加固** - 自动化 SSH 和防火墙配置

---

## 📋 系统要求

### 服务器
- **提供商**: DigitalOcean（或其他 VPS）
- **配置**: 最低 512MB RAM / 1 CPU / 10GB 硬盘
- **系统**: Ubuntu 22.04 LTS x64
- **流量**: 500GB/月起
- **费用**: $4/月起

### 客户端
- iOS 12+ / iPadOS 12+
- macOS 10.14+
- Windows 10+
- Android 5.0+

---

## 🚀 快速开始

### 1. 克隆项目

```bash
git clone https://github.com/KavenDurant/self-vpn.git
cd self-vpn
```

### 2. 配置环境

```bash
# 复制环境变量模板
cp .env.example .env

# 编辑 .env，填入你的服务器 IP
vim .env
```

### 3. 一键部署

```bash
# 确保脚本有执行权限
chmod +x scripts/*.sh

# 执行快速部署
./scripts/deploy-quick.sh
```

### 4. 添加客户端

```bash
# 为每台设备生成配置
./scripts/add-client.sh iphone
./scripts/add-client.sh macbook
./scripts/add-client.sh ipad
./scripts/add-client.sh windows
```

---

## 📱 客户端配置

### iOS/iPadOS

1. App Store 下载 **WireGuard**
2. 扫描生成的二维码或导入配置文件
3. 点击开关连接

详细说明：[SUCCESS.md](SUCCESS.md)

### macOS

1. App Store 下载 **WireGuard**
2. 从文件导入隧道（选择 `clients/macbook.conf`）
3. 点击激活连接

详细说明：[MACBOOK_GUIDE.md](MACBOOK_GUIDE.md)

### Windows

1. 下载 [WireGuard](https://www.wireguard.com/install/)
2. 导入配置文件
3. 点击激活连接

### Android

1. Google Play 下载 **WireGuard**
2. 扫描二维码或导入配置文件
3. 点击开关连接

---

## 📁 项目结构

```
self-vpn/
├── README.md                 # 项目说明
├── DEPLOYMENT_GUIDE.md       # 完整部署指南
├── SUCCESS.md                # 部署成功后的使用指南
├── MACBOOK_GUIDE.md          # macOS 客户端指南
├── .env.example              # 环境变量模板
├── config/
│   ├── server.conf.template  # 服务端配置模板
│   └── client.conf.template  # 客户端配置模板
├── scripts/
│   ├── deploy.sh            # 完整部署脚本
│   ├── deploy-quick.sh      # 快速部署脚本
│   ├── add-client.sh        # 添加客户端
│   ├── monitor.sh           # 流量监控
│   └── security.sh          # 安全加固
└── clients/                 # 客户端配置（生成后）
    └── (不提交到 Git)
```

---

## 🔧 维护命令

### 查看服务器状态

```bash
ssh -i ~/.ssh/id_ed25519 root@YOUR_SERVER_IP "wg show"
```

### 流量监控

```bash
./scripts/monitor.sh
```

### 重启 VPN 服务

```bash
ssh -i ~/.ssh/id_ed25519 root@YOUR_SERVER_IP "systemctl restart wg-quick@wg0"
```

### 安全加固

```bash
./scripts/security.sh
```

---

## ⚠️ 安全提示

1. **不要提交敏感文件到 Git**
   - `.env` 包含服务器信息
   - `clients/*.conf` 包含私钥
   - 所有密钥文件

2. **定期备份配置**
   ```bash
   tar -czf vpn-backup-$(date +%Y%m%d).tar.gz clients/
   ```

3. **流量监控**
   - 每月限制：500GB
   - 建议用量：不超过 400GB
   - 每周检查一次

---

## 💰 成本计算

### DigitalOcean 方案

| 配置 | 价格 | 流量 | 可用时长（$30） |
|------|------|------|----------------|
| 512MB / 1CPU | $4/月 | 500GB | 7.5 个月 |
| 1GB / 1CPU | $6/月 | 1TB | 5 个月 |
| 2GB / 1CPU | $12/月 | 2TB | 2.5 个月 |

### 流量消耗参考

| 活动 | 每小时流量 |
|------|-----------|
| 网页浏览 | ~100MB |
| 1080p 视频 | ~3GB |
| 4K 视频 | ~7GB |
| 音乐流媒体 | ~50MB |

---

## 📚 文档

- [完整部署指南](DEPLOYMENT_GUIDE.md)
- [成功部署指南](SUCCESS.md)
- [macOS 客户端指南](MACBOOK_GUIDE.md)

---

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

---

## 📄 许可证

本项目采用 MIT License 开源。

---

## ⚖️ 免责声明

本项目仅供学习和研究使用。请遵守当地法律法规。作者不对使用本项目产生的任何后果负责。

---

**Made with ❤️ for privacy and security**
