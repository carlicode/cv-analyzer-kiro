"""
Skill: analyze-cv
Extrae texto de archivos (PDF/TXT) y llama a AWS Bedrock para obtener feedback estructurado
"""
import fitz  # PyMuPDF
import boto3
import json
import os
import re
from typing import Dict


def extract_text_from_pdf_bytes(file_bytes: bytes) -> str:
    """
    Extrae texto de un PDF desde bytes en memoria.
    No requiere guardar archivo en disco.
    
    Args:
        file_bytes: Contenido del PDF en bytes
        
    Returns:
        str: Texto extraído del PDF
        
    Raises:
        ValueError: Si no se puede extraer texto del PDF
    """
    doc = fitz.open(stream=file_bytes, filetype="pdf")
    text = ""
    for page in doc:
        text += page.get_text()
    doc.close()
    
    if not text.strip():
        raise ValueError("No se pudo extraer texto del PDF")
    
    return text


def extract_text_from_txt_bytes(file_bytes: bytes) -> str:
    """
    Extrae texto de un archivo TXT desde bytes en memoria.
    
    Args:
        file_bytes: Contenido del TXT en bytes
        
    Returns:
        str: Texto extraído del archivo
        
    Raises:
        ValueError: Si no se puede decodificar el archivo
    """
    try:
        # Intentar UTF-8 primero
        text = file_bytes.decode('utf-8')
    except UnicodeDecodeError:
        try:
            # Fallback a latin-1
            text = file_bytes.decode('latin-1')
        except Exception as e:
            raise ValueError(f"No se pudo decodificar el archivo de texto: {str(e)}")
    
    if not text.strip():
        raise ValueError("El archivo de texto está vacío")
    
    return text


def analyze_with_bedrock(cv_text: str, language: str = "es") -> Dict:
    """
    Analiza CV usando AWS Bedrock con Claude.
    Retorna respuesta estructurada en JSON.
    
    Args:
        cv_text: Texto del CV a analizar
        language: Idioma del análisis (default: es)
        
    Returns:
        dict: Análisis estructurado con score, strengths, improvements, etc.
        
    Raises:
        Exception: Si hay error en la llamada a Bedrock
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
    
    try:
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
    except Exception as e:
        raise Exception(f"Error al llamar a AWS Bedrock: {str(e)}")


def extract_score_from_text(text: str) -> int:
    """
    Extrae puntuación numérica del texto si el JSON falla.
    Busca patrones como "puntuación: 8" o "score: 7/10"
    
    Args:
        text: Texto donde buscar la puntuación
        
    Returns:
        int: Puntuación entre 1-10 (default: 5)
    """
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


def analyze_cv(file_bytes: bytes, language: str = "es", file_type: str = "pdf") -> Dict:
    """
    Función principal que orquesta el análisis completo.
    Recibe bytes del archivo, extrae texto y analiza con Bedrock.
    
    Args:
        file_bytes: Contenido del archivo en bytes
        language: Idioma del análisis (default: es)
        file_type: Tipo de archivo (pdf o txt)
        
    Returns:
        dict: Resultado del análisis o error
    """
    try:
        # Extraer texto según el tipo de archivo
        if file_type.lower() == "pdf":
            text = extract_text_from_pdf_bytes(file_bytes)
        elif file_type.lower() == "txt":
            text = extract_text_from_txt_bytes(file_bytes)
        else:
            return {
                "error": f"Tipo de archivo no soportado: {file_type}",
                "feedback": None,
                "score": None
            }
        
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
