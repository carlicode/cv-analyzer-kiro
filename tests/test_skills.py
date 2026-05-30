"""
Tests para el módulo skills/analyze_cv.py
"""
import pytest
from skills.analyze_cv import (
    extract_text_from_txt_bytes,
    extract_score_from_text,
    analyze_cv
)


def test_extract_text_from_txt_bytes():
    """Test de extracción de texto desde bytes"""
    text_content = "Este es un CV de prueba con contenido válido"
    file_bytes = text_content.encode('utf-8')
    
    result = extract_text_from_txt_bytes(file_bytes)
    assert result == text_content


def test_extract_text_from_txt_bytes_empty():
    """Test con archivo de texto vacío"""
    file_bytes = b""
    
    with pytest.raises(ValueError, match="vacío"):
        extract_text_from_txt_bytes(file_bytes)


def test_extract_score_from_text():
    """Test de extracción de puntuación desde texto"""
    # Test con diferentes formatos
    assert extract_score_from_text("puntuación: 8") == 8
    assert extract_score_from_text("score: 7") == 7
    assert extract_score_from_text("8/10") == 8
    assert extract_score_from_text("sin puntuación") == 5  # default


def test_analyze_cv_insufficient_content():
    """Test con contenido insuficiente"""
    short_text = "CV"
    file_bytes = short_text.encode('utf-8')
    
    result = analyze_cv(file_bytes, language="es", file_type="txt")
    
    assert "error" in result
    assert "demasiado corto" in result["error"]


def test_analyze_cv_unsupported_type():
    """Test con tipo de archivo no soportado"""
    file_bytes = b"content"
    
    result = analyze_cv(file_bytes, language="es", file_type="docx")
    
    assert "error" in result
    assert "no soportado" in result["error"]


@pytest.mark.skip(reason="Requiere AWS credentials configuradas")
def test_analyze_cv_with_bedrock():
    """Test completo con AWS Bedrock (requiere configuración)"""
    cv_text = """
    Juan Pérez
    Desarrollador Full Stack
    
    Experiencia:
    - 5 años en desarrollo web
    - Python, JavaScript, React
    - Proyectos en AWS
    
    Educación:
    - Ingeniería en Sistemas
    """
    file_bytes = cv_text.encode('utf-8')
    
    result = analyze_cv(file_bytes, language="es", file_type="txt")
    
    assert "error" not in result or result["error"] is None
    assert result["score"] >= 1
    assert result["score"] <= 10
    assert isinstance(result["strengths"], list)
    assert isinstance(result["improvements"], list)
