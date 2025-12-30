#!/bin/bash

#############################################
# SSH 安全加固脚本
# 用途: 加固 SSH 配置，提高安全性
#############################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 加载环境变量
source .env

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}SSH 安全加固${NC}"
echo -e "${GREEN}================================${NC}"
echo ""

# 确认执行
read -p "确认执行安全加固？这将修改 SSH 配置。(y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "已取消"
    exit 0
fi

echo -e "\n${GREEN}[1/5] 禁用 SSH 密码登录...${NC}"
ssh -i $SSH_KEY $SSH_USER@$SERVER_IP << 'ENDSSH'
    # 备份原配置
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
    
    # 禁用密码认证
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    
    # 禁用空密码
    sed -i 's/#PermitEmptyPasswords no/PermitEmptyPasswords no/' /etc/ssh/sshd_config
    sed -i 's/PermitEmptyPasswords yes/PermitEmptyPasswords no/' /etc/ssh/sshd_config
    
    # 禁用 root 密码登录（但允许密钥登录）
    sed -i 's/#PermitRootLogin yes/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
    sed -i 's/PermitRootLogin yes/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
    
    echo "SSH 配置已修改"
ENDSSH

echo -e "\n${GREEN}[2/5] 配置防暴力破解...${NC}"
ssh -i $SSH_KEY $SSH_USER@$SERVER_IP << 'ENDSSH'
    # 安装 fail2ban
    apt-get install -y fail2ban
    
    # 配置 fail2ban
    cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = 22
logpath = /var/log/auth.log
EOF
    
    # 启动 fail2ban
    systemctl enable fail2ban
    systemctl restart fail2ban
    
    echo "Fail2ban 已配置并启动"
ENDSSH

echo -e "\n${GREEN}[3/5] 配置自动安全更新...${NC}"
ssh -i $SSH_KEY $SSH_USER@$SERVER_IP << 'ENDSSH'
    # 安装自动更新
    apt-get install -y unattended-upgrades
    
    # 启用自动安全更新
    dpkg-reconfigure -plow unattended-upgrades
    
    echo "自动安全更新已启用"
ENDSSH

echo -e "\n${GREEN}[4/5] 重启 SSH 服务...${NC}"
ssh -i $SSH_KEY $SSH_USER@$SERVER_IP << 'ENDSSH'
    systemctl restart sshd
    echo "SSH 服务已重启"
ENDSSH

echo -e "\n${GREEN}[5/5] 验证配置...${NC}"
ssh -i $SSH_KEY $SSH_USER@$SERVER_IP << 'ENDSSH'
    echo "当前 SSH 配置:"
    grep "^PasswordAuthentication" /etc/ssh/sshd_config
    grep "^PermitRootLogin" /etc/ssh/sshd_config
    grep "^PermitEmptyPasswords" /etc/ssh/sshd_config
    
    echo ""
    echo "Fail2ban 状态:"
    systemctl status fail2ban --no-pager | grep Active
ENDSSH

echo -e "\n${GREEN}================================${NC}"
echo -e "${GREEN}安全加固完成！${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo -e "已完成:"
echo -e "✅ 禁用 SSH 密码登录"
echo -e "✅ 配置 Fail2ban 防暴力破解"
echo -e "✅ 启用自动安全更新"
echo ""
echo -e "${YELLOW}重要提示: 请确保你的 SSH 密钥可以正常登录！${NC}"
echo ""
