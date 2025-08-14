# Integration tests for API endpoints
import pytest
import json

class TestAPI:
    """Test API endpoints functionality."""
    
    def test_api_signup(self, client):
        """Test API signup endpoint."""
        response = client.post('/api/auth/signup', 
                             json={
                                 'username': 'apiuser',
                                 'email': 'api@test.com',
                                 'password': 'apipass123'
                             },
                             content_type='application/json')
        
        assert response.status_code == 201
        data = json.loads(response.data)
        assert data['msg'] == 'Signup successful'
    
    def test_api_duplicate_signup(self, client):
        """Test API signup with duplicate email."""
        # First signup
        client.post('/api/auth/signup', 
                   json={
                       'username': 'apiuser',
                       'email': 'api@test.com',
                       'password': 'apipass123'
                   },
                   content_type='application/json')
        
        # Duplicate signup
        response = client.post('/api/auth/signup', 
                             json={
                                 'username': 'apiuser2',
                                 'email': 'api@test.com',
                                 'password': 'apipass123'
                             },
                             content_type='application/json')
        
        assert response.status_code == 400
        data = json.loads(response.data)
        assert data['msg'] == 'Email already exists'
    
    def test_api_login(self, client):
        """Test API login endpoint."""
        # First signup
        client.post('/api/auth/signup', 
                   json={
                       'username': 'apiuser',
                       'email': 'api@test.com',
                       'password': 'apipass123'
                   },
                   content_type='application/json')
        
        # Then login
        response = client.post('/api/auth/login', 
                             json={
                                 'email': 'api@test.com',
                                 'password': 'apipass123'
                             },
                             content_type='application/json')
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert 'access_token' in data
        assert 'user' in data
    
    def test_api_invalid_login(self, client):
        """Test API login with invalid credentials."""
        response = client.post('/api/auth/login', 
                             json={
                                 'email': 'nonexistent@test.com',
                                 'password': 'wrongpass'
                             },
                             content_type='application/json')
        
        assert response.status_code == 401
        data = json.loads(response.data)
        assert data['msg'] == 'Invalid credentials'
