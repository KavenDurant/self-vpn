# 🍎 MacBook WireGuard 安装指南

## 📥 安装 WireGuard

### 方法 1：App Store（推荐）
1. 打开 **App Store**
2. 搜索 **"WireGuard"**
3. 点击 **"获取"** 安装（免费）

### 方法 2：Homebrew
```bash
brew install --cask wireguard-tools
```

---

## 🔧 导入配置

### 步骤 1：打开 WireGuard

安装完成后，在 **应用程序** 中找到并打开 **WireGuard**

### 步骤 2：导入配置文件

1. 点击窗口左下角的 **"从文件导入隧道..."** 按钮
   
   或者：点击菜单栏 **文件 → 从文件导入隧道...**

2. 选择文件：
   ```
   /Volumes/WD-1TB/WebstormProjects/self-vpn/clients/macbook.conf
   ```

3. 配置会自动导入，名称显示为 **"macbook"**

### 步骤 3：连接 VPN

1. 在 WireGuard 窗口中，选择 **"macbook"** 配置
2. 点击右侧的 **"激活"** 按钮
3. 首次连接可能需要授权，点击 **"允许"**

---

## ✅ 验证连接

### 方法 1：检查状态

在 WireGuard 窗口中查看：
- **状态**: 应显示 "活跃"
- **传输**: 应显示发送/接收的数据量
- **最近握手**: 应显示最近连接时间

### 方法 2：检查 IP 地址

打开终端，运行：
```bash
# 查看当前公网 IP
curl ifconfig.me
```

**预期结果**：显示 `159.223.131.230`（你的 VPN 服务器 IP）

### 方法 3：测试 DNS

```bash
# 查看当前 DNS 服务器
scutil --dns | grep nameserver
```

**预期结果**：应包含 `1.1.1.1` 和 `8.8.8.8`

---

## 🎛️ 高级设置（可选）

### 按需连接（On-Demand）

1. 选中 **"macbook"** 配置
2. 点击 **"编辑"**
3. 勾选 **"按需连接"**
4. 配置规则（比如连接到特定 Wi-Fi 时自动连接）

### 开机自动连接

WireGuard 会记住上次的连接状态：
- 如果关机前 VPN 是连接状态，重启后会自动连接
- 不需要额外配置

---

## 🔍 故障排查

### 问题 1：无法激活

**原因**：权限问题

**解决方案**：
1. 完全退出 WireGuard
2. 重新打开并尝试连接
3. 系统会弹出授权窗口，点击 **"允许"**
4. 可能需要输入 Mac 管理员密码

### 问题 2：连接后无网络

**原因**：DNS 配置问题

**解决方案**：
1. 点击 **"停用"** 断开连接
2. 等待 5 秒
3. 再次点击 **"激活"**

如果仍然无法访问网络：
```bash
# 刷新 DNS 缓存
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```

### 问题 3：速度慢

**原因**：服务器位于纽约，延迟较高

**测试延迟**：
```bash
ping 159.223.131.230
```

**预期延迟**：200-300ms

**改进建议**：
- 如果延迟超过 300ms，考虑迁移服务器到旧金山

### 问题 4：经常断开

**原因**：Mac 休眠后连接中断

**解决方案**：
1. 编辑配置（点击 **"编辑"**）
2. 确认 `PersistentKeepalive = 25` 存在
3. 保存并重新连接

---

## 📊 查看连接信息

### 在 WireGuard 中查看

点击 **"macbook"** 配置，右侧面板显示：
- **状态**：连接状态
- **公钥**：本机公钥
- **地址**：10.8.0.3
- **传输**：发送/接收流量
- **最近握手**：最后一次与服务器通信时间

### 使用命令行查看

```bash
# 查看 VPN 接口
ifconfig utun3  # 接口名称可能不同

# 查看路由
netstat -nr | grep utun
```

---

## 🔒 安全建议

1. **不要分享配置文件**
   - `macbook.conf` 包含你的私钥
   - 严禁发送给他人

2. **定期备份**
   ```bash
   cp /Volumes/WD-1TB/WebstormProjects/self-vpn/clients/macbook.conf ~/Documents/Backup/
   ```

3. **仅在需要时连接**
   - 节省流量
   - 降低服务器负载

---

## 🎯 使用场景

### 推荐使用 VPN 的场景：

✅ 访问国外网站和服务  
✅ 使用公共 Wi-Fi 时保护隐私  
✅ 绕过地域限制  
✅ 需要隐藏真实 IP 时  

### 不需要使用 VPN 的场景：

❌ 访问国内网站（会更慢）  
❌ 观看国内视频（可能无法访问）  
❌ 使用国内银行/支付（可能被风控）  
❌ 大文件下载（消耗流量）  

---

## 📱 配置文件位置

**配置文件**：
```
/Volumes/WD-1TB/WebstormProjects/self-vpn/clients/macbook.conf
```

**密钥文件**：
- 私钥：`clients/macbook_private.key`
- 公钥：`clients/macbook_public.key`

**备份建议**：
```bash
# 创建备份
tar -czf vpn-backup-$(date +%Y%m%d).tar.gz /Volumes/WD-1TB/WebstormProjects/self-vpn/clients/
```

---

## 🎉 完成！

你的 MacBook 已经配置完成，现在可以：

1. ✅ 点击 **"激活"** 连接 VPN
2. ✅ 访问 https://ifconfig.me 确认 IP 已变更
3. ✅ 正常使用网络

**提示**：
- 菜单栏会显示 WireGuard 图标
- 点击图标可快速切换连接状态
- 活跃时图标会高亮显示

---

**祝使用愉快！🎊**
