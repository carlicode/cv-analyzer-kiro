# CV Analyzer

Analizador de CVs con IA que da feedback estructurado en segundos.

**Stack:** Python 3.12 · FastAPI · AWS Bedrock (Claude Haiku 4.5) · Vanilla JS · AWS Lambda + S3

---

## Arquitectura

```
S3 (frontend)  →  API Gateway  →  Lambda (FastAPI)  →  Bedrock (Claude Haiku 4.5)
```

- Frontend estático en S3 (HTML/CSS/JS)
- Backend serverless en Lambda via Mangum
- Sin base de datos — completamente stateless
- Región: `us-east-1`
- Soporte PDF y TXT (API Gateway configurado con binary media types para PDFs)

---

## Deploy a AWS

### Prerequisitos

```bash
aws configure          # credenciales AWS
sam --version          # AWS SAM CLI instalado
```

Habilitar acceso al modelo en Bedrock:
**AWS Console → Bedrock → Model access → us-east-1 → Claude Haiku 4.5** (`anthropic.claude-haiku-4-5-20251001-v1:0`)

### Deploy completo (backend + frontend S3)

```bash
./deploy-aws.sh
```

El script hace todo:
1. `sam build` + `sam deploy` → Lambda + API Gateway
2. Crea bucket S3 público
3. Inyecta la URL de API en el frontend
4. Sube archivos a S3

Al finalizar imprime las URLs del frontend y la API.

### Solo backend (Lambda)

```bash
sam build
sam deploy
```

### Limpiar recursos

```bash
sam delete --stack-name cv-analyzer-stack
aws s3 rb s3://cv-analyzer-frontend-$(aws sts get-caller-identity --query Account --output text) --force
```

---

## Desarrollo local

```bash
# Instalar dependencias
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt

# Variables de entorno (copiar y completar)
cp .env.example .env

# Backend
python main.py
# → http://localhost:8000

# Frontend (otra terminal)
cd frontend && python -m http.server 8080
# → http://localhost:8080
```

### Docker

```bash
docker-compose up
# → http://localhost:8000
```

---

## Estructura

```
cv-analyzer-kiro/
├── main.py                 # FastAPI app
├── lambda_handler.py       # Adaptador Lambda (Mangum)
├── skills/
│   └── analyze_cv.py       # Extracción PDF/TXT + llamada a Bedrock
├── frontend/               # UI estática (HTML/CSS/JS)
├── tests/                  # Tests unitarios e integración
├── template.yaml           # SAM / CloudFormation
├── samconfig.toml          # Configuración de deploy SAM
├── deploy-aws.sh           # Script de deploy completo
├── cleanup-aws.sh          # Limpieza de recursos AWS
├── requirements.txt        # Dependencias de producción
├── requirements-dev.txt    # Dependencias de desarrollo y tests
└── .env.example            # Variables de entorno
```

---

## API

| Método | Ruta | Descripción |
|--------|------|-------------|
| `GET` | `/` | Health check |
| `POST` | `/analyze` | Analiza un CV |

**POST /analyze** — `multipart/form-data`

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `file` | File | PDF o TXT (máx 5MB) |
| `language` | string | `es` o `en` (default: `es`) |

**Respuesta exitosa:**

```json
{
  "success": true,
  "data": {
    "score": 7,
    "clarity_score": 8,
    "strengths": ["..."],
    "improvements": ["..."],
    "summary": "..."
  },
  "processing_time_ms": 3200
}
```

---

## Tests

```bash
pip install -r requirements-dev.txt
pytest tests/ -v
```

---

Made with ❤️ by @Carli.Code — GDG Santa Cruz · Women Techmakers · UCB Bolivia
