#!/bin/bash

# Comprehensive Test Runner for E-commerce Application

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

# Test configuration
TEST_TYPES=${1:-all}
COVERAGE=${2:-true}
VERBOSE=${3:-true}

print_status "🧪 Starting E-commerce Application Test Suite"
print_status "Test types: $TEST_TYPES"
print_status "Coverage: $COVERAGE"
print_status "Verbose: $VERBOSE"

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    print_warning "Virtual environment not found. Creating one..."
    python3 -m venv venv
fi

# Activate virtual environment
source venv/bin/activate

# Install test dependencies
print_status "📦 Installing test dependencies..."
pip install -r requirements-test.txt

# Set pytest options
PYTEST_OPTS=""
if [ "$VERBOSE" = "true" ]; then
    PYTEST_OPTS="$PYTEST_OPTS -v"
fi

if [ "$COVERAGE" = "true" ]; then
    PYTEST_OPTS="$PYTEST_OPTS --cov=../backend/app --cov-report=term-missing --cov-report=html:htmlcov --cov-report=xml:coverage.xml"
fi

# Function to run specific test type
run_test_type() {
    local test_type=$1
    local test_file=$2
    
    print_test "Running $test_type tests..."
    
    if [ -f "$test_file" ]; then
        pytest $test_file $PYTEST_OPTS --tb=short
        if [ $? -eq 0 ]; then
            print_status "✅ $test_type tests passed"
        else
            print_error "❌ $test_type tests failed"
            return 1
        fi
    else
        print_warning "⚠️ $test_file not found, skipping $test_type tests"
    fi
}

# Function to check application health
check_app_health() {
    print_status "🏥 Checking application health..."
    
    # Try to connect to the application
    if curl -f http://localhost:5000/health &> /dev/null; then
        print_status "✅ Application is running and healthy"
        return 0
    else
        print_warning "⚠️ Application is not running or not healthy"
        print_warning "Some tests may be skipped"
        return 1
    fi
}

# Run tests based on type
run_tests() {
    local failed_tests=0
    
    case $TEST_TYPES in
        "unit")
            run_test_type "Unit - Authentication" "test_auth.py" || ((failed_tests++))
            run_test_type "Unit - Products" "test_products.py" || ((failed_tests++))
            run_test_type "Unit - Cart" "test_cart.py" || ((failed_tests++))
            run_test_type "Unit - Admin" "test_admin.py" || ((failed_tests++))
            run_test_type "Unit - API" "test_api.py" || ((failed_tests++))
            ;;
        "integration")
            check_app_health
            run_test_type "Integration" "test_integration.py" || ((failed_tests++))
            ;;
        "e2e")
            check_app_health
            print_warning "E2E tests require Chrome/Chromium browser"
            run_test_type "End-to-End" "test_e2e.py" || ((failed_tests++))
            ;;
        "performance")
            check_app_health
            run_test_type "Performance" "test_performance.py" || ((failed_tests++))
            ;;
        "security")
            check_app_health
            run_test_type "Security" "test_security.py" || ((failed_tests++))
            ;;
        "all"|*)
            print_status "🚀 Running all test types..."
            
            # Unit tests (don't require running app)
            print_test "=== UNIT TESTS ==="
            run_test_type "Unit - Authentication" "test_auth.py" || ((failed_tests++))
            run_test_type "Unit - Products" "test_products.py" || ((failed_tests++))
            run_test_type "Unit - Cart" "test_cart.py" || ((failed_tests++))
            run_test_type "Unit - Admin" "test_admin.py" || ((failed_tests++))
            run_test_type "Unit - API" "test_api.py" || ((failed_tests++))
            
            # Check if app is running for integration tests
            if check_app_health; then
                print_test "=== INTEGRATION TESTS ==="
                run_test_type "Integration" "test_integration.py" || ((failed_tests++))
                
                print_test "=== PERFORMANCE TESTS ==="
                run_test_type "Performance" "test_performance.py" || ((failed_tests++))
                
                print_test "=== SECURITY TESTS ==="
                run_test_type "Security" "test_security.py" || ((failed_tests++))
                
                print_test "=== END-TO-END TESTS ==="
                print_warning "E2E tests require Chrome/Chromium browser"
                run_test_type "End-to-End" "test_e2e.py" || ((failed_tests++))
            else
                print_warning "Skipping integration, performance, security, and E2E tests (app not running)"
            fi
            ;;
    esac
    
    return $failed_tests
}

# Generate test report
generate_report() {
    print_status "📊 Generating test report..."
    
    if [ "$COVERAGE" = "true" ] && [ -f "coverage.xml" ]; then
        print_status "Coverage report generated:"
        echo "  - HTML: htmlcov/index.html"
        echo "  - XML: coverage.xml"
        
        # Show coverage summary
        if command -v coverage &> /dev/null; then
            print_status "Coverage Summary:"
            coverage report --show-missing
        fi
    fi
    
    # JUnit XML for CI/CD
    if [ -f "test-results.xml" ]; then
        print_status "JUnit XML report: test-results.xml"
    fi
}

# Main execution
main() {
    local start_time=$(date +%s)
    
    run_tests
    local test_result=$?
    
    generate_report
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    print_status "⏱️ Test execution completed in ${duration}s"
    
    if [ $test_result -eq 0 ]; then
        print_status "🎉 All tests passed successfully!"
        exit 0
    else
        print_error "💥 $test_result test suite(s) failed"
        exit 1
    fi
}

# Show usage if help requested
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: $0 [test_type] [coverage] [verbose]"
    echo ""
    echo "Test types:"
    echo "  unit        - Run unit tests only"
    echo "  integration - Run integration tests only"
    echo "  e2e         - Run end-to-end tests only"
    echo "  performance - Run performance tests only"
    echo "  security    - Run security tests only"
    echo "  all         - Run all tests (default)"
    echo ""
    echo "Coverage: true/false (default: true)"
    echo "Verbose: true/false (default: true)"
    echo ""
    echo "Examples:"
    echo "  $0 unit"
    echo "  $0 all false false"
    echo "  $0 integration true true"
    exit 0
fi

# Run main function
main
