# Agent: CV Analyzer Agent

## Rol

Orquesta el flujo completo del análisis de CVs: recibe archivo, valida, extrae, analiza y devuelve feedback.

## Responsabilidades

1. **Validación de entrada**
   - Verifica formato (.pdf o .txt)
   - Verifica tamaño (< 5MB)
   - Retorna error claro si falla

2. **Extracción**
   - Usa skill `analyze-cv` para extraer texto
   - Maneja errores de lectura

3. **Análisis**
   - Envía texto a Claude API
   - Procesa respuesta estructurada

4. **Respuesta**
   - Devuelve JSON con feedback y score
   - Incluye timestamp y metadata

## Flujo de ejecución

```
┌─────────────┐
│ Recibe PDF  │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Valida     │ ──── Error ───► Retorna error
└──────┬──────┘
       │ OK
       ▼
┌─────────────┐
│ Extrae texto│
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ Analiza IA  │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ Devuelve    │
│ feedback    │
└─────────────┘
```

## Endpoints (FastAPI)

### POST /analyze

**Request (multipart/form-data):**
```
file: [archivo PDF]
language: "es" (opcional)
```

**Manejo de archivo:**
- El archivo se recibe como `UploadFile` de FastAPI
- Se lee completamente en memoria como bytes: `file_bytes = await file.read()`
- NO se guarda en disco (procesamiento en memoria)
- Se pasa directamente al skill `analyze_cv(file_bytes)`
- Después del análisis, los bytes se descartan automáticamente

**Response (JSON):**
```json
{
  "success": true,
  "data": {
    "score": 8,
    "clarity_score": 7,
    "strengths": [
      "Experiencia relevante en el sector",
      "Habilidades técnicas bien detalladas",
      "Formato limpio y profesional"
    ],
    "improvements": [
      "Agregar logros cuantificables",
      "Incluir palabras clave del sector",
      "Reducir longitud a 2 páginas"
    ],
    "summary": "CV sólido con buena estructura. Mejorar con métricas concretas."
  },
  "timestamp": "2026-05-30T10:30:00Z",
  "processing_time_ms": 3200
}
```

**Error Response:**
```json
{
  "success": false,
  "error": "File size exceeds 5MB limit",
  "error_code": "FILE_TOO_LARGE",
  "timestamp": "2026-05-30T10:30:00Z"
}
```

## Configuración

Variables de entorno necesarias:

```bash
# AWS Bedrock
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key

# Configuración de la app
MAX_FILE_SIZE_MB=5
ALLOWED_EXTENSIONS=pdf,txt
DEFAULT_LANGUAGE=es
```

## Implementación del endpoint

```python
from fastapi import FastAPI, UploadFile, File, HTTPException, Form
from fastapi.responses import JSONResponse
import time
from typing import Optional

app = FastAPI()

MAX_FILE_SIZE = 5 * 1024 * 1024  # 5MB en bytes

@app.post("/analyze")
async def analyze_cv_endpoint(
    file: UploadFile = File(...),
    language: Optional[str] = Form("es")
):
    start_time = time.time()
    
    # Validar extensión
    if not file.filename.endswith(('.pdf', '.txt')):
        raise HTTPException(
            status_code=400,
            detail={
                "success": False,
                "error": "Invalid file format. Only PDF and TXT allowed",
                "error_code": "INVALID_FORMAT"
            }
        )
    
    # Leer archivo en memoria
    file_bytes = await file.read()
    
    # Validar tamaño
    if len(file_bytes) > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=413,
            detail={
                "success": False,
                "error": "File size exceeds 5MB limit",
                "error_code": "FILE_TOO_LARGE"
            }
        )
    
    # Analizar con el skill
    from skills.analyze_cv import analyze_cv
    result = analyze_cv(file_bytes, language)
    
    # Manejar errores del skill
    if result.get("error"):
        raise HTTPException(
            status_code=400,
            detail={
                "success": False,
                "error": result["error"],
                "error_code": "ANALYSIS_ERROR"
            }
        )
    
    # Calcular tiempo de procesamiento
    processing_time = int((time.time() - start_time) * 1000)
    
    # Respuesta exitosa
    return JSONResponse(content={
        "success": True,
        "data": {
            "score": result["score"],
            "clarity_score": result["clarity_score"],
            "strengths": result["strengths"],
            "improvements": result["improvements"],
            "summary": result["summary"]
        },
        "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "processing_time_ms": processing_time
    })
```

## Manejo de errores

| Error | Código HTTP | Error Code | Mensaje |
|-------|-------------|------------|---------|
| Archivo muy grande | 413 | FILE_TOO_LARGE | "File size exceeds 5MB limit" |
| Formato inválido | 400 | INVALID_FORMAT | "Invalid file format. Only PDF and TXT allowed" |
| Error de Bedrock | 500 | BEDROCK_ERROR | "AWS Bedrock service unavailable" |
| Texto vacío | 400 | NO_TEXT_EXTRACTED | "No text extracted from file" |
| CV muy corto | 400 | INSUFFICIENT_CONTENT | "CV content is too short" |
| Error AWS auth | 500 | AWS_AUTH_ERROR | "AWS authentication failed" |

## Métricas

- Tiempo de procesamiento promedio: < 5s
- Tasa de éxito: > 95%
- Timeout: 10s

## Testing

```python
from fastapi.testclient import TestClient
from main import app
import io

client = TestClient(app)

# Test básico
def test_analyze_valid_cv():
    with open("test_cv.pdf", "rb") as f:
        response = client.post(
            "/analyze",
            files={"file": ("cv.pdf", f, "application/pdf")},
            data={"language": "es"}
        )
    
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert "data" in data
    assert data["data"]["score"] >= 1
    assert data["data"]["score"] <= 10
    assert len(data["data"]["strengths"]) > 0
    assert len(data["data"]["improvements"]) > 0

# Test archivo muy grande
def test_analyze_large_file():
    large_content = b"x" * (6 * 1024 * 1024)  # 6MB
    response = client.post(
        "/analyze",
        files={"file": ("large.pdf", io.BytesIO(large_content), "application/pdf")}
    )
    assert response.status_code == 413
    assert response.json()["error_code"] == "FILE_TOO_LARGE"

# Test formato inválido
def test_analyze_invalid_format():
    response = client.post(
        "/analyze",
        files={"file": ("doc.docx", io.BytesIO(b"content"), "application/vnd.openxmlformats")}
    )
    assert response.status_code == 400
    assert response.json()["error_code"] == "INVALID_FORMAT"
```

## Deployment

### AWS Lambda (Recomendado - ya tienes acceso a Bedrock)

```bash
# Usar AWS SAM o Serverless Framework
sam build
sam deploy --guided
```

**Ventajas:**
- Acceso directo a Bedrock sin configurar credenciales
- Usa IAM roles automáticamente
- Escalado automático
- Pay-per-use

**Configuración Lambda:**
- Runtime: Python 3.11
- Memory: 512MB
- Timeout: 30s
- IAM Role: Debe tener permisos `bedrock:InvokeModel`

### Railway (Alternativa)

```bash
railway up
```

**Nota:** Necesitarás configurar AWS credentials como variables de entorno.

### Permisos IAM necesarios

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "bedrock:InvokeModel"
      ],
      "Resource": "arn:aws:bedrock:*::foundation-model/anthropic.claude-3-5-sonnet-20241022-v2:0"
    }
  ]
}
```
