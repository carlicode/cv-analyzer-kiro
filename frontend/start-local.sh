#!/bin/bash

# TalentScope AI - Local Development Server
# This script starts a simple HTTP server for frontend development

echo "🚀 Starting TalentScope AI Frontend..."
echo ""
echo "📍 Frontend will be available at:"
echo "   http://localhost:8080"
echo ""
echo "⚠️  Make sure the backend is running on http://localhost:8000"
echo "   To start backend: cd .. && python main.py"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

# Check if Python is available
if command -v python3 &> /dev/null; then
    python3 -m http.server 8080
elif command -v python &> /dev/null; then
    python -m http.server 8080
else
    echo "❌ Python not found. Please install Python to run the local server."
    echo "   Or use: npx serve"
    exit 1
fi
