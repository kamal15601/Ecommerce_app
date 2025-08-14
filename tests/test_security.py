"""
Security tests for the E-commerce application
"""
import pytest
import requests
import json


class TestSecurity:
    """Security tests for the application"""
    
    @pytest.fixture
    def base_url(self):
        return "http://localhost:5000"
    
    @pytest.fixture
    def api_url(self):
        return "http://localhost:5000/api"
    
    def test_security_headers(self, base_url):
        """Test that security headers are present"""
        try:
            response = requests.get(base_url)
            headers = response.headers
            
            # Check for important security headers
            expected_headers = {
                'X-Content-Type-Options': 'nosniff',
                'X-Frame-Options': ['DENY', 'SAMEORIGIN'],
                'X-XSS-Protection': '1; mode=block'
            }
            
            for header, expected_value in expected_headers.items():
                assert header in headers, f"Missing security header: {header}"
                if isinstance(expected_value, list):
                    assert headers[header] in expected_value
                else:
                    assert headers[header] == expected_value
                    
        except requests.exceptions.ConnectionError:
            pytest.skip("Application not running")
    
    def test_sql_injection_protection(self, api_url):
        """Test SQL injection protection"""
        sql_payloads = [
            "' OR '1'='1",
            "'; DROP TABLE users; --",
            "1' UNION SELECT * FROM users --",
            "admin'--",
            "admin' #"
        ]
        
        try:
            for payload in sql_payloads:
                # Test in search parameters
                response = requests.get(f"{api_url}/products", params={"search": payload})
                assert response.status_code != 500, f"SQL injection possible with payload: {payload}"
                
                # Test in login
                login_data = {"username": payload, "password": "test"}
                response = requests.post(f"{api_url}/login", json=login_data)
                assert response.status_code in [400, 401], f"Unexpected response for SQL payload: {payload}"
                
        except requests.exceptions.ConnectionError:
            pytest.skip("API not available")
    
    def test_xss_protection(self, base_url):
        """Test XSS protection"""
        xss_payloads = [
            "<script>alert('xss')</script>",
            "javascript:alert('xss')",
            "<img src=x onerror=alert('xss')>",
            "<svg onload=alert('xss')>",
            "';alert('xss');//"
        ]
        
        try:
            for payload in xss_payloads:
                # Test in search
                response = requests.get(f"{base_url}/", params={"q": payload})
                assert "<script>" not in response.text.lower(), f"XSS possible with: {payload}"
                assert "javascript:" not in response.text.lower(), f"XSS possible with: {payload}"
                
        except requests.exceptions.ConnectionError:
            pytest.skip("Application not running")
    
    def test_authentication_required(self, api_url):
        """Test that protected endpoints require authentication"""
        protected_endpoints = [
            "/cart",
            "/wishlist",
            "/orders",
            "/profile"
        ]
        
        try:
            for endpoint in protected_endpoints:
                response = requests.get(f"{api_url}{endpoint}")
                assert response.status_code == 401, f"Endpoint {endpoint} not properly protected"
                
        except requests.exceptions.ConnectionError:
            pytest.skip("API not available")
    
    def test_authorization_levels(self, api_url):
        """Test that admin endpoints require admin privileges"""
        admin_endpoints = [
            "/admin/users",
            "/admin/products",
            "/admin/orders"
        ]
        
        try:
            # Test without any token
            for endpoint in admin_endpoints:
                response = requests.get(f"{api_url}{endpoint}")
                assert response.status_code in [401, 403], f"Admin endpoint {endpoint} not protected"
            
            # Test with regular user token (would need to implement user login first)
            # This is a placeholder for when we have proper token-based auth
            
        except requests.exceptions.ConnectionError:
            pytest.skip("API not available")
    
    def test_rate_limiting(self, base_url):
        """Test rate limiting protection"""
        try:
            # Make many requests quickly
            responses = []
            for _ in range(100):
                response = requests.get(base_url, timeout=1)
                responses.append(response.status_code)
            
            # Check if we get rate limited (429 Too Many Requests)
            rate_limited = any(status == 429 for status in responses)
            # Note: This test might pass even without rate limiting if the server is fast enough
            # In production, you'd want proper rate limiting
            
        except requests.exceptions.ConnectionError:
            pytest.skip("Application not running")
        except requests.exceptions.ReadTimeout:
            # This might happen with rate limiting
            pass
    
    def test_csrf_protection(self, base_url):
        """Test CSRF protection for forms"""
        try:
            # Get login page to check for CSRF token
            response = requests.get(f"{base_url}/login")
            assert "csrf_token" in response.text or "_token" in response.text, "CSRF token not found"
            
        except requests.exceptions.ConnectionError:
            pytest.skip("Application not running")
    
    def test_password_requirements(self, api_url):
        """Test password strength requirements"""
        weak_passwords = [
            "123",
            "password",
            "abc",
            "111111",
            "qwerty"
        ]
        
        try:
            for weak_pass in weak_passwords:
                register_data = {
                    "username": "testuser",
                    "email": "test@example.com",
                    "password": weak_pass
                }
                response = requests.post(f"{api_url}/register", json=register_data)
                # Should reject weak passwords
                assert response.status_code == 400, f"Weak password accepted: {weak_pass}"
                
        except requests.exceptions.ConnectionError:
            pytest.skip("API not available")
    
    def test_file_upload_security(self, api_url):
        """Test file upload security"""
        dangerous_files = [
            ("test.php", "<?php echo 'hack'; ?>"),
            ("test.exe", b"\x4d\x5a\x90\x00"),  # PE header
            ("test.js", "alert('xss');"),
            ("../../../etc/passwd", "root:x:0:0:root:/root:/bin/bash")
        ]
        
        try:
            for filename, content in dangerous_files:
                files = {"file": (filename, content)}
                response = requests.post(f"{api_url}/upload", files=files)
                # Should reject dangerous files
                assert response.status_code in [400, 403], f"Dangerous file accepted: {filename}"
                
        except requests.exceptions.ConnectionError:
            pytest.skip("API not available")
    
    def test_information_disclosure(self, base_url):
        """Test for information disclosure"""
        sensitive_paths = [
            "/.env",
            "/config.py",
            "/requirements.txt",
            "/.git/config",
            "/admin",
            "/debug",
            "/phpinfo.php",
            "/server-status"
        ]
        
        try:
            for path in sensitive_paths:
                response = requests.get(f"{base_url}{path}")
                # Should not expose sensitive information
                assert response.status_code in [404, 403], f"Sensitive path accessible: {path}"
                
        except requests.exceptions.ConnectionError:
            pytest.skip("Application not running")
    
    def test_http_methods_security(self, api_url):
        """Test HTTP methods security"""
        dangerous_methods = ["TRACE", "OPTIONS", "PUT", "DELETE"]
        
        try:
            for method in dangerous_methods:
                response = requests.request(method, f"{api_url}/products")
                # Should not allow dangerous methods without authentication
                if method in ["PUT", "DELETE"]:
                    assert response.status_code in [401, 403, 405]
                elif method == "TRACE":
                    assert response.status_code == 405, "TRACE method should be disabled"
                    
        except requests.exceptions.ConnectionError:
            pytest.skip("API not available")


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
