# Test configuration and dependencies
import pytest
from app import create_app, db
from app.models import User, Product, Category
import tempfile
import os

@pytest.fixture
def app():
    """Create and configure a new app instance for each test."""
    # Create a temporary file to isolate the database for each test
    db_fd, db_path = tempfile.mkstemp()
    
    app = create_app()
    app.config['TESTING'] = True
    app.config['SQLALCHEMY_DATABASE_URI'] = f'sqlite:///{db_path}'
    app.config['WTF_CSRF_ENABLED'] = False
    
    with app.app_context():
        db.create_all()
        yield app
        db.drop_all()
    
    os.close(db_fd)
    os.unlink(db_path)

@pytest.fixture
def client(app):
    """A test client for the app."""
    return app.test_client()

@pytest.fixture
def runner(app):
    """A test runner for the app's Click commands."""
    return app.test_cli_runner()

@pytest.fixture
def auth(client):
    """Authentication helper."""
    class AuthActions:
        def __init__(self, client):
            self._client = client

        def register(self, username='testuser', email='test@example.com', password='testpass'):
            return self._client.post(
                '/signup',
                data={'username': username, 'email': email, 'password': password}
            )

        def login(self, email='test@example.com', password='testpass'):
            return self._client.post(
                '/login',
                data={'email': email, 'password': password}
            )

        def logout(self):
            return self._client.get('/logout')

    return AuthActions(client)
