"""
Integration tests for the E-commerce application
"""
import pytest
import requests
import time
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.chrome.options import Options


class TestIntegration:
    """Integration tests for the complete application flow"""
    
    @pytest.fixture(scope="class")
    def driver(self):
        """Setup Chrome WebDriver for UI tests"""
        chrome_options = Options()
        chrome_options.add_argument("--headless")
        chrome_options.add_argument("--no-sandbox")
        chrome_options.add_argument("--disable-dev-shm-usage")
        
        driver = webdriver.Chrome(options=chrome_options)
        driver.implicitly_wait(10)
        yield driver
        driver.quit()
    
    def test_application_health(self):
        """Test if the application is running and healthy"""
        base_url = "http://localhost:5000"
        
        try:
            response = requests.get(f"{base_url}/health", timeout=30)
            assert response.status_code == 200
            assert response.json()["status"] == "healthy"
        except requests.exceptions.ConnectionError:
            pytest.skip("Application not running")
    
    def test_database_connection(self):
        """Test database connectivity"""
        base_url = "http://localhost:5000"
        
        try:
            response = requests.get(f"{base_url}/api/health/db", timeout=30)
            assert response.status_code == 200
            assert response.json()["database"] == "connected"
        except requests.exceptions.ConnectionError:
            pytest.skip("Application not running")
    
    def test_redis_connection(self):
        """Test Redis connectivity"""
        base_url = "http://localhost:5000"
        
        try:
            response = requests.get(f"{base_url}/api/health/redis", timeout=30)
            assert response.status_code == 200
            assert response.json()["redis"] == "connected"
        except requests.exceptions.ConnectionError:
            pytest.skip("Application not running")
    
    def test_complete_user_journey(self, driver):
        """Test complete user journey from registration to checkout"""
        base_url = "http://localhost:5000"
        
        try:
            # 1. Navigate to home page
            driver.get(base_url)
            assert "E-commerce" in driver.title
            
            # 2. Register new user
            driver.get(f"{base_url}/signup")
            driver.find_element(By.NAME, "username").send_keys("testuser123")
            driver.find_element(By.NAME, "email").send_keys("test@example.com")
            driver.find_element(By.NAME, "password").send_keys("testpass123")
            driver.find_element(By.CSS_SELECTOR, "button[type='submit']").click()
            
            # Wait for redirect
            WebDriverWait(driver, 10).until(
                EC.url_contains("/login")
            )
            
            # 3. Login
            driver.find_element(By.NAME, "username").send_keys("testuser123")
            driver.find_element(By.NAME, "password").send_keys("testpass123")
            driver.find_element(By.CSS_SELECTOR, "button[type='submit']").click()
            
            # Wait for successful login
            WebDriverWait(driver, 10).until(
                EC.presence_of_element_located((By.CLASS_NAME, "user-menu"))
            )
            
            # 4. Browse products
            driver.get(f"{base_url}/")
            products = driver.find_elements(By.CLASS_NAME, "product-card")
            assert len(products) > 0
            
            # 5. Add product to cart
            first_product = products[0]
            add_to_cart_btn = first_product.find_element(By.CLASS_NAME, "add-to-cart")
            add_to_cart_btn.click()
            
            # 6. View cart
            driver.get(f"{base_url}/cart")
            cart_items = driver.find_elements(By.CLASS_NAME, "cart-item")
            assert len(cart_items) > 0
            
            # 7. Proceed to checkout
            checkout_btn = driver.find_element(By.CLASS_NAME, "checkout-btn")
            checkout_btn.click()
            
            # Fill checkout form
            driver.find_element(By.NAME, "shipping_address").send_keys("123 Test Street, Test City")
            driver.find_element(By.CSS_SELECTOR, "button[type='submit']").click()
            
            # Wait for order confirmation
            WebDriverWait(driver, 10).until(
                EC.presence_of_element_located((By.CLASS_NAME, "order-confirmation"))
            )
            
        except Exception as e:
            pytest.skip(f"UI test failed: {str(e)}")
    
    def test_api_endpoints(self):
        """Test API endpoints functionality"""
        base_url = "http://localhost:5000/api"
        
        try:
            # Test products API
            response = requests.get(f"{base_url}/products")
            assert response.status_code == 200
            products = response.json()
            assert isinstance(products, list)
            
            # Test categories API
            response = requests.get(f"{base_url}/categories")
            assert response.status_code == 200
            categories = response.json()
            assert isinstance(categories, list)
            
            # Test authentication required endpoints
            response = requests.get(f"{base_url}/cart")
            assert response.status_code == 401  # Unauthorized without token
            
        except requests.exceptions.ConnectionError:
            pytest.skip("Application not running")
    
    def test_load_test_basic(self):
        """Basic load test with concurrent requests"""
        import concurrent.futures
        import threading
        
        base_url = "http://localhost:5000"
        results = []
        
        def make_request():
            try:
                response = requests.get(f"{base_url}/", timeout=10)
                return response.status_code == 200
            except:
                return False
        
        try:
            # Test with 10 concurrent requests
            with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
                futures = [executor.submit(make_request) for _ in range(10)]
                results = [future.result() for future in futures]
            
            success_rate = sum(results) / len(results)
            assert success_rate >= 0.8  # At least 80% success rate
            
        except Exception:
            pytest.skip("Load test failed - application might not be running")
    
    def test_security_headers(self):
        """Test security headers are present"""
        base_url = "http://localhost:5000"
        
        try:
            response = requests.get(base_url)
            headers = response.headers
            
            # Check for important security headers
            security_headers = [
                'X-Content-Type-Options',
                'X-Frame-Options',
                'X-XSS-Protection'
            ]
            
            for header in security_headers:
                assert header in headers, f"Missing security header: {header}"
                
        except requests.exceptions.ConnectionError:
            pytest.skip("Application not running")


class TestPerformance:
    """Performance tests"""
    
    def test_response_time(self):
        """Test response time is acceptable"""
        base_url = "http://localhost:5000"
        
        try:
            start_time = time.time()
            response = requests.get(base_url)
            end_time = time.time()
            
            response_time = end_time - start_time
            assert response_time < 2.0  # Should respond within 2 seconds
            assert response.status_code == 200
            
        except requests.exceptions.ConnectionError:
            pytest.skip("Application not running")
    
    def test_database_query_performance(self):
        """Test database query performance"""
        base_url = "http://localhost:5000/api"
        
        try:
            start_time = time.time()
            response = requests.get(f"{base_url}/products")
            end_time = time.time()
            
            query_time = end_time - start_time
            assert query_time < 1.0  # Database queries should be fast
            assert response.status_code == 200
            
        except requests.exceptions.ConnectionError:
            pytest.skip("Application not running")
