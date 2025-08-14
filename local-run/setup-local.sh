#!/bin/bash

# Local Development Setup Script

echo "🚀 Setting up E-commerce Application for Local Development"

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed. Please install Python 3.8+ first."
    exit 1
fi

# Check if PostgreSQL is installed
if ! command -v psql &> /dev/null; then
    echo "❌ PostgreSQL is not installed. Please install PostgreSQL 12+ first."
    exit 1
fi

# Create virtual environment
echo "📦 Creating Python virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Install Python dependencies
echo "📚 Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements-local.txt

# Copy environment file
echo "⚙️ Setting up environment variables..."
cp .env.local ../.env

# Create database
echo "🗄️ Setting up local database..."
sudo -u postgres psql -c "CREATE USER ecommerce_user WITH PASSWORD 'dev_password';"
sudo -u postgres psql -c "CREATE DATABASE ecommerce_local OWNER ecommerce_user;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ecommerce_local TO ecommerce_user;"

# Initialize database
echo "🏗️ Initializing database schema..."
psql -h localhost -U ecommerce_user -d ecommerce_local -f init-local-db.sql

# Add sample data
echo "📊 Adding sample data..."
cd ..
python local-run/sample-data-local.py

echo "✅ Local setup complete!"
echo ""
echo "To start the application:"
echo "  cd local-run"
echo "  ./start-local.sh"
echo ""
echo "Application will be available at: http://localhost:5000"
