# Self-VPN 部署指南

## ✅ 服务器信息

- **主机名**: vpn-us-sf
- **IP 地址**: `159.223.131.230`
- **系统**: Ubuntu 22.04 LTS x64
- **配置**: 1 vCPU / 0.5GB RAM / 10GB Disk
- **区域**: NYC1 (纽约)
- **费用**: $4/月 (可用约 7.5 个月)

⚠️ **注意**: 你选择的是纽约区域，延迟可能较高（200-300ms）。如果速度不理想，建议后续迁移到旧金山。

---

## 🚀 快速部署（3 步完成）

### 第 1 步：测试 SSH 连接

```bash
ssh -i ~/.ssh/id_ed25519 root@159.223.131.230
```

如果能成功连接，输入 `exit` 退出，继续下一步。

---

### 第 2 步：一键部署 WireGuard

```bash
./scripts/deploy.sh
```

**这个脚本会自动完成：**
- ✅ 更新系统并安装 WireGuard
- ✅ 生成服务器密钥对
- ✅ 配置防火墙
- ✅ 启动 WireGuard 服务

**预计时间**: 3-5 分钟

---

### 第 3 步：添加客户端设备

为你的 4 台设备生成配置：

```bash
# iPhone
./scripts/add-client.sh iphone

# MacBook
./scripts/add-client.sh macbook

# iPad
./scripts/add-client.sh ipad

# Windows PC
./scripts/add-client.sh windows
```

每个命令会生成：
- 配置文件：`clients/<设备名>.conf`
- 二维码图片：`clients/<设备名>.png`

---

## 📱 客户端安装

### iOS/iPadOS (iPhone/iPad)

1. **App Store** 搜索并安装 **WireGuard**
2. 打开 App，点击右上角 **"+"**
3. 选择 **"从二维码创建"**
4. 扫描终端显示的二维码（或打开 `clients/iphone.png`）
5. 点击开关连接

### macOS (MacBook)

1. **App Store** 搜索并安装 **WireGuard**
2. 打开 App，点击 **"从文件导入隧道"**
3. 选择 `clients/macbook.conf`
4. 点击 **"激活"** 连接

### Windows PC

1. 访问 https://www.wireguard.com/install/ 下载安装
2. 打开 WireGuard，点击 **"导入隧道"**
3. 选择 `clients/windows.conf`
4. 点击 **"激活"** 连接

---

## 🔒 安全加固（推荐执行）

部署完成后，建议运行安全加固脚本：

```bash
./scripts/security.sh
```

**包括：**
- 禁用 SSH 密码登录（仅允许密钥）
- 安装 Fail2ban 防暴力破解
- 启用自动安全更新

---

## 📊 日常维护

### 查看流量使用

```bash
./scripts/monitor.sh
```

会显示：
- 总流量使用情况
- 当前在线设备数
- 流量告警（超过 400GB 会提示）

### 查看 VPN 状态

```bash
ssh -i ~/.ssh/id_ed25519 root@159.223.131.230 "wg show"
```

### 重启 VPN 服务

```bash
ssh -i ~/.ssh/id_ed25519 root@159.223.131.230 "systemctl restart wg-quick@wg0"
```

---

## ⚠️ 重要提示

### 流量管理
- **每月限制**: 500GB
- **建议用量**: 每月不超过 400GB
- **监控频率**: 每周检查一次

### 成本控制
- **预算**: $30
- **月费**: $4
- **可用时长**: 约 7.5 个月（到 2026年8月）
- **续费提醒**: 建议提前 1 个月充值

### 安全注意事项
- ✅ 配置文件包含私钥，**严禁分享**
- ✅ 定期备份 `clients/` 目录
- ✅ 不要在公共场合展示二维码
- ✅ 每月更新服务器系统一次

---

## 🆘 故障排查

### 问题 1: 无法连接 VPN

**解决方案：**

```bash
# 1. 检查服务器 WireGuard 状态
ssh -i ~/.ssh/id_ed25519 root@159.223.131.230 "systemctl status wg-quick@wg0"

# 2. 检查防火墙
ssh -i ~/.ssh/id_ed25519 root@159.223.131.230 "ufw status"

# 3. 重启 WireGuard
ssh -i ~/.ssh/id_ed25519 root@159.223.131.230 "systemctl restart wg-quick@wg0"

# 4. 查看日志
ssh -i ~/.ssh/id_ed25519 root@159.223.131.230 "journalctl -u wg-quick@wg0 -n 50"
```

### 问题 2: 连接速度慢

**可能原因：**
- 纽约机房距离中国较远（延迟 200-300ms）
- 本地网络问题
- 服务器负载过高

**解决方案：**
1. 测试延迟：`ping 159.223.131.230`
2. 如果延迟过高，考虑迁移到旧金山机房
3. 检查服务器 CPU：`ssh root@159.223.131.230 "top -n 1"`

### 问题 3: 流量超限

**解决方案：**
1. 查看流量：`./scripts/monitor.sh`
2. 减少视频观看（1080p 视频约 3GB/小时）
3. 仅在需要时连接 VPN
4. 升级套餐到更高流量

---

## 📈 性能优化建议

### 如果速度不理想

1. **更换区域** - 建议迁移到：
   - San Francisco (SFO3) - 延迟 150-180ms
   - Singapore (SGP1) - 延迟 80-120ms

2. **升级配置** - 如果 2 台设备同时使用卡顿：
   - 升级到 $6/月 (1GB RAM) 套餐

3. **优化 MTU** - 编辑客户端配置：
   ```
   [Interface]
   MTU = 1420  # 添加这行，可能提升速度
   ```

---

## 📁 文件说明

```
self-vpn/
├── .env                      # 服务器配置（已配置 IP）
├── scripts/
│   ├── deploy.sh            # 一键部署脚本
│   ├── add-client.sh        # 添加客户端
│   ├── monitor.sh           # 流量监控
│   └── security.sh          # 安全加固
├── clients/                 # 客户端配置（执行后生成）
│   ├── iphone.conf
│   ├── iphone.png
│   ├── macbook.conf
│   └── ...
└── config/
    ├── server_public.key    # 服务器公钥（部署后生成）
    └── *.template           # 配置模板
```

---

## 🎯 下一步行动

1. **立即执行**: `./scripts/deploy.sh` - 部署 VPN
2. **添加设备**: `./scripts/add-client.sh <设备名>` - 生成配置
3. **安全加固**: `./scripts/security.sh` - 加固安全
4. **测试连接**: 在客户端导入配置并测试

---

**祝使用愉快！如有问题，请查看故障排查部分。🎉**
