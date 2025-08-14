FROM redis:7-alpine

# Copy custom redis configuration
COPY redis.conf /usr/local/etc/redis/redis.conf

# Create redis directories
RUN mkdir -p /data
RUN chown redis:redis /data

# Expose port
EXPOSE 6379

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD redis-cli ping | grep PONG

CMD ["redis-server", "/usr/local/etc/redis/redis.conf"]
