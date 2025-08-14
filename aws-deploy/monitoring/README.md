# AWS Monitoring and Observability Setup

This directory contains monitoring configurations and scripts for AWS deployment of the e-commerce application.

## 📊 Monitoring Components

### 1. CloudWatch Dashboard (`cloudwatch-dashboard.json`)
- **Application Load Balancer metrics** - Request count, response times, error rates
- **ECS Service metrics** - CPU/Memory utilization, task health
- **RDS Database metrics** - CPU, connections, latency
- **ElastiCache Redis metrics** - CPU, connections, cache hit/miss rates
- **Application logs** - Error log analysis and filtering

### 2. CloudWatch Alarms (`setup-alarms.sh`)
Automated setup for critical application alarms:
- **High CPU Utilization** (>80%) - ECS tasks performance
- **High Memory Utilization** (>85%) - Memory leak detection
- **High Error Rate** (>10 5xx errors) - Application health
- **Database Connections** (>50) - Database connection pooling
- **High Response Time** (>2s) - User experience monitoring

### 3. X-Ray Tracing Configuration (`xray-config.json`)
- Distributed tracing for request flows
- Performance bottleneck identification
- Service dependency mapping
- Error root cause analysis

## 🚀 Quick Setup

### Prerequisites
```bash
# Ensure AWS CLI is configured
aws configure

# Set environment variables
export AWS_REGION=us-east-1
export APP_NAME=ecommerce-app
export NOTIFICATION_EMAIL=your-email@example.com
```

### 1. Setup CloudWatch Alarms
```bash
./setup-alarms.sh
```

### 2. Create CloudWatch Dashboard
```bash
# Replace placeholders with actual resource names
sed -i 's/${ALB_NAME}/your-alb-name/g' cloudwatch-dashboard.json
sed -i 's/${ECS_SERVICE_NAME}/your-service-name/g' cloudwatch-dashboard.json
sed -i 's/${ECS_CLUSTER_NAME}/your-cluster-name/g' cloudwatch-dashboard.json
sed -i 's/${RDS_INSTANCE_ID}/your-rds-instance/g' cloudwatch-dashboard.json
sed -i 's/${REDIS_CLUSTER_ID}/your-redis-cluster/g' cloudwatch-dashboard.json
sed -i 's/${LOG_GROUP_NAME}/your-log-group/g' cloudwatch-dashboard.json
sed -i 's/${AWS_REGION}/us-east-1/g' cloudwatch-dashboard.json

# Create the dashboard
aws cloudwatch put-dashboard \
    --dashboard-name "${APP_NAME}-monitoring" \
    --dashboard-body file://cloudwatch-dashboard.json
```

### 3. Enable X-Ray Tracing
```bash
# Apply X-Ray configuration to your ECS task definition
# This is typically done during ECS deployment
```

## 📈 Monitoring Best Practices

### 1. Key Metrics to Monitor
- **Application Performance:**
  - Response time (target: <1s)
  - Error rate (target: <1%)
  - Throughput (requests/second)

- **Infrastructure Health:**
  - CPU utilization (target: 60-80%)
  - Memory utilization (target: <80%)
  - Network I/O

- **Database Performance:**
  - Connection count
  - Query execution time
  - Read/Write latency

### 2. Alerting Strategy
- **Critical Alerts** - Immediate response required
  - Application down (5xx errors >5%)
  - Database unavailable
  - Memory exhaustion (>95%)

- **Warning Alerts** - Investigation needed
  - High response time (>2s)
  - High CPU (>80%)
  - Growing error rate

### 3. Log Management
- **Structured Logging** - Use JSON format for better parsing
- **Log Aggregation** - Centralize logs in CloudWatch
- **Log Retention** - Configure appropriate retention periods
- **Cost Optimization** - Use log groups and filters

## 🔍 Troubleshooting with Monitoring

### High Response Time
1. Check **ECS metrics** for CPU/Memory spikes
2. Review **RDS metrics** for database bottlenecks
3. Analyze **ALB metrics** for traffic patterns
4. Use **X-Ray traces** to identify slow components

### High Error Rate
1. Check **application logs** for error patterns
2. Review **database connection** metrics
3. Analyze **Redis cache** hit rates
4. Investigate **dependency failures**

### Resource Exhaustion
1. Monitor **ECS task scaling** metrics
2. Check **RDS connection pooling**
3. Review **memory leak patterns**
4. Analyze **auto-scaling policies**

## 💰 Cost Optimization

### CloudWatch Costs
- **Metrics:** $0.30 per metric per month
- **Logs:** $0.50 per GB ingested
- **Alarms:** $0.10 per alarm per month
- **Dashboards:** $3.00 per dashboard per month

### Optimization Tips
- Use **metric filters** to reduce log volume
- Set appropriate **log retention periods**
- Create **custom metrics** only when necessary
- Use **alarm suppression** during maintenance

## 🔗 Related Resources

- [AWS CloudWatch Documentation](https://docs.aws.amazon.com/cloudwatch/)
- [ECS Monitoring Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/monitoring.html)
- [RDS Performance Insights](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_PerfInsights.html)
- [X-Ray Developer Guide](https://docs.aws.amazon.com/xray/latest/devguide/)

## 📧 Support

For monitoring setup issues:
1. Verify AWS permissions (CloudWatch, SNS access)
2. Check resource naming and region consistency
3. Confirm email subscription for SNS notifications
4. Review CloudWatch dashboard configuration
