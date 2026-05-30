#!/usr/bin/env python3
"""
Script para probar el endpoint /analyze con un archivo de prueba
"""
import requests
import sys
import json
from pathlib import Path


def test_analyze_endpoint(file_path: str, api_url: str = "http://localhost:8000", language: str = "es"):
    """
    Prueba el endpoint /analyze con un archivo
    
    Args:
        file_path: Ruta al archivo PDF o TXT
        api_url: URL base del API
        language: Idioma del análisis
    """
    file_path = Path(file_path)
    
    if not file_path.exists():
        print(f"❌ Error: El archivo {file_path} no existe")
        sys.exit(1)
    
    print(f"📄 Analizando archivo: {file_path.name}")
    print(f"🌐 API URL: {api_url}/analyze")
    print(f"🗣️  Idioma: {language}\n")
    
    try:
        with open(file_path, 'rb') as f:
            files = {'file': (file_path.name, f, 'application/pdf' if file_path.suffix == '.pdf' else 'text/plain')}
            data = {'language': language}
            
            response = requests.post(
                f"{api_url}/analyze",
                files=files,
                data=data,
                timeout=30
            )
        
        print(f"📊 Status Code: {response.status_code}\n")
        
        result = response.json()
        print("📋 Respuesta:")
        print(json.dumps(result, indent=2, ensure_ascii=False))
        
        if response.status_code == 200 and result.get("success"):
            print("\n✅ Análisis exitoso!")
            data = result["data"]
            print(f"\n🎯 Puntuación General: {data['score']}/10")
            print(f"📝 Claridad: {data['clarity_score']}/10")
            print(f"\n💪 Puntos Fuertes:")
            for strength in data['strengths']:
                print(f"  • {strength}")
            print(f"\n🔧 Áreas de Mejora:")
            for improvement in data['improvements']:
                print(f"  • {improvement}")
            print(f"\n📖 Resumen:")
            print(f"  {data['summary']}")
            print(f"\n⏱️  Tiempo de procesamiento: {result['processing_time_ms']}ms")
        else:
            print("\n❌ Error en el análisis")
            
    except requests.exceptions.ConnectionError:
        print("❌ Error: No se pudo conectar al servidor")
        print("   Asegúrate de que el servidor esté corriendo en", api_url)
        sys.exit(1)
    except Exception as e:
        print(f"❌ Error inesperado: {str(e)}")
        sys.exit(1)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Uso: python test_endpoint.py <archivo_cv.pdf> [api_url] [language]")
        print("\nEjemplos:")
        print("  python test_endpoint.py mi_cv.pdf")
        print("  python test_endpoint.py mi_cv.pdf http://localhost:8000 es")
        print("  python test_endpoint.py mi_cv.txt http://localhost:8000 en")
        sys.exit(1)
    
    file_path = sys.argv[1]
    api_url = sys.argv[2] if len(sys.argv) > 2 else "http://localhost:8000"
    language = sys.argv[3] if len(sys.argv) > 3 else "es"
    
    test_analyze_endpoint(file_path, api_url, language)
