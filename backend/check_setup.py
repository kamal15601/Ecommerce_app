# Simple initialization script to verify setup
import os
import sys

def check_setup():
    print("🔍 Checking E-Commerce App Setup...")
    print("=" * 50)
    
    # Check Python version
    python_version = sys.version_info
    print(f"✅ Python Version: {python_version.major}.{python_version.minor}.{python_version.micro}")
    
    # Check if we can import required modules
    try:
        import flask
        print(f"✅ Flask: {flask.__version__}")
    except ImportError:
        print("❌ Flask not installed. Run: pip install -r requirements.txt")
        return False
    
    try:
        import sqlalchemy
        print(f"✅ SQLAlchemy: {sqlalchemy.__version__}")
    except ImportError:
        print("❌ SQLAlchemy not installed. Run: pip install -r requirements.txt")
        return False
    
    try:
        import psycopg2
        print("✅ psycopg2 (PostgreSQL driver) installed")
    except ImportError:
        print("❌ psycopg2 not installed. Run: pip install -r requirements.txt")
        return False
    
    # Check if app can be imported
    try:
        from app import create_app
        app = create_app()
        print("✅ Flask app can be created successfully")
    except Exception as e:
        print(f"❌ Error creating Flask app: {e}")
        return False
    
    print("=" * 50)
    print("🎉 Setup check completed successfully!")
    print("\n📋 Next steps:")
    print("1. Ensure PostgreSQL is running")
    print("2. Create database 'ecommerce' with user 'admin'")
    print("3. Run: python add_sample_data.py")
    print("4. Run: python app.py")
    print("5. Open browser to http://localhost:5000")
    
    return True

if __name__ == '__main__':
    check_setup()
