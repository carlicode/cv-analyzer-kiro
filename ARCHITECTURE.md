# Arquitectura del CV Analyzer 🏗️

## Visión General

El CV Analyzer es una API REST construida con FastAPI que procesa CVs en formato PDF o TXT, extrae el texto y utiliza AWS Bedrock (Claude 3.5 Sonnet) para generar feedback estructurado.

## Componentes Principales

### 1. API Layer (`main.py`)

**Responsabilidades:**
- Recibir requests HTTP
- Validar archivos (formato, tamaño)
- Orquestar el flujo de análisis
- Manejar errores y respuestas

**Endpoints:**
- `GET /` - Health check
- `POST /analyze` - Análisis de CV

**Flujo de Request:**
```
Cliente → FastAPI → Validación → Skills → AWS Bedrock → Respuesta
```

### 2. Skills Layer (`skills/analyze_cv.py`)

**Responsabilidades:**
- Extracción de texto desde bytes
- Comunicación con AWS Bedrock
- Parseo de respuestas de IA
- Manejo de errores de procesamiento

**Funciones principales:**
- `extract_text_from_pdf_bytes()` - Extrae texto de PDF usando PyMuPDF
- `extract_text_from_txt_bytes()` - Extrae texto de archivos TXT
- `analyze_with_bedrock()` - Llama a AWS Bedrock con el prompt
- `analyze_cv()` - Función principal que orquesta el análisis

### 3. Configuration (`config.py`)

**Responsabilidades:**
- Cargar variables de entorno
- Validar configuración crítica
- Centralizar constantes

## Flujo de Datos

```
┌─────────────────┐
│  Cliente HTTP   │
└────────┬────────┘
         │ POST /analyze
         │ (multipart/form-data)
         ▼
┌─────────────────┐
│   FastAPI       │
│   Endpoint      │
└────────┬────────┘
         │
         ├─► Validar extensión (.pdf, .txt)
         ├─► Validar tamaño (< 5MB)
         ├─► Leer archivo en memoria
         │
         ▼
┌─────────────────┐
│  analyze_cv()   │
│  (skill)        │
└────────┬────────┘
         │
         ├─► Extraer texto (PyMuPDF o decode)
         ├─► Validar contenido (> 50 chars)
         │
         ▼
┌─────────────────┐
│  AWS Bedrock    │
│  (Claude 3.5)   │
└────────┬────────┘
         │
         ├─► Procesar con IA
         ├─► Parsear JSON response
         │
         ▼
┌─────────────────┐
│  JSON Response  │
│  al Cliente     │
└─────────────────┘
```

## Modelo de Datos

### Request

```python
{
    "file": UploadFile,      # Archivo PDF o TXT
    "language": str          # "es", "en", etc. (opcional)
}
```

### Response Exitosa

```python
{
    "success": True,
    "data": {
        "score": int,              # 1-10
        "clarity_score": int,      # 1-10
        "strengths": List[str],    # 3-5 puntos
        "improvements": List[str], # 3-5 puntos
        "summary": str             # 2-3 líneas
    },
    "timestamp": str,              # ISO 8601
    "processing_time_ms": int
}
```

### Response de Error

```python
{
    "success": False,
    "error": str,
    "error_code": str,
    "timestamp": str
}
```

## Manejo de Errores

### Niveles de Error

1. **Validación (400)**
   - Formato inválido
   - Contenido insuficiente
   - Texto no extraíble

2. **Límites (413)**
   - Archivo muy grande

3. **Servicio (500)**
   - Error de AWS Bedrock
   - Error de autenticación AWS
   - Error inesperado

### Estrategia de Fallback

Si AWS Bedrock no devuelve JSON válido:
1. Intentar parsear JSON
2. Si falla, extraer puntuación con regex
3. Devolver respuesta parcial con valores por defecto

## Seguridad

### Validaciones Implementadas

- ✅ Tamaño máximo de archivo (5MB)
- ✅ Extensiones permitidas (PDF, TXT)
- ✅ Procesamiento en memoria (no se guarda en disco)
- ✅ Timeout en requests
- ✅ CORS configurado

### Consideraciones

- Las credenciales AWS se cargan desde variables de entorno
- No se almacenan archivos en disco
- Los bytes se descartan después del análisis
- No hay persistencia de datos

## Performance

### Métricas Esperadas

- **Tiempo de procesamiento:** 2-5 segundos
- **Throughput:** ~10-20 requests/minuto (limitado por Bedrock)
- **Memoria:** ~100-200MB por request

### Optimizaciones

- Procesamiento en memoria (sin I/O de disco)
- Streaming de archivos grandes
- Timeout configurado (30s)
- Respuestas comprimidas

## Escalabilidad

### Limitaciones Actuales

- Procesamiento síncrono
- Sin caché
- Sin queue system
- Limitado por rate limits de Bedrock

### Mejoras Futuras

1. **Procesamiento Asíncrono**
   - Implementar queue (Celery, RQ)
   - Background tasks con FastAPI

2. **Caché**
   - Redis para resultados recientes
   - Cache de embeddings

3. **Rate Limiting**
   - Implementar rate limiting por IP
   - Queue de requests

4. **Monitoreo**
   - Logs estructurados
   - Métricas con Prometheus
   - Tracing con OpenTelemetry

## Deployment

### Opciones Recomendadas

1. **AWS Lambda + API Gateway**
   - Ventaja: Acceso directo a Bedrock con IAM roles
   - Ventaja: Escalado automático
   - Ventaja: Pay-per-use

2. **Railway / Render**
   - Ventaja: Deploy simple
   - Ventaja: CI/CD integrado
   - Desventaja: Requiere configurar AWS credentials

3. **Docker + ECS/EKS**
   - Ventaja: Control total
   - Ventaja: Escalado horizontal
   - Desventaja: Más complejo

### Variables de Entorno Requeridas

```bash
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=xxx
AWS_SECRET_ACCESS_KEY=xxx
MAX_FILE_SIZE_MB=5
ALLOWED_EXTENSIONS=pdf,txt
DEFAULT_LANGUAGE=es
PORT=8000
```

## Testing

### Estrategia de Testing

1. **Unit Tests** (`tests/test_skills.py`)
   - Extracción de texto
   - Parseo de respuestas
   - Manejo de errores

2. **Integration Tests** (`tests/test_api.py`)
   - Endpoints completos
   - Validaciones
   - Respuestas de error

3. **E2E Tests** (manual)
   - Script `test_endpoint.py`
   - Pruebas con archivos reales

### Cobertura

- Target: > 80%
- Crítico: Skills y validaciones
- Opcional: Error handlers

## Dependencias

### Core

- `fastapi` - Framework web
- `uvicorn` - ASGI server
- `PyMuPDF` - Extracción de PDF
- `boto3` - AWS SDK

### Dev

- `pytest` - Testing
- `black` - Formatting
- `flake8` - Linting
- `mypy` - Type checking

## Próximos Pasos

1. ✅ Estructura básica
2. ⏳ Tests completos
3. ⏳ Deploy a Railway/AWS
4. ⏳ Frontend simple
5. ⏳ Monitoreo y logs
6. ⏳ Rate limiting
7. ⏳ Caché con Redis
8. ⏳ Queue system
