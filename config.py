"""
Configuration module - Centraliza la configuración de la aplicación
"""
import os
from dotenv import load_dotenv

# Cargar variables de entorno desde .env
load_dotenv()


class Config:
    """Configuración de la aplicación"""
    
    # AWS Bedrock
    AWS_REGION = os.getenv("AWS_REGION", "us-east-1")
    AWS_ACCESS_KEY_ID = os.getenv("AWS_ACCESS_KEY_ID")
    AWS_SECRET_ACCESS_KEY = os.getenv("AWS_SECRET_ACCESS_KEY")
    
    # Application
    MAX_FILE_SIZE_MB = int(os.getenv("MAX_FILE_SIZE_MB", "5"))
    ALLOWED_EXTENSIONS = os.getenv("ALLOWED_EXTENSIONS", "pdf,txt").split(",")
    DEFAULT_LANGUAGE = os.getenv("DEFAULT_LANGUAGE", "es")
    PORT = int(os.getenv("PORT", "8000"))
    
    # Bedrock Model
    BEDROCK_MODEL_ID = "anthropic.claude-3-5-sonnet-20241022-v2:0"
    
    @classmethod
    def validate(cls):
        """Valida que las configuraciones críticas estén presentes"""
        if not cls.AWS_ACCESS_KEY_ID or not cls.AWS_SECRET_ACCESS_KEY:
            raise ValueError(
                "AWS credentials not configured. "
                "Please set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables."
            )
