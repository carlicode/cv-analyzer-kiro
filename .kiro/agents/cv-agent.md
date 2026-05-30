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

**Request:**
```json
{
  "file": "base64_encoded_pdf",
  "language": "es"
}
```

**Response:**
```json
{
  "success": true,
  "feedback": "...",
  "score": 8,
  "timestamp": "2026-05-30T10:30:00Z",
  "processing_time_ms": 3200
}
```

**Error Response:**
```json
{
  "success": false,
  "error": "File size exceeds 5MB limit",
  "timestamp": "2026-05-30T10:30:00Z"
}
```

## Configuración

Variables de entorno necesarias:

```bash
ANTHROPIC_API_KEY=sk-ant-...
MAX_FILE_SIZE_MB=5
ALLOWED_EXTENSIONS=pdf,txt
DEFAULT_LANGUAGE=es
```

## Manejo de errores

| Error | Código | Mensaje |
|-------|--------|---------|
| Archivo muy grande | 413 | "File size exceeds limit" |
| Formato inválido | 400 | "Invalid file format" |
| Error de IA | 500 | "AI service unavailable" |
| Texto vacío | 400 | "No text extracted from file" |

## Métricas

- Tiempo de procesamiento promedio: < 5s
- Tasa de éxito: > 95%
- Timeout: 10s

## Testing

```python
# Test básico
def test_analyze_valid_cv():
    response = client.post("/analyze", files={"file": open("test_cv.pdf", "rb")})
    assert response.status_code == 200
    assert "feedback" in response.json()
    assert response.json()["score"] >= 1
    assert response.json()["score"] <= 10

# Test error
def test_analyze_large_file():
    response = client.post("/analyze", files={"file": large_file})
    assert response.status_code == 413
```

## Deployment

Railway:
```bash
railway up
```

AWS Lambda:
```bash
serverless deploy
```
