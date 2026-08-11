# Supernova Agent Server

خدمة Python محلية لوكيل Supernova. لا يحتوي هذا المجلد على أي مفتاح API.

## التشغيل المحلي

```bash
cd SupernovaAgentServer
python3 -m venv .venv
source .venv/bin/activate
pip install -r agent/requirements.txt
export ANTHROPIC_API_KEY="ضع مفتاحك المحلي هنا"
export AMEEN_PROVIDER="anthropic"
python -m uvicorn agent.main:app --host 0.0.0.0 --port 8000
```

لا ترفع المفتاح إلى Git. ضعه في `~/.zshrc` محليًا أو في أسرار منصة النشر.

تتصل واجهة iPad بـ `ws://127.0.0.1:8000/ws` عند تشغيل المحاكي. عند تشغيلها على iPad حقيقي، غيّر العنوان في `AgentWebSocketService.swift` إلى عنوان IP المحلي للـMac أو إلى عنوان خدمة منشورة عبر HTTPS/WSS.
