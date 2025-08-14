# Unit tests for admin functionality
import pytest

class TestAdmin:
    """Test admin dashboard functionality."""
    
    def test_admin_requires_login(self, client):
        """Test that admin page requires authentication."""
        response = client.get('/admin')
        assert response.status_code == 302  # Redirect to login
    
    def test_admin_requires_admin_role(self, app, client, auth):
        """Test that admin page requires admin role."""
        # Register regular user
        auth.register()
        auth.login()
        
        response = client.get('/admin')
        assert response.status_code == 302  # Redirect due to lack of admin role
    
    def test_admin_access_for_admin_user(self, app, client):
        """Test admin access for admin user."""
        from app.models import User
        from werkzeug.security import generate_password_hash
        
        # Create admin user
        with app.app_context():
            from app import db
            admin_user = User(
                username='admin',
                email='admin@test.com',
                password_hash=generate_password_hash('adminpass'),
                is_admin=True
            )
            db.session.add(admin_user)
            db.session.commit()
        
        # Login as admin
        response = client.post('/login', data={
            'email': 'admin@test.com',
            'password': 'adminpass'
        })
        assert response.status_code == 302
        
        # Access admin page
        response = client.get('/admin')
        assert response.status_code == 200
        assert b'Admin Dashboard' in response.data
