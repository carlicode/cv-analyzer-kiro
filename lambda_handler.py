"""
AWS Lambda Handler para CV Analyzer
Adaptador entre API Gateway y FastAPI
"""
from mangum import Mangum
from main import app

# lifespan="off" evita que Mangum intente gestionar el ciclo de vida ASGI
# API Gateway REST API con BinaryMediaTypes configurados envía multipart/form-data
# como base64; Mangum lo decodifica automáticamente via el flag isBase64Encoded
handler = Mangum(app, lifespan="off")
