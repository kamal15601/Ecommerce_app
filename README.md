# 🛒 E-Commerce Web Application

A complete e-commerce web application built with Python Flask, PostgreSQL, and responsive HTML/CSS templates. Features include user authentication, product management, cart, wishlist, checkout, and admin dashboard.

## 🚀 Features

- **User Authentication:** Signup, login, logout with session management
- **Product Catalog:** Browse products with categories, descriptions, and pricing
- **Shopping Cart:** Add/remove items, view cart contents and totals
- **Wishlist:** Save favorite products for later
- **Checkout System:** Order summary and payment form
- **Admin Dashboard:** Manage products, categories, and orders
- **Responsive Design:** Works on desktop and mobile devices
- **RESTful API:** Backend API endpoints for all operations

## 🛠️ Technology Stack

- **Backend:** Python Flask, SQLAlchemy, PostgreSQL
- **Frontend:** HTML5, CSS3, Jinja2 templates
- **Authentication:** Flask sessions, password hashing
- **Database:** PostgreSQL with Flask-Migrate
- **Deployment:** Docker & Kubernetes ready

## 📋 Prerequisites

- **Python 3.11+** installed
- **PostgreSQL** database server

## 🔧 Complete Setup Guide

### Step 1: Install PostgreSQL Database

1. **Download PostgreSQL** from https://www.postgresql.org/download/windows/
2. **Install it** with these settings:
   - Username: `postgres`
   - Password: `yourpassword` (remember this!)
   - Port: `5432`

3. **Open pgAdmin** (comes with PostgreSQL)
4. **Create database and user:**
   - Right-click "Databases" → "Create" → "Database"
   - Database name: `ecommerce`
   - In pgAdmin SQL tool, run:
   ```sql
   CREATE USER admin WITH PASSWORD 'adminpass';
   GRANT ALL PRIVILEGES ON DATABASE ecommerce TO admin;
   GRANT ALL ON SCHEMA public TO admin;
   ```

### Step 2: Clone and Setup Project

```bash
cd "C:\Users\2309301\OneDrive - Cognizant\Desktop\Ecommerce-app"
```

### Step 3: Install Python Dependencies

```bash
pip install -r backend/requirements.txt
```

### Step 4: Verify Setup (Optional but Recommended)

```bash
cd backend
python check_setup.py
```

This will verify that all dependencies are installed correctly.

### Step 5: Set Environment Variables

In Command Prompt/PowerShell:
```bash
set FLASK_APP=backend/app.py
set FLASK_ENV=development
```

### Step 6: Initialize Database Tables

```bash
cd backend
python -c "from app import create_app, db; app=create_app(); app.app_context().push(); db.create_all(); print('Database tables created!')"
```

### Step 7: Add Sample Data (Recommended)

```bash
python add_sample_data.py
```

This creates:
- Sample products (Smartphone, Laptop, T-Shirt, Jeans)
- Sample categories (Electronics, Clothing, Books, Home & Garden)
- Admin user: **Email:** `admin@example.com`, **Password:** `admin123`

### Step 8: Run the Application

```bash
python app.py
```

You should see:
```
* Running on http://127.0.0.1:5000
* Debug mode: on
```

### Step 9: Access Your Webapp

1. **Open browser** and go to: **http://localhost:5000**
2. **Available features:**
   - Browse products on homepage
   - Sign up for new account
   - Login with existing account
   - Admin login: `admin@example.com` / `admin123`
   - View cart, wishlist, checkout
   - Access admin dashboard

## 🎯 Usage

### For Users:
1. **Browse Products:** Visit homepage to see all available products
2. **View Details:** Click any product to see full details and reviews
3. **Create Account:** Sign up with username, email, and password
4. **Add to Cart:** (Feature ready for implementation)
5. **Checkout:** Complete purchase with payment form

### For Admins:
1. **Login:** Use `admin@example.com` / `admin123`
2. **Dashboard:** Access admin panel to view stats
3. **Manage Products:** Add, edit, delete products and categories
4. **View Orders:** Monitor customer orders and status

## 🔍 Project Structure

```
Ecommerce-app/
├── backend/
│   ├── app/
│   │   ├── __init__.py          # Flask app factory
│   │   ├── models.py            # Database models
│   │   ├── routes.py            # API endpoints
│   │   └── views.py             # HTML page routes
│   ├── config/
│   │   ├── development.py       # Dev environment config
│   │   ├── staging.py           # Staging config
│   │   └── production.py        # Production config
│   ├── templates/               # HTML templates
│   │   ├── home.html
│   │   ├── login.html
│   │   ├── signup.html
│   │   ├── product_detail.html
│   │   ├── cart.html
│   │   ├── wishlist.html
│   │   ├── checkout.html
│   │   └── admin.html
│   ├── static/
│   │   └── css/
│   │       └── style.css        # Responsive styling
│   ├── app.py                   # Application entry point
│   ├── add_sample_data.py       # Sample data script
│   ├── requirements.txt         # Python dependencies
│   └── Dockerfile               # Docker configuration
├── db/
│   ├── init.sql                 # Database schema
│   └── Dockerfile               # Database Docker config
├── k8s/                         # Kubernetes manifests
│   ├── dev/
│   ├── staging/
│   └── prod/
├── .env.dev                     # Development environment
├── .env.staging                 # Staging environment
├── .env.prod                    # Production environment
└── README.md                    # This file
```

## 🏗️ Application Services

This application consists of **4 core services**:

### 1. **Backend Service** (Flask Application)
- **Technology:** Python Flask with SQLAlchemy
- **Port:** 5000
- **Purpose:** Main application logic, API endpoints, user authentication
- **Health Check:** `/health` endpoint
- **Features:** User management, product catalog, cart, wishlist, checkout, admin

### 2. **Database Service** (PostgreSQL)
- **Technology:** PostgreSQL 15
- **Port:** 5432
- **Purpose:** Data storage for users, products, orders, cart items
- **Persistence:** Persistent volume for data retention
- **Features:** ACID compliance, backup support, connection pooling

### 3. **Cache Service** (Redis)
- **Technology:** Redis 7
- **Port:** 6379
- **Purpose:** Session storage, caching, temporary data
- **Features:** High-performance key-value storage, pub/sub messaging
- **Security:** Password authentication

### 4. **Reverse Proxy Service** (Nginx)
- **Technology:** Nginx
- **Port:** 80/443
- **Purpose:** Load balancing, SSL termination, static file serving
- **Features:** Rate limiting, GZIP compression, security headers

## 📁 Deployment Organization

This project is organized into **4 deployment approaches**:

### 🖥️ Local Development (`local-run/`)
**Files needed for local development:**
- `requirements-local.txt` - Python dependencies
- `.env.local` - Local environment variables
- `setup-local.sh` - Setup script
- `start-local.sh` - Start application locally
- Database setup scripts

**Usage:** Direct Python execution on your development machine

### 🐳 Docker Deployment (`docker-deploy/`)
**Files needed for Docker containers:**
- `docker-compose.yml` - Main Docker Compose file
- `docker-compose.prod.yml` - Production configuration
- `backend.Dockerfile` - Flask app container
- `nginx.Dockerfile` - Nginx container
- `redis.Dockerfile` - Redis container
- `deploy-docker.sh` - Deployment script
- Environment files (`.env.docker`, `.env.docker.prod`)

**Usage:** Containerized deployment with Docker Compose

### ☸️ Kubernetes Deployment (`kubernetes-deploy/`)
**Files needed for Kubernetes cluster:**
- `helm/` - Complete Helm chart with templates
  - `Chart.yaml` - Helm chart metadata
  - `values.yaml`, `values-dev.yaml`, `values-staging.yaml`, `values-prod.yaml`
  - `templates/` - Kubernetes manifest templates
- `manifests/` - Raw Kubernetes YAML files
- `deploy-helm.sh` - Helm deployment script
- `deploy-k8s.sh` - kubectl deployment script

**Usage:** Production-ready Kubernetes deployment with Helm

### ☁️ AWS Deployment (`aws-deploy/`)
**Files needed for AWS cloud deployment:**
- `elastic-beanstalk/` - AWS Elastic Beanstalk deployment
  - Application versions and configuration files
  - Environment-specific settings
- `eks/` - Amazon Elastic Kubernetes Service (EKS)
  - Kubernetes cluster configuration
  - Helm values for AWS environment
- `ecs-fargate/` - Amazon ECS with Fargate
  - Task definitions and service configurations
  - Infrastructure as Code templates
- `cloudformation/` - AWS CloudFormation templates
  - VPC and networking setup
  - Infrastructure provisioning
- `scripts/` - AWS utility scripts
  - ECR repository creation
  - Docker image build and push
  - AWS CLI setup automation
- `monitoring/` - AWS monitoring setup
  - CloudWatch configurations
  - Application performance monitoring

**Usage:** Production-ready AWS cloud deployment with multiple service options

### 🔄 CI/CD Pipeline (`cicd/`)
**Files for Jenkins automation:**
- `Jenkinsfile` - Complete CI/CD pipeline
- Build, test, security scan, deploy stages
- Multi-environment support (dev/staging/prod)
- Quality gates and approvals

## 🐛 Troubleshooting

### Common Issues:

1. **Database Connection Error:**
   ```
   could not translate host name "db" to address
   ```
   **Solution:** Ensure PostgreSQL is running and database `ecommerce` exists

2. **Import Errors:**
   ```
   ModuleNotFoundError: No module named 'flask'
   ```
   **Solution:** Run `pip install -r backend/requirements.txt`

3. **Port 5000 Busy:**
   ```
   OSError: [Errno 98] Address already in use
   ```
   **Solution:** Change port in `app.py`: `app.run(host="0.0.0.0", port=5001)`

4. **Permission Denied (Database):**
   **Solution:** Grant proper permissions to user `admin` in PostgreSQL

### Environment Variables:

Create `.env` file in backend/ folder:
```
DATABASE_URL=postgresql://admin:adminpass@localhost:5432/ecommerce
SECRET_KEY=your-secret-key-here
FLASK_ENV=development
```

## 🚀 Deployment

### Local Development:
```bash
cd backend
python app.py
```

### Docker Deployment:
```bash
docker build -t ecommerce-app ./backend
docker run -p 5000:5000 ecommerce-app
```

### Kubernetes Deployment:
```bash
kubectl apply -f k8s/dev/
```

### AWS Cloud Deployment:

This application supports **multiple AWS deployment strategies**:

#### 🚀 Quick Start - Elastic Beanstalk (Recommended for beginners)
```bash
cd aws-deploy/elastic-beanstalk
./deploy-eb.sh
```

#### ☁️ Production - Amazon EKS (Kubernetes on AWS)
```bash
cd aws-deploy/eks
./deploy-eks.sh
```

#### 🐳 Scalable - Amazon ECS with Fargate
```bash
cd aws-deploy/ecs-fargate
./deploy-ecs.sh
```

#### 📋 Detailed AWS Instructions:

**See [`aws_run_steps.md`](aws_run_steps.md)** for complete step-by-step instructions including:
- Prerequisites and AWS CLI setup
- Environment configuration
- Database setup (Amazon RDS)
- Monitoring and logging (CloudWatch)
- Security configuration
- Cost optimization
- Troubleshooting guide

**AWS Deployment Options:**

| Method | Best For | Complexity | Scaling | Cost |
|--------|----------|------------|---------|------|
| **Elastic Beanstalk** | Quick deployments, beginners | Low | Automatic | $$ |
| **EKS** | Production, microservices | High | Manual/Auto | $$$ |
| **ECS Fargate** | Containerized apps | Medium | Automatic | $$$ |

**Quick AWS Setup:**
```bash
# 1. Setup AWS CLI and dependencies
./aws-deploy/scripts/setup-aws-cli.sh

# 2. Create ECR repository (for container deployments)
./aws-deploy/scripts/create-ecr-repo.sh

# 3. Build and push Docker image
./aws-deploy/scripts/build-and-push.sh

# 4. Deploy using your preferred method
cd aws-deploy/[method]
./deploy-[method].sh
```

**AWS Services Used:**
- **EC2** - Virtual servers
- **RDS** - Managed PostgreSQL database
- **ElastiCache** - Redis caching
- **ALB** - Application Load Balancer
- **EKS/ECS** - Container orchestration
- **CloudWatch** - Monitoring and logging
- **IAM** - Security and permissions
- **VPC** - Networking

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/new-feature`)
3. Commit changes (`git commit -am 'Add new feature'`)
4. Push to branch (`git push origin feature/new-feature`)
5. Create Pull Request

## 📝 License

This project is open source and available under the [MIT License](LICENSE).

## 📞 Support

If you encounter any issues or need help:
1. Check the troubleshooting section above
2. Ensure all prerequisites are installed
3. Verify database connection and permissions
4. Check that all Python dependencies are installed

---

**Test Credentials:**
- **Admin:** `admin@example.com` / `admin123`
- **Or create your own account** via the signup page

Enjoy your e-commerce webapp! 🎉

## 🧪 Testing

This application includes comprehensive testing with **6 types of tests**:

### Test Types:

1. **Unit Tests** (`tests/test_*.py`)
   - Authentication testing (`test_auth.py`)
   - Product management (`test_products.py`)
   - Cart functionality (`test_cart.py`)
   - Admin operations (`test_admin.py`)
   - API endpoints (`test_api.py`)

2. **Integration Tests** (`tests/test_integration.py`)
   - Complete user workflows
   - Database connectivity
   - Redis connectivity
   - API endpoint integration

3. **End-to-End Tests** (`tests/test_e2e.py`)
   - Browser-based testing with Selenium
   - Complete user journeys
   - UI interaction testing
   - Cross-browser compatibility

4. **Performance Tests** (`tests/test_performance.py`)
   - Response time testing
   - Concurrent request handling
   - Load testing with Locust
   - Memory usage simulation

5. **Security Tests** (`tests/test_security.py`)
   - SQL injection protection
   - XSS protection
   - Authentication security
   - Security headers verification

6. **API Tests** (Included in integration tests)
   - REST API endpoint testing
   - Authentication flow
   - Error handling
   - Data validation

### Running Tests:

#### All Tests:
```bash
cd tests
./run_tests.sh
```

#### Specific Test Types:
```bash
# Unit tests only
pytest test_auth.py test_products.py test_cart.py test_admin.py test_api.py -v

# Integration tests
pytest test_integration.py -v

# End-to-end tests (requires Chrome/Chromium)
pytest test_e2e.py -v

# Performance tests
pytest test_performance.py -v

# Security tests
pytest test_security.py -v
```

#### Test Coverage:
```bash
pytest --cov=../backend/app --cov-report=html
```

### Test Requirements:
```bash
pip install -r tests/requirements-test.txt
```

**Includes:**
- pytest, pytest-flask, pytest-cov
- selenium (for E2E tests)
- requests (for API tests)
- coverage reporting tools
- Security testing tools (bandit, safety)

### Test Environment Setup:
The tests can run against:
- Local development server
- Docker containers
- Kubernetes deployment

**Note:** Some tests require the application to be running. Start the application first, then run the tests.
