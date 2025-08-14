#!/bin/bash
# CloudWatch Alarms Setup Script
# Sets up monitoring alarms for the e-commerce application

set -e

# Configuration
AWS_REGION=${AWS_REGION:-us-east-1}
APP_NAME=${APP_NAME:-ecommerce-app}
NOTIFICATION_EMAIL=${NOTIFICATION_EMAIL}

echo "🔔 Setting up CloudWatch Alarms for ${APP_NAME}..."

# Create SNS Topic for notifications
echo "Creating SNS topic for notifications..."
TOPIC_ARN=$(aws sns create-topic \
    --name "${APP_NAME}-alerts" \
    --region ${AWS_REGION} \
    --query 'TopicArn' \
    --output text)

echo "Topic ARN: ${TOPIC_ARN}"

# Subscribe email to SNS topic (if provided)
if [ ! -z "$NOTIFICATION_EMAIL" ]; then
    echo "Subscribing ${NOTIFICATION_EMAIL} to SNS topic..."
    aws sns subscribe \
        --topic-arn ${TOPIC_ARN} \
        --protocol email \
        --notification-endpoint ${NOTIFICATION_EMAIL} \
        --region ${AWS_REGION}
    
    echo "✅ Please check your email and confirm the subscription"
fi

# High CPU Utilization Alarm
echo "Creating High CPU Utilization alarm..."
aws cloudwatch put-metric-alarm \
    --alarm-name "${APP_NAME}-high-cpu" \
    --alarm-description "High CPU utilization detected" \
    --metric-name CPUUtilization \
    --namespace AWS/ECS \
    --statistic Average \
    --period 300 \
    --threshold 80 \
    --comparison-operator GreaterThanThreshold \
    --evaluation-periods 2 \
    --alarm-actions ${TOPIC_ARN} \
    --region ${AWS_REGION}

# High Memory Utilization Alarm
echo "Creating High Memory Utilization alarm..."
aws cloudwatch put-metric-alarm \
    --alarm-name "${APP_NAME}-high-memory" \
    --alarm-description "High memory utilization detected" \
    --metric-name MemoryUtilization \
    --namespace AWS/ECS \
    --statistic Average \
    --period 300 \
    --threshold 85 \
    --comparison-operator GreaterThanThreshold \
    --evaluation-periods 2 \
    --alarm-actions ${TOPIC_ARN} \
    --region ${AWS_REGION}

# High Error Rate Alarm (5xx errors)
echo "Creating High Error Rate alarm..."
aws cloudwatch put-metric-alarm \
    --alarm-name "${APP_NAME}-high-error-rate" \
    --alarm-description "High 5xx error rate detected" \
    --metric-name HTTPCode_Target_5XX_Count \
    --namespace AWS/ApplicationELB \
    --statistic Sum \
    --period 300 \
    --threshold 10 \
    --comparison-operator GreaterThanThreshold \
    --evaluation-periods 1 \
    --alarm-actions ${TOPIC_ARN} \
    --region ${AWS_REGION}

# Database Connection Alarm
echo "Creating Database Connection alarm..."
aws cloudwatch put-metric-alarm \
    --alarm-name "${APP_NAME}-db-connections" \
    --alarm-description "High database connections detected" \
    --metric-name DatabaseConnections \
    --namespace AWS/RDS \
    --statistic Average \
    --period 300 \
    --threshold 50 \
    --comparison-operator GreaterThanThreshold \
    --evaluation-periods 2 \
    --alarm-actions ${TOPIC_ARN} \
    --region ${AWS_REGION}

# Response Time Alarm
echo "Creating High Response Time alarm..."
aws cloudwatch put-metric-alarm \
    --alarm-name "${APP_NAME}-high-response-time" \
    --alarm-description "High response time detected" \
    --metric-name TargetResponseTime \
    --namespace AWS/ApplicationELB \
    --statistic Average \
    --period 300 \
    --threshold 2.0 \
    --comparison-operator GreaterThanThreshold \
    --evaluation-periods 3 \
    --alarm-actions ${TOPIC_ARN} \
    --region ${AWS_REGION}

echo "✅ CloudWatch Alarms setup complete!"
echo ""
echo "📊 Created alarms:"
echo "  - High CPU Utilization (>80%)"
echo "  - High Memory Utilization (>85%)"
echo "  - High Error Rate (>10 5xx errors)"
echo "  - High Database Connections (>50)"
echo "  - High Response Time (>2s)"
echo ""
echo "📧 SNS Topic: ${TOPIC_ARN}"
if [ ! -z "$NOTIFICATION_EMAIL" ]; then
    echo "📧 Email notifications will be sent to: ${NOTIFICATION_EMAIL}"
    echo "   (Please confirm the subscription in your email)"
fi
echo ""
echo "View alarms: https://console.aws.amazon.com/cloudwatch/home?region=${AWS_REGION}#alarmsV2:"
