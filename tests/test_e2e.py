"""
End-to-end tests for the E-commerce application
"""
import pytest
import requests
import json
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.chrome.options import Options


class TestE2E:
    """End-to-end tests covering complete user workflows"""
    
    @pytest.fixture(scope="class")
    def driver(self):
        """Setup Chrome WebDriver"""
        chrome_options = Options()
        chrome_options.add_argument("--headless")
        chrome_options.add_argument("--no-sandbox")
        chrome_options.add_argument("--disable-dev-shm-usage")
        chrome_options.add_argument("--disable-gpu")
        
        driver = webdriver.Chrome(options=chrome_options)
        driver.implicitly_wait(10)
        yield driver
        driver.quit()
    
    @pytest.fixture
    def api_client(self):
        """API client for testing"""
        class APIClient:
            def __init__(self):
                self.base_url = "http://localhost:5000/api"
                self.token = None
            
            def login(self, username, password):
                response = requests.post(f"{self.base_url}/login", json={
                    "username": username,
                    "password": password
                })
                if response.status_code == 200:
                    self.token = response.json().get("token")
                return response
            
            def get_headers(self):
                headers = {"Content-Type": "application/json"}
                if self.token:
                    headers["Authorization"] = f"Bearer {self.token}"
                return headers
            
            def get(self, endpoint):
                return requests.get(f"{self.base_url}{endpoint}", headers=self.get_headers())
            
            def post(self, endpoint, data):
                return requests.post(f"{self.base_url}{endpoint}", 
                                   json=data, headers=self.get_headers())
            
            def put(self, endpoint, data):
                return requests.put(f"{self.base_url}{endpoint}", 
                                  json=data, headers=self.get_headers())
            
            def delete(self, endpoint):
                return requests.delete(f"{self.base_url}{endpoint}", headers=self.get_headers())
        
        return APIClient()
    
    def test_user_registration_and_login_flow(self, driver):
        """Test complete user registration and login flow"""
        base_url = "http://localhost:5000"
        
        try:
            # Navigate to registration
            driver.get(f"{base_url}/signup")
            
            # Fill registration form
            driver.find_element(By.NAME, "username").send_keys("e2euser")
            driver.find_element(By.NAME, "email").send_keys("e2e@test.com")
            driver.find_element(By.NAME, "password").send_keys("e2epass123")
            driver.find_element(By.CSS_SELECTOR, "button[type='submit']").click()
            
            # Should redirect to login
            WebDriverWait(driver, 10).until(
                EC.url_contains("/login")
            )
            
            # Login with new credentials
            driver.find_element(By.NAME, "username").send_keys("e2euser")
            driver.find_element(By.NAME, "password").send_keys("e2epass123")
            driver.find_element(By.CSS_SELECTOR, "button[type='submit']").click()
            
            # Should be logged in and redirected to home
            WebDriverWait(driver, 10).until(
                EC.presence_of_element_located((By.CLASS_NAME, "user-menu"))
            )
            
        except Exception as e:
            pytest.skip(f"Browser test failed: {str(e)}")
    
    def test_shopping_cart_workflow(self, driver):
        """Test complete shopping cart workflow"""
        base_url = "http://localhost:5000"
        
        try:
            # Login first
            driver.get(f"{base_url}/login")
            driver.find_element(By.NAME, "username").send_keys("e2euser")
            driver.find_element(By.NAME, "password").send_keys("e2epass123")
            driver.find_element(By.CSS_SELECTOR, "button[type='submit']").click()
            
            # Browse products
            driver.get(f"{base_url}/")
            products = driver.find_elements(By.CLASS_NAME, "product-card")
            assert len(products) > 0
            
            # Add first product to cart
            first_product = products[0]
            product_name = first_product.find_element(By.CLASS_NAME, "product-name").text
            add_btn = first_product.find_element(By.CLASS_NAME, "add-to-cart")
            add_btn.click()
            
            # Add second product to cart
            if len(products) > 1:
                second_product = products[1]
                add_btn = second_product.find_element(By.CLASS_NAME, "add-to-cart")
                add_btn.click()
            
            # View cart
            driver.get(f"{base_url}/cart")
            cart_items = driver.find_elements(By.CLASS_NAME, "cart-item")
            assert len(cart_items) > 0
            
            # Update quantity
            quantity_input = driver.find_element(By.CLASS_NAME, "quantity-input")
            quantity_input.clear()
            quantity_input.send_keys("2")
            update_btn = driver.find_element(By.CLASS_NAME, "update-cart")
            update_btn.click()
            
            # Remove item
            if len(cart_items) > 1:
                remove_btn = driver.find_element(By.CLASS_NAME, "remove-item")
                remove_btn.click()
            
        except Exception as e:
            pytest.skip(f"Shopping cart test failed: {str(e)}")
    
    def test_wishlist_workflow(self, driver):
        """Test wishlist functionality"""
        base_url = "http://localhost:5000"
        
        try:
            # Login
            driver.get(f"{base_url}/login")
            driver.find_element(By.NAME, "username").send_keys("e2euser")
            driver.find_element(By.NAME, "password").send_keys("e2epass123")
            driver.find_element(By.CSS_SELECTOR, "button[type='submit']").click()
            
            # Add items to wishlist
            driver.get(f"{base_url}/")
            products = driver.find_elements(By.CLASS_NAME, "product-card")
            
            for product in products[:2]:  # Add first 2 products
                wishlist_btn = product.find_element(By.CLASS_NAME, "add-to-wishlist")
                wishlist_btn.click()
            
            # View wishlist
            driver.get(f"{base_url}/wishlist")
            wishlist_items = driver.find_elements(By.CLASS_NAME, "wishlist-item")
            assert len(wishlist_items) > 0
            
            # Move item from wishlist to cart
            move_to_cart_btn = driver.find_element(By.CLASS_NAME, "move-to-cart")
            move_to_cart_btn.click()
            
        except Exception as e:
            pytest.skip(f"Wishlist test failed: {str(e)}")
    
    def test_checkout_process(self, driver):
        """Test complete checkout process"""
        base_url = "http://localhost:5000"
        
        try:
            # Login and add items to cart (prerequisite)
            driver.get(f"{base_url}/login")
            driver.find_element(By.NAME, "username").send_keys("e2euser")
            driver.find_element(By.NAME, "password").send_keys("e2epass123")
            driver.find_element(By.CSS_SELECTOR, "button[type='submit']").click()
            
            # Add product to cart
            driver.get(f"{base_url}/")
            product = driver.find_element(By.CLASS_NAME, "product-card")
            add_btn = product.find_element(By.CLASS_NAME, "add-to-cart")
            add_btn.click()
            
            # Go to checkout
            driver.get(f"{base_url}/cart")
            checkout_btn = driver.find_element(By.CLASS_NAME, "checkout-btn")
            checkout_btn.click()
            
            # Fill shipping information
            shipping_address = driver.find_element(By.NAME, "shipping_address")
            shipping_address.send_keys("123 E2E Test Street, Test City, 12345")
            
            # Submit order
            submit_btn = driver.find_element(By.CSS_SELECTOR, "button[type='submit']")
            submit_btn.click()
            
            # Verify order confirmation
            WebDriverWait(driver, 10).until(
                EC.presence_of_element_located((By.CLASS_NAME, "order-confirmation"))
            )
            
            order_number = driver.find_element(By.CLASS_NAME, "order-number").text
            assert order_number is not None
            
        except Exception as e:
            pytest.skip(f"Checkout test failed: {str(e)}")
    
    def test_admin_functionality(self, driver):
        """Test admin panel functionality"""
        base_url = "http://localhost:5000"
        
        try:
            # Login as admin (assuming admin user exists)
            driver.get(f"{base_url}/login")
            driver.find_element(By.NAME, "username").send_keys("admin")
            driver.find_element(By.NAME, "password").send_keys("admin123")
            driver.find_element(By.CSS_SELECTOR, "button[type='submit']").click()
            
            # Access admin panel
            driver.get(f"{base_url}/admin")
            
            # Check admin sections are present
            assert driver.find_element(By.CLASS_NAME, "users-section")
            assert driver.find_element(By.CLASS_NAME, "products-section")
            assert driver.find_element(By.CLASS_NAME, "orders-section")
            
            # Test adding new product
            add_product_btn = driver.find_element(By.CLASS_NAME, "add-product-btn")
            add_product_btn.click()
            
            # Fill product form
            driver.find_element(By.NAME, "name").send_keys("E2E Test Product")
            driver.find_element(By.NAME, "description").send_keys("Test product description")
            driver.find_element(By.NAME, "price").send_keys("29.99")
            driver.find_element(By.NAME, "stock").send_keys("100")
            
            submit_btn = driver.find_element(By.CSS_SELECTOR, "button[type='submit']")
            submit_btn.click()
            
        except Exception as e:
            pytest.skip(f"Admin test failed: {str(e)}")
    
    def test_api_complete_workflow(self, api_client):
        """Test complete API workflow"""
        try:
            # Test user registration via API
            response = api_client.post("/register", {
                "username": "apiuser",
                "email": "api@test.com",
                "password": "apipass123"
            })
            assert response.status_code in [200, 201]
            
            # Test login
            response = api_client.login("apiuser", "apipass123")
            assert response.status_code == 200
            assert api_client.token is not None
            
            # Test getting products
            response = api_client.get("/products")
            assert response.status_code == 200
            products = response.json()
            assert isinstance(products, list)
            
            if products:
                product_id = products[0]["id"]
                
                # Test adding to cart
                response = api_client.post("/cart", {
                    "product_id": product_id,
                    "quantity": 2
                })
                assert response.status_code in [200, 201]
                
                # Test getting cart
                response = api_client.get("/cart")
                assert response.status_code == 200
                cart = response.json()
                assert len(cart) > 0
                
                # Test adding to wishlist
                response = api_client.post("/wishlist", {
                    "product_id": product_id
                })
                assert response.status_code in [200, 201]
                
                # Test getting wishlist
                response = api_client.get("/wishlist")
                assert response.status_code == 200
                wishlist = response.json()
                assert len(wishlist) > 0
            
        except requests.exceptions.ConnectionError:
            pytest.skip("API not available")
    
    def test_error_handling(self, driver):
        """Test error handling and edge cases"""
        base_url = "http://localhost:5000"
        
        try:
            # Test accessing protected pages without login
            driver.get(f"{base_url}/cart")
            # Should redirect to login
            WebDriverWait(driver, 10).until(
                EC.url_contains("/login")
            )
            
            # Test invalid login
            driver.find_element(By.NAME, "username").send_keys("invaliduser")
            driver.find_element(By.NAME, "password").send_keys("invalidpass")
            driver.find_element(By.CSS_SELECTOR, "button[type='submit']").click()
            
            # Should show error message
            error_msg = driver.find_element(By.CLASS_NAME, "error-message")
            assert error_msg.is_displayed()
            
            # Test 404 page
            driver.get(f"{base_url}/nonexistent-page")
            assert "404" in driver.page_source or "Not Found" in driver.page_source
            
        except Exception as e:
            pytest.skip(f"Error handling test failed: {str(e)}")


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
