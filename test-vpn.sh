#!/usr/bin/env bash
set -euo pipefail

echo "=== VPN 连接测试脚本 ==="
echo ""

echo "📍 当前 IP 地址:"
CURRENT_IP="$(curl -s --max-time 5 ifconfig.me || true)"
if [[ -z "$CURRENT_IP" ]]; then
  echo "   (获取失败)"
else
  echo "   $CURRENT_IP"
fi

echo ""

echo "🌍 IP 归属地信息:"
if curl -s --max-time 5 ipinfo.io/json >/tmp/ipinfo.json 2>/dev/null; then
  python3 - <<'PY' 2>/dev/null || echo "   (解析失败)"
import json
with open('/tmp/ipinfo.json','r') as f:
    data=json.load(f)
print(f"   国家: {data.get('country','N/A')}")
PY
else
  echo "   (获取失败)"
fi

echo ""

echo "🔍 当前 DNS 服务器(以 nameserver[0] 为准):"
DNS0="$(scutil --dns | grep "nameserver\[0\]" | head -1 | awk '{print $3}' || true)"
if [[ -z "$DNS0" ]]; then
  echo "   (未知)"
else
  echo "   $DNS0"
fi

echo ""

echo "🇨🇳 测试百度访问:"
if curl -s --max-time 5 https://www.baidu.com | grep -q "百度"; then
  echo "   ✅ 可以访问"
else
  echo "   ❌ 无法访问"
fi

echo ""

echo "🌐 测试 Google 访问:"
if curl -s --max-time 5 https://www.google.com | grep -q "Google"; then
  echo "   ✅ 可以访问"
else
  echo "   ❌ 无法访问"
fi

echo ""
echo "=== 测试完成 ==="
