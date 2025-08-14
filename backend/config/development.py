import os
SQLALCHEMY_DATABASE_URI = os.getenv('DATABASE_URL', 'postgresql://admin:adminpass@localhost:5432/ecommerce')
SQLALCHEMY_TRACK_MODIFICATIONS = False
SECRET_KEY = os.getenv('SECRET_KEY', 'devsecretkey')
JWT_SECRET_KEY = os.getenv('SECRET_KEY', 'devsecretkey')
