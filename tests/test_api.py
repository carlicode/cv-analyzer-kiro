"""
Tests para el API endpoint /analyze
"""
from fastapi.testclient import TestClient
from main import app
import io
import pytest

client = TestClient(app)


def test_root_endpoint():
    """Test del health check endpoint"""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert "service" in data


def test_analyze_invalid_format():
    """Test con formato de archivo inválido"""
    response = client.post(
        "/analyze",
        files={"file": ("doc.docx", io.BytesIO(b"content"), "application/vnd.openxmlformats")},
        data={"language": "es"}
    )
    assert response.status_code == 400
    data = response.json()
    assert data["detail"]["error_code"] == "INVALID_FORMAT"


def test_analyze_large_file():
    """Test con archivo muy grande (>5MB)"""
    large_content = b"x" * (6 * 1024 * 1024)  # 6MB
    response = client.post(
        "/analyze",
        files={"file": ("large.pdf", io.BytesIO(large_content), "application/pdf")},
        data={"language": "es"}
    )
    assert response.status_code == 413
    data = response.json()
    assert data["detail"]["error_code"] == "FILE_TOO_LARGE"


def test_analyze_empty_file():
    """Test con archivo vacío"""
    response = client.post(
        "/analyze",
        files={"file": ("empty.pdf", io.BytesIO(b""), "application/pdf")},
        data={"language": "es"}
    )
    # Debería fallar en la extracción de texto
    assert response.status_code in [400, 500]


@pytest.mark.skip(reason="Requiere AWS credentials y archivo PDF válido")
def test_analyze_valid_cv():
    """Test con CV válido (requiere AWS configurado)"""
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
    assert "timestamp" in data
    assert "processing_time_ms" in data
