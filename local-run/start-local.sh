#!/bin/bash

# Start Local Development Environment

echo "🚀 Starting E-commerce Application (Local Development)"

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "❌ Virtual environment not found. Please run setup-local.sh first."
    exit 1
fi

# Activate virtual environment
source venv/bin/activate

# Load environment variables
export $(cat .env.local | xargs)

# Start Redis (if available)
if command -v redis-server &> /dev/null; then
    echo "🔴 Starting Redis server..."
    redis-server --daemonize yes --port 6379
fi

# Start PostgreSQL (if not running)
if ! pgrep -x "postgres" > /dev/null; then
    echo "🐘 Starting PostgreSQL..."
    sudo service postgresql start
fi

# Run database migrations (if needed)
echo "🗄️ Running database migrations..."
cd ..
export FLASK_APP=backend/app.py
flask db upgrade 2>/dev/null || echo "No migrations to run"

# Start the Flask application
echo "🌐 Starting Flask application..."
cd backend
python app.py

echo "✅ Application started!"
echo "Access the application at: http://localhost:5000"
