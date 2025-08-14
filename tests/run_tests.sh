# Run all tests with coverage
#!/bin/bash

echo "🧪 Running E-Commerce App Tests..."
echo "=================================="

# Install test dependencies
pip install -r tests/requirements-test.txt

# Run tests with coverage
cd backend
python -m pytest ../tests/ -v --cov=app --cov-report=html --cov-report=term-missing

echo ""
echo "📊 Test Results:"
echo "- Coverage report: htmlcov/index.html"
echo "- Test files: tests/"

# Run specific test categories
echo ""
echo "🔍 Running test categories:"
echo "1. Authentication tests..."
python -m pytest ../tests/test_auth.py -v

echo "2. Product tests..."
python -m pytest ../tests/test_products.py -v

echo "3. Cart/Wishlist tests..."
python -m pytest ../tests/test_cart.py -v

echo "4. Admin tests..."
python -m pytest ../tests/test_admin.py -v

echo "5. API tests..."
python -m pytest ../tests/test_api.py -v

echo ""
echo "✅ All tests completed!"
