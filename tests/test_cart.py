# Unit tests for cart and wishlist functionality
import pytest

class TestCart:
    """Test shopping cart functionality."""
    
    def test_cart_requires_login(self, client):
        """Test that cart page requires authentication."""
        response = client.get('/cart')
        assert response.status_code == 302  # Redirect to login
    
    def test_cart_access_after_login(self, client, auth):
        """Test cart access after login."""
        auth.register()
        auth.login()
        
        response = client.get('/cart')
        assert response.status_code == 200
        assert b'Shopping Cart' in response.data
    
    def test_empty_cart_display(self, client, auth):
        """Test empty cart display."""
        auth.register()
        auth.login()
        
        response = client.get('/cart')
        assert response.status_code == 200
        assert b'Your cart is empty' in response.data

class TestWishlist:
    """Test wishlist functionality."""
    
    def test_wishlist_requires_login(self, client):
        """Test that wishlist page requires authentication."""
        response = client.get('/wishlist')
        assert response.status_code == 302  # Redirect to login
    
    def test_wishlist_access_after_login(self, client, auth):
        """Test wishlist access after login."""
        auth.register()
        auth.login()
        
        response = client.get('/wishlist')
        assert response.status_code == 200
        assert b'Wishlist' in response.data
    
    def test_empty_wishlist_display(self, client, auth):
        """Test empty wishlist display."""
        auth.register()
        auth.login()
        
        response = client.get('/wishlist')
        assert response.status_code == 200
        assert b'Your wishlist is empty' in response.data

class TestCheckout:
    """Test checkout functionality."""
    
    def test_checkout_requires_login(self, client):
        """Test that checkout page requires authentication."""
        response = client.get('/checkout')
        assert response.status_code == 302  # Redirect to login
    
    def test_checkout_access_after_login(self, client, auth):
        """Test checkout access after login."""
        auth.register()
        auth.login()
        
        response = client.get('/checkout')
        assert response.status_code == 200
        assert b'Checkout' in response.data
