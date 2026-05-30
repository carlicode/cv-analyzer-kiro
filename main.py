"""
CV Analyzer API - FastAPI Application
Orquesta el flujo completo del análisis de CVs
"""
from fastapi import FastAPI, UploadFile, File, HTTPException, Form
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
import time
from typing import Optional
import os

from skills.analyze_cv import analyze_cv

app = FastAPI(
    title="CV Analyzer API",
    description="API para analizar CVs y proporcionar feedback estructurado",
    version="1.0.0"
)

# Configurar CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configuración
MAX_FILE_SIZE = int(os.getenv("MAX_FILE_SIZE_MB", "5")) * 1024 * 1024  # 5MB en bytes
ALLOWED_EXTENSIONS = os.getenv("ALLOWED_EXTENSIONS", "pdf,txt").split(",")


@app.get("/")
async def root():
    """Health check endpoint"""
    return {
        "status": "ok",
        "service": "CV Analyzer API",
        "version": "1.0.0"
    }


@app.post("/analyze")
async def analyze_cv_endpoint(
    file: UploadFile = File(...),
    language: Optional[str] = Form("es")
):
    """
    Analiza un CV y devuelve feedback estructurado.
    
    Args:
        file: Archivo PDF o TXT del CV
        language: Idioma del análisis (default: es)
    
    Returns:
        JSON con score, strengths, improvements y summary
    """
    start_time = time.time()
    
    # Validar extensión
    file_extension = file.filename.split(".")[-1].lower() if file.filename else ""
    if file_extension not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=400,
            detail={
                "success": False,
                "error": f"Invalid file format. Only {', '.join(ALLOWED_EXTENSIONS).upper()} allowed",
                "error_code": "INVALID_FORMAT",
                "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
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
                "error": f"File size exceeds {MAX_FILE_SIZE // (1024*1024)}MB limit",
                "error_code": "FILE_TOO_LARGE",
                "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
            }
        )
    
    # Analizar con el skill
    result = analyze_cv(file_bytes, language, file_extension)
    
    # Manejar errores del skill
    if result.get("error"):
        error_code_map = {
            "No se pudo extraer texto": "NO_TEXT_EXTRACTED",
            "demasiado corto": "INSUFFICIENT_CONTENT",
            "Error de validación": "VALIDATION_ERROR",
            "AWS": "AWS_ERROR"
        }
        
        error_code = "ANALYSIS_ERROR"
        for key, code in error_code_map.items():
            if key.lower() in result["error"].lower():
                error_code = code
                break
        
        raise HTTPException(
            status_code=400 if error_code != "AWS_ERROR" else 500,
            detail={
                "success": False,
                "error": result["error"],
                "error_code": error_code,
                "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
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


if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", "8000"))
    uvicorn.run(app, host="0.0.0.0", port=port)
