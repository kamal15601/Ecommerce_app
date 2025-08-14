# Unit tests for product functionality
import pytest
from app.models import Product, Category

class TestProducts:
    """Test product-related functionality."""
    
    def test_home_page_loads(self, client):
        """Test that home page loads correctly."""
        response = client.get('/')
        assert response.status_code == 200
        assert b'E-Commerce Store' in response.data
    
    def test_home_page_with_products(self, app, client):
        """Test home page displays products correctly."""
        with app.app_context():
            # Create test category and product
            category = Category(name='Test Category')
            from app import db
            db.session.add(category)
            db.session.commit()
            
            product = Product(
                name='Test Product',
                description='Test Description',
                price=29.99,
                brand='Test Brand',
                category_id=category.id
            )
            db.session.add(product)
            db.session.commit()
        
        response = client.get('/')
        assert response.status_code == 200
        assert b'Test Product' in response.data
        assert b'29.99' in response.data
    
    def test_product_detail_page(self, app, client):
        """Test product detail page."""
        with app.app_context():
            category = Category(name='Test Category')
            from app import db
            db.session.add(category)
            db.session.commit()
            
            product = Product(
                name='Test Product',
                description='Detailed description of test product',
                price=49.99,
                brand='Test Brand',
                category_id=category.id
            )
            db.session.add(product)
            db.session.commit()
            product_id = product.id
        
        response = client.get(f'/product/{product_id}')
        assert response.status_code == 200
        assert b'Test Product' in response.data
        assert b'Detailed description' in response.data
    
    def test_product_not_found(self, client):
        """Test product detail page with invalid ID."""
        response = client.get('/product/999')
        assert response.status_code == 404
