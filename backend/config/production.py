import os
SQLALCHEMY_DATABASE_URI = os.getenv('DATABASE_URL', 'postgresql://admin:adminpass@db:5432/ecommerce')
SQLALCHEMY_TRACK_MODIFICATIONS = False
SECRET_KEY = os.getenv('SECRET_KEY', 'prodsecretkey')
JWT_SECRET_KEY = os.getenv('SECRET_KEY', 'prodsecretkey')
