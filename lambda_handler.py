"""
AWS Lambda Handler para CV Analyzer
Adaptador entre API Gateway y FastAPI
"""
from mangum import Mangum
from main import app

# Handler para AWS Lambda
handler = Mangum(app, lifespan="off")
