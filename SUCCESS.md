# 🎉 VPN 部署成功！

## ✅ 服务器信息

- **IP 地址**: 159.223.131.230
- **端口**: 51820 (UDP)
- **区域**: NYC1 (纽约)
- **状态**: ✅ 运行中

---

## 📱 已配置客户端

### 1. iPhone
- **配置文件**: `clients/iphone.conf`
- **二维码**: `clients/iphone.png`
- **IP 地址**: 10.8.0.2

#### 安装步骤：
1. App Store 下载 **WireGuard** 官方 App
2. 打开 App，点击右上角 "+"
3. 选择 "从二维码创建"
4. 扫描 `clients/iphone.png` 或终端显示的二维码
5. 点击开关连接

---

## 🔄 添加更多设备

为其他 3 台设备添加配置（MacBook、iPad、Windows）：

```bash
# 方法 1: 使用自动化脚本（可能需要调试）
./scripts/add-client.sh macbook
./scripts/add-client.sh ipad
./scripts/add-client.sh windows

# 方法 2: 手动添加（推荐）
# 按照下面的手动步骤操作
```

### 手动添加客户端步骤：

1. **生成密钥**：
```bash
# 为 MacBook 生成密钥
mkdir -p clients
CLIENT_NAME="macbook"
ssh -i ~/.ssh/id_ed25519 root@159.223.131.230 "wg genkey" > clients/${CLIENT_NAME}_private.key
cat clients/${CLIENT_NAME}_private.key | ssh -i ~/.ssh/id_ed25519 root@159.223.131.230 "wg pubkey" > clients/${CLIENT_NAME}_public.key
```

2. **创建配置文件** `clients/macbook.conf`：
```ini
[Interface]
# 客户端私钥（从 clients/macbook_private.key 获取）
PrivateKey = YOUR_CLIENT_PRIVATE_KEY
# 客户端 IP 地址（递增：10.8.0.3、10.8.0.4、10.8.0.5）
Address = 10.8.0.3/32
# DNS 服务器
DNS = 1.1.1.1, 8.8.8.8

[Peer]
# 服务器公钥
PublicKey = qZkOm/pEEXAsfxybKhEZwsBpJhva5+ZjxNYfZQcGzkM=
# 允许的 IP 范围
AllowedIPs = 0.0.0.0/0, ::/0
# 服务器地址和端口
Endpoint = 159.223.131.230:51820
# 保持连接
PersistentKeepalive = 25
```

3. **添加到服务器**：
```bash
CLIENT_PUBLIC_KEY=$(cat clients/macbook_public.key)
ssh -i ~/.ssh/id_ed25519 root@159.223.131.230 << EOF
cat >> /etc/wireguard/wg0.conf << PEER

# Client: macbook
[Peer]
PublicKey = ${CLIENT_PUBLIC_KEY}
AllowedIPs = 10.8.0.3/32
PEER

wg syncconf wg0 <(wg-quick strip wg0)
echo "MacBook 已添加"
EOF
```

---

## 📊 监控和维护

### 查看服务器状态：
```bash
ssh -i ~/.ssh/id_ed25519 root@159.223.131.230 "wg show"
```

### 查看连接的客户端：
```bash
ssh -i ~/.ssh/id_ed25519 root@159.223.131.230 "wg show wg0 peers"
```

### 查看防火墙状态：
```bash
ssh -i ~/.ssh/id_ed25519 root@159.223.131.230 "ufw status"
```

### 重启 VPN 服务：
```bash
ssh -i ~/.ssh/id_ed25519 root@159.223.131.230 "systemctl restart wg-quick@wg0"
```

---

## ⚠️ 重要提示

### 流量管理
- **每月限制**: 500GB
- **告警阈值**: 400GB（80%）
- **监控建议**: 每周检查一次

### 安全建议
- ✅ **不要分享配置文件**（包含私钥）
- ✅ **定期备份** `clients/` 目录
- ✅ **不要在公共场合展示二维码**
- ✅ 建议执行安全加固：`./scripts/security.sh`

### 成本控制
- **月费**: $4/月
- **预算**: $30
- **可用时长**: 约 7.5 个月（到 2026年8月）
- **续费提醒**: 提前 1 个月充值

---

## 🔧 故障排查

### 无法连接 VPN

1. **检查服务器状态**：
```bash
ssh -i ~/.ssh/id_ed25519 root@159.223.131.230 "systemctl status wg-quick@wg0"
```

2. **查看日志**：
```bash
ssh -i ~/.ssh/id_ed25519 root@159.223.131.230 "journalctl -u wg-quick@wg0 -n 50"
```

3. **重启服务**：
```bash
ssh -i ~/.ssh/id_ed25519 root@159.223.131.230 "systemctl restart wg-quick@wg0"
```

### 速度慢

**原因分析**：
- NYC1（纽约）距离中国较远
- 预期延迟：200-300ms

**改进建议**：
1. 先测试使用 1-2 周
2. 如果确实太慢，考虑迁移到旧金山：
   - 销毁当前服务器
   - 重新创建时选择 **San Francisco (SFO3)**
   - 重新运行部署脚本

### 测试延迟：
```bash
ping 159.223.131.230
```

---

## 📞 下一步

1. ✅ **iPhone 已配置** - 立即测试连接
2. ⏳ **添加 MacBook** - 参考上面的手动步骤
3. ⏳ **添加 iPad** - IP 地址使用 10.8.0.4
4. ⏳ **添加 Windows** - IP 地址使用 10.8.0.5
5. 🔒 **安全加固** - 运行 `./scripts/security.sh`

---

**恭喜！你的 VPN 服务器已经成功部署！🎉**

如有问题，请参考 `DEPLOYMENT_GUIDE.md` 获取更多帮助。
