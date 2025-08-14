# Dockerfile for PostgreSQL database
# NOTE: Base images should be regularly updated to address security vulnerabilities
#       Run 'docker scan' before deployment to verify security status

FROM bitnami/postgresql:16.1.0
ENV POSTGRESQL_DATABASE=ecommerce
ENV POSTGRESQL_USERNAME=admin
ENV POSTGRESQL_PASSWORD=adminpass
ENV POSTGRESQL_POSTGRES_PASSWORD=adminpass
COPY init.sql /docker-entrypoint-initdb.d/custom-scripts/
EXPOSE 5432
