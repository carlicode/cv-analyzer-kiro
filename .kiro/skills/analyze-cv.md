# Skill: analyze-cv

## Descripción

Extrae texto de un PDF (desde bytes en memoria) y llama a AWS Bedrock para obtener feedback estructurado del CV.

## Inputs

| Nombre | Tipo | Requerido | Descripción |
|--------|------|-----------|-------------|
| file_bytes | bytes | sí | Contenido del PDF en bytes |
| language | string | no | Default: es |

## Outputs

| Nombre | Tipo | Descripción |
|--------|------|-------------|
| feedback | dict | Análisis estructurado con secciones |
| score | integer | Puntuación 1-10 |
| strengths | list | Lista de puntos fuertes |
| improvements | list | Lista de áreas de mejora |
| clarity_score | integer | Puntuación de claridad 1-10 |
| error | string | Error o null |

## Paso 1 — Extraer texto desde bytes

```python
import fitz  # PyMuPDF
import io

def extract_text_from_pdf_bytes(file_bytes: bytes) -> str:
    """
    Extrae texto de un PDF desde bytes en memoria.
    No requiere guardar archivo en disco.
    """
    doc = fitz.open(stream=file_bytes, filetype="pdf")
    text = ""
    for page in doc:
        text += page.get_text()
    doc.close()
    
    if not text.strip():
        raise ValueError("No se pudo extraer texto del PDF")
    
    return text
```

## Paso 2 — Llamar a AWS Bedrock

```python
import boto3
import json
import os

def analyze_with_bedrock(cv_text: str, language: str = "es") -> dict:
    """
    Analiza CV usando AWS Bedrock con Claude.
    Retorna respuesta estructurada en JSON.
    """
    bedrock = boto3.client(
        service_name='bedrock-runtime',
        region_name=os.getenv('AWS_REGION', 'us-east-1')
    )
    
    prompt = f"""Analiza este CV y devuelve feedback estructurado en {language}.

CV:
{cv_text}

IMPORTANTE: Responde ÚNICAMENTE con un objeto JSON válido con esta estructura exacta:
{{
  "puntos_fuertes": ["punto 1", "punto 2", "punto 3"],
  "areas_mejora": ["mejora 1", "mejora 2", "mejora 3"],
  "claridad_formato": 8,
  "puntuacion_general": 7,
  "resumen": "Breve resumen del CV en 2-3 líneas"
}}

No incluyas texto adicional, solo el JSON."""
    
    body = json.dumps({
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 2000,
        "messages": [
            {
                "role": "user",
                "content": prompt
            }
        ]
    })
    
    response = bedrock.invoke_model(
        modelId='anthropic.claude-3-5-sonnet-20241022-v2:0',
        body=body
    )
    
    response_body = json.loads(response['body'].read())
    ai_response = response_body['content'][0]['text']
    
    # Parsear JSON de la respuesta
    try:
        feedback_data = json.loads(ai_response)
        return {
            "feedback": feedback_data,
            "score": feedback_data.get("puntuacion_general", 5),
            "strengths": feedback_data.get("puntos_fuertes", []),
            "improvements": feedback_data.get("areas_mejora", []),
            "clarity_score": feedback_data.get("claridad_formato", 5),
            "summary": feedback_data.get("resumen", "")
        }
    except json.JSONDecodeError:
        # Fallback si la IA no devuelve JSON válido
        return {
            "feedback": {"raw_response": ai_response},
            "score": extract_score_from_text(ai_response),
            "strengths": [],
            "improvements": [],
            "clarity_score": 5,
            "summary": ai_response[:200]
        }

def extract_score_from_text(text: str) -> int:
    """
    Extrae puntuación numérica del texto si el JSON falla.
    Busca patrones como "puntuación: 8" o "score: 7/10"
    """
    import re
    
    # Buscar patrones de puntuación
    patterns = [
        r'puntuaci[oó]n[:\s]+(\d+)',
        r'score[:\s]+(\d+)',
        r'(\d+)\s*/\s*10',
    ]
    
    for pattern in patterns:
        match = re.search(pattern, text.lower())
        if match:
            score = int(match.group(1))
            return min(max(score, 1), 10)  # Clamp entre 1-10
    
    return 5  # Default si no se encuentra
```

## Paso 3 — Integrar

```python
def analyze_cv(file_bytes: bytes, language: str = "es") -> dict:
    """
    Función principal que orquesta el análisis completo.
    Recibe bytes del PDF, extrae texto y analiza con Bedrock.
    """
    try:
        # Extraer texto
        text = extract_text_from_pdf_bytes(file_bytes)
        
        # Validar que hay contenido
        if len(text.strip()) < 50:
            return {
                "error": "El CV es demasiado corto o no contiene texto suficiente",
                "feedback": None,
                "score": None
            }
        
        # Analizar con IA
        result = analyze_with_bedrock(text, language)
        return result
        
    except ValueError as e:
        return {
            "error": f"Error de validación: {str(e)}",
            "feedback": None,
            "score": None
        }
    except Exception as e:
        return {
            "error": f"Error inesperado: {str(e)}",
            "feedback": None,
            "score": None
        }
```

## Uso

```python
# Desde FastAPI endpoint
with open("cv.pdf", "rb") as f:
    file_bytes = f.read()

result = analyze_cv(file_bytes, language="es")

if result.get("error"):
    print(f"Error: {result['error']}")
else:
    print(f"Score: {result['score']}/10")
    print(f"Puntos fuertes: {result['strengths']}")
    print(f"Áreas de mejora: {result['improvements']}")
```

## Configuración AWS

Variables de entorno necesarias:

```bash
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
# O usar IAM roles si está en EC2/Lambda
```

## Dependencias

```txt
PyMuPDF>=1.23.0
boto3>=1.34.0
```
