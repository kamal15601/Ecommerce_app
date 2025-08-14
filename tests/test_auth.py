# Unit tests for authentication functionality
import pytest
from app.models import User
from werkzeug.security import check_password_hash

class TestAuth:
    """Test authentication views and functionality."""
    
    def test_signup_page_loads(self, client):
        """Test that signup page loads correctly."""
        response = client.get('/signup')
        assert response.status_code == 200
        assert b'Signup' in response.data
    
    def test_login_page_loads(self, client):
        """Test that login page loads correctly."""
        response = client.get('/login')
        assert response.status_code == 200
        assert b'Login' in response.data
    
    def test_user_registration(self, app, client):
        """Test user registration functionality."""
        response = client.post('/signup', data={
            'username': 'testuser',
            'email': 'test@example.com',
            'password': 'testpass123'
        })
        
        # Should redirect after successful registration
        assert response.status_code == 302
        
        # Check user was created in database
        with app.app_context():
            user = User.query.filter_by(email='test@example.com').first()
            assert user is not None
            assert user.username == 'testuser'
            assert check_password_hash(user.password_hash, 'testpass123')
    
    def test_duplicate_email_registration(self, app, client, auth):
        """Test that duplicate email registration is prevented."""
        # First registration
        auth.register()
        
        # Try to register with same email
        response = client.post('/signup', data={
            'username': 'testuser2',
            'email': 'test@example.com',
            'password': 'testpass123'
        })
        
        # Should redirect back to signup with error
        assert response.status_code == 302
    
    def test_user_login(self, client, auth):
        """Test user login functionality."""
        # Register a user first
        auth.register()
        
        # Login with correct credentials
        response = auth.login()
        assert response.status_code == 302
        
        # Check that we can access protected pages
        response = client.get('/cart')
        assert response.status_code == 200
    
    def test_invalid_login(self, client, auth):
        """Test login with invalid credentials."""
        # Try to login without registering
        response = auth.login()
        assert response.status_code == 302
        
        # Register user
        auth.register()
        
        # Try login with wrong password
        response = auth.login(password='wrongpass')
        assert response.status_code == 302
    
    def test_logout(self, client, auth):
        """Test user logout functionality."""
        auth.register()
        auth.login()
        
        response = auth.logout()
        assert response.status_code == 302
        
        # Should not be able to access protected pages
        response = client.get('/cart')
        assert response.status_code == 302  # Redirect to login
