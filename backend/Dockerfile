# Dockerfile for Flask backend with security best practices
# NOTE: Base images should be regularly updated to address security vulnerabilities
#       Run 'docker scan' before deployment to verify security status

FROM python:3.11-alpine AS builder

# Set working directory
WORKDIR /app

# Install build dependencies and runtime dependencies
RUN apk add --no-cache gcc python3-dev

# Copy requirements file
COPY requirements.txt ./

# Create virtual environment and install dependencies
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Final stage
FROM python:3.11-alpine

# Create a non-root user to run the app
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Set working directory
WORKDIR /app

# Copy virtual environment from builder stage
COPY --from=builder /opt/venv /opt/venv

# Set environment variables
ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Copy application code
COPY --chown=appuser:appuser . .

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 5000

# Run the application
CMD ["python", "app.py"]
