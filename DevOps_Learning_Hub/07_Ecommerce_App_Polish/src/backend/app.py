from flask import Flask, jsonify, request
from flask_cors import CORS
import os
import redis
import logging
from logging.handlers import RotatingFileHandler
import json
import time
import prometheus_client
from prometheus_client import Counter, Histogram, Info

# Initialize Prometheus metrics
REQUEST_COUNT = Counter(
    'app_request_count', 'Application Request Count',
    ['app_name', 'method', 'endpoint', 'http_status']
)
REQUEST_LATENCY = Histogram(
    'app_request_latency_seconds', 'Application Request Latency',
    ['app_name', 'method', 'endpoint']
)
APP_INFO = Info('app_info', 'Application Information')
APP_INFO.info({
    'app': 'ecommerce-api',
    'version': '1.0.0',
    'author': 'DevOps Learning Hub'
})

# Set up logging
if not os.path.exists('logs'):
    os.makedirs('logs')

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        RotatingFileHandler('logs/app.log', maxBytes=10000000, backupCount=10),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Initialize Flask app
app = Flask(__name__)
CORS(app)

# Initialize Redis connection
try:
    redis_host = os.environ.get('REDIS_HOST', 'localhost')
    redis_port = int(os.environ.get('REDIS_PORT', 6379))
    redis_client = redis.Redis(host=redis_host, port=redis_port, db=0)
    redis_client.ping()  # Test connection
    logger.info(f"Connected to Redis at {redis_host}:{redis_port}")
except Exception as e:
    logger.error(f"Failed to connect to Redis: {str(e)}")
    redis_client = None

# Metrics endpoint
@app.route('/metrics')
def metrics():
    return prometheus_client.generate_latest()

# Middleware for tracking request metrics
@app.before_request
def before_request():
    request.start_time = time.time()

@app.after_request
def after_request(response):
    request_latency = time.time() - request.start_time
    REQUEST_LATENCY.labels('ecommerce-api', request.method, request.path).observe(request_latency)
    REQUEST_COUNT.labels('ecommerce-api', request.method, request.path, response.status_code).inc()
    return response

# Sample product data
PRODUCTS = [
    {"id": 1, "name": "Smartphone", "price": 699.99, "category": "Electronics"},
    {"id": 2, "name": "Laptop", "price": 1299.99, "category": "Electronics"},
    {"id": 3, "name": "Headphones", "price": 199.99, "category": "Electronics"},
    {"id": 4, "name": "T-shirt", "price": 24.99, "category": "Clothing"},
    {"id": 5, "name": "Jeans", "price": 49.99, "category": "Clothing"}
]

# Cache implementation
def get_cached_data(key):
    if redis_client:
        cached = redis_client.get(key)
        if cached:
            logger.info(f"Cache hit for {key}")
            return json.loads(cached)
    return None

def set_cached_data(key, data, expires=3600):
    if redis_client:
        redis_client.setex(key, expires, json.dumps(data))
        logger.info(f"Cache set for {key}")

# API Routes
@app.route('/health', methods=['GET'])
def health_check():
    health = {
        "status": "up",
        "timestamp": time.time(),
        "redis": "connected" if redis_client else "disconnected"
    }
    return jsonify(health)

@app.route('/api/products', methods=['GET'])
def get_products():
    cache_key = "all_products"
    cached_products = get_cached_data(cache_key)
    
    if cached_products:
        return jsonify(cached_products)
    
    logger.info("Retrieving all products")
    set_cached_data(cache_key, PRODUCTS)
    return jsonify(PRODUCTS)

@app.route('/api/products/<int:product_id>', methods=['GET'])
def get_product(product_id):
    cache_key = f"product_{product_id}"
    cached_product = get_cached_data(cache_key)
    
    if cached_product:
        return jsonify(cached_product)
    
    logger.info(f"Retrieving product with ID: {product_id}")
    product = next((p for p in PRODUCTS if p["id"] == product_id), None)
    
    if product:
        set_cached_data(cache_key, product)
        return jsonify(product)
    else:
        logger.warning(f"Product with ID {product_id} not found")
        return jsonify({"error": "Product not found"}), 404

@app.route('/api/products', methods=['POST'])
def create_product():
    if not request.json:
        return jsonify({"error": "Invalid request"}), 400
    
    new_product = {
        "id": len(PRODUCTS) + 1,
        "name": request.json.get("name"),
        "price": request.json.get("price"),
        "category": request.json.get("category")
    }
    
    PRODUCTS.append(new_product)
    logger.info(f"Created new product: {new_product}")
    
    # Invalidate cache
    if redis_client:
        redis_client.delete("all_products")
        logger.info("Invalidated product cache")
    
    return jsonify(new_product), 201

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port)
