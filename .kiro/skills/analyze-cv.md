# Skill: analyze-cv

## Descripción

Extrae texto de un PDF y llama a la IA para obtener feedback del CV.

## Inputs

| Nombre | Tipo | Requerido | Descripción |
|--------|------|-----------|-------------|
| file_path | string | sí | Ruta al PDF |
| language | string | no | Default: es |

## Outputs

| Nombre | Tipo | Descripción |
|--------|------|-------------|
| feedback | string | Análisis completo |
| score | integer | Puntuación 1-10 |
| error | string | Error o null |

## Paso 1 — Extraer texto

```python
import fitz  # PyMuPDF

def extract_text_from_pdf(file_path: str) -> str:
    doc = fitz.open(file_path)
    text = ""
    for page in doc:
        text += page.get_text()
    return text
```

## Paso 2 — Llamar a IA

```python
from anthropic import Anthropic

def analyze_with_ai(cv_text: str, language: str = "es") -> dict:
    client = Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))
    
    prompt = f"""Analiza este CV y devuelve feedback estructurado en {language}.

CV:
{cv_text}

Devuelve:
1. Puntos fuertes (3-5)
2. Áreas de mejora (3-5)
3. Claridad y formato (1-10)
4. Puntuación general (1-10)
"""
    
    message = client.messages.create(
        model="claude-3-5-sonnet-20241022",
        max_tokens=1024,
        messages=[{"role": "user", "content": prompt}]
    )
    
    return {
        "feedback": message.content[0].text,
        "score": extract_score(message.content[0].text)
    }
```

## Paso 3 — Integrar

```python
def analyze_cv(file_path: str, language: str = "es") -> dict:
    try:
        text = extract_text_from_pdf(file_path)
        result = analyze_with_ai(text, language)
        return result
    except Exception as e:
        return {"error": str(e), "feedback": None, "score": None}
```

## Uso

```python
result = analyze_cv("cv.pdf", language="es")
print(result["feedback"])
print(f"Score: {result['score']}/10")
```
