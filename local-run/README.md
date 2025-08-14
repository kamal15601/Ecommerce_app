# Local Development Setup

This folder contains all files needed to run the application locally on your development machine.

## Files in this folder:

### Python Environment Files
- `requirements-local.txt` - Python dependencies for local development
- `run-local.py` - Script to run the application locally
- `setup-local.sh` - Setup script for local environment

### Configuration Files
- `.env.local` - Local environment variables
- `config-local.py` - Local configuration settings

### Database Files
- `init-local-db.sql` - Local database initialization
- `sample-data-local.py` - Script to add sample data for development

### Scripts
- `start-local.sh` - Start all services locally
- `stop-local.sh` - Stop all local services
- `reset-local.sh` - Reset local database and data

## How to use:

1. Install Python dependencies:
   ```bash
   pip install -r requirements-local.txt
   ```

2. Set up local database:
   ```bash
   ./setup-local.sh
   ```

3. Start the application:
   ```bash
   ./start-local.sh
   ```

4. Access the application at: http://localhost:5000

## Requirements:
- Python 3.8+
- PostgreSQL 12+
- Redis 6+ (optional, for caching)
