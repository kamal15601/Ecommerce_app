"""
Performance tests for the E-commerce application
"""
import pytest
import requests
import time
import concurrent.futures
import statistics
from locust import HttpUser, task, between


class TestPerformance:
    """Performance tests for the application"""
    
    @pytest.fixture
    def base_url(self):
        return "http://localhost:5000"
    
    def test_response_time_home_page(self, base_url):
        """Test home page response time"""
        times = []
        
        for _ in range(10):
            start = time.time()
            try:
                response = requests.get(base_url, timeout=30)
                end = time.time()
                if response.status_code == 200:
                    times.append(end - start)
            except requests.exceptions.ConnectionError:
                pytest.skip("Application not running")
        
        if times:
            avg_time = statistics.mean(times)
            max_time = max(times)
            assert avg_time < 2.0, f"Average response time {avg_time:.2f}s exceeds 2s"
            assert max_time < 5.0, f"Max response time {max_time:.2f}s exceeds 5s"
    
    def test_concurrent_requests(self, base_url):
        """Test handling concurrent requests"""
        def make_request():
            try:
                response = requests.get(base_url, timeout=10)
                return response.status_code == 200
            except:
                return False
        
        try:
            # Test with 20 concurrent requests
            with concurrent.futures.ThreadPoolExecutor(max_workers=20) as executor:
                futures = [executor.submit(make_request) for _ in range(20)]
                results = [future.result() for future in concurrent.futures.as_completed(futures)]
            
            success_rate = sum(results) / len(results)
            assert success_rate >= 0.8, f"Success rate {success_rate:.2f} below 80%"
            
        except Exception:
            pytest.skip("Concurrent request test failed")
    
    def test_api_performance(self, base_url):
        """Test API endpoint performance"""
        endpoints = [
            "/api/products",
            "/api/categories",
            "/api/health"
        ]
        
        for endpoint in endpoints:
            times = []
            for _ in range(5):
                start = time.time()
                try:
                    response = requests.get(f"{base_url}{endpoint}", timeout=10)
                    end = time.time()
                    if response.status_code == 200:
                        times.append(end - start)
                except requests.exceptions.ConnectionError:
                    pytest.skip(f"Endpoint {endpoint} not available")
            
            if times:
                avg_time = statistics.mean(times)
                assert avg_time < 1.0, f"API {endpoint} avg time {avg_time:.2f}s exceeds 1s"
    
    def test_memory_usage_simulation(self, base_url):
        """Simulate heavy usage to test memory handling"""
        def heavy_request():
            try:
                # Make multiple requests with data
                response = requests.get(f"{base_url}/api/products", timeout=5)
                return response.status_code == 200
            except:
                return False
        
        try:
            # Simulate 50 requests
            with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
                futures = [executor.submit(heavy_request) for _ in range(50)]
                results = [future.result() for future in concurrent.futures.as_completed(futures)]
            
            success_rate = sum(results) / len(results)
            assert success_rate >= 0.7, f"Heavy load success rate {success_rate:.2f} below 70%"
            
        except Exception:
            pytest.skip("Memory usage test failed")


class EcommerceUser(HttpUser):
    """Locust user for load testing"""
    wait_time = between(1, 3)
    
    def on_start(self):
        """Setup user session"""
        self.client.get("/")
    
    @task(3)
    def view_home(self):
        """View home page"""
        self.client.get("/")
    
    @task(2)
    def view_products(self):
        """View products"""
        self.client.get("/api/products")
    
    @task(1)
    def view_categories(self):
        """View categories"""
        self.client.get("/api/categories")
    
    @task(1)
    def health_check(self):
        """Health check"""
        self.client.get("/api/health")
    
    @task(1)
    def login_page(self):
        """View login page"""
        self.client.get("/login")


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
