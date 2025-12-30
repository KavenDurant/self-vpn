#!/bin/bash

#############################################
# VPN 流量监控脚本
# 用途: 监控服务器流量使用情况
#############################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 加载环境变量
source .env

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}VPN 流量监控${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# 获取服务器流量信息
TRAFFIC_INFO=$(ssh -i $SSH_KEY $SSH_USER@$SERVER_IP << 'ENDSSH'
    # 获取网络接口流量
    RX_BYTES=$(cat /sys/class/net/eth0/statistics/rx_bytes)
    TX_BYTES=$(cat /sys/class/net/eth0/statistics/tx_bytes)
    TOTAL_BYTES=$((RX_BYTES + TX_BYTES))
    
    # 转换为 GB
    RX_GB=$(echo "scale=2; $RX_BYTES / 1024 / 1024 / 1024" | bc)
    TX_GB=$(echo "scale=2; $TX_BYTES / 1024 / 1024 / 1024" | bc)
    TOTAL_GB=$(echo "scale=2; $TOTAL_BYTES / 1024 / 1024 / 1024" | bc)
    
    echo "RX_GB=$RX_GB"
    echo "TX_GB=$TX_GB"
    echo "TOTAL_GB=$TOTAL_GB"
    
    # 获取当前月份的流量（需要安装 vnstat）
    if command -v vnstat &> /dev/null; then
        MONTH_TRAFFIC=$(vnstat --oneline | cut -d';' -f11)
        echo "MONTH_TRAFFIC=$MONTH_TRAFFIC"
    fi
    
    # 获取 WireGuard 连接信息
    echo "---WIREGUARD---"
    wg show wg0
ENDSSH
)

# 解析流量信息
eval "$(echo "$TRAFFIC_INFO" | grep -E '^(RX_GB|TX_GB|TOTAL_GB|MONTH_TRAFFIC)=')"

# 显示流量信息
echo -e "${GREEN}总流量统计:${NC}"
echo -e "接收 (RX): ${YELLOW}${RX_GB} GB${NC}"
echo -e "发送 (TX): ${YELLOW}${TX_GB} GB${NC}"
echo -e "总计: ${YELLOW}${TOTAL_GB} GB${NC}"
echo ""

# 计算流量使用百分比（基于每月 500GB 限制）
if [ ! -z "$TOTAL_GB" ]; then
    USAGE_PERCENT=$(echo "scale=2; $TOTAL_GB / $TRAFFIC_LIMIT_GB * 100" | bc)
    echo -e "流量限制: ${YELLOW}${TRAFFIC_LIMIT_GB} GB/月${NC}"
    echo -e "已使用: ${YELLOW}${USAGE_PERCENT}%${NC}"
    
    # 流量告警
    if (( $(echo "$TOTAL_GB > $TRAFFIC_WARNING_GB" | bc -l) )); then
        echo -e "${RED}⚠️  警告: 流量使用超过 ${TRAFFIC_WARNING_GB} GB！${NC}"
    fi
    
    if (( $(echo "$TOTAL_GB > $TRAFFIC_LIMIT_GB" | bc -l) )); then
        echo -e "${RED}❌ 错误: 流量已超出每月限制！${NC}"
    fi
fi

echo ""
echo -e "${GREEN}WireGuard 连接状态:${NC}"
echo "$TRAFFIC_INFO" | sed -n '/---WIREGUARD---/,$p' | tail -n +2

# 显示活动客户端
echo ""
echo -e "${GREEN}活动客户端:${NC}"
ACTIVE_CLIENTS=$(echo "$TRAFFIC_INFO" | grep -c "endpoint:" || echo "0")
echo -e "当前在线: ${YELLOW}${ACTIVE_CLIENTS}${NC} 台设备"

echo ""
echo -e "${BLUE}================================${NC}"
