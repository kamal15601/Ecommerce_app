# ELK Stack (Elasticsearch, Logstash, Kibana) - Logging & Visualization

## Overview
The ELK Stack is a powerful set of tools for searching, analyzing, and visualizing log data in real time. It consists of Elasticsearch (search engine), Logstash (data processing pipeline), and Kibana (visualization dashboard).

## Learning Objectives
- Deploy and configure the ELK stack
- Collect and parse logs from applications and infrastructure
- Visualize logs and metrics in Kibana
- Implement log retention and security best practices
- Integrate ELK with monitoring and alerting systems

## Prerequisites
- Basic Linux/Unix knowledge
- Docker and Kubernetes familiarity
- Understanding of log formats (JSON, syslog, etc.)

---

## Lab 1: ELK Stack Deployment (Docker)

### Steps
1. **Run ELK Stack with Docker Compose**
```yaml
# docker-compose.yml
version: '3.7'
services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.13.0
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
    ports:
      - 9200:9200
    volumes:
      - esdata:/usr/share/elasticsearch/data
  logstash:
    image: docker.elastic.co/logstash/logstash:8.13.0
    ports:
      - 5000:5000
    volumes:
      - ./logstash.conf:/usr/share/logstash/pipeline/logstash.conf
  kibana:
    image: docker.elastic.co/kibana/kibana:8.13.0
    ports:
      - 5601:5601
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
volumes:
  esdata:
```
2. **Access Kibana UI**
- Open http://localhost:5601

---

## Lab 2: Logstash Pipeline Configuration

### Steps
1. **Basic Logstash Pipeline**
```conf
# logstash.conf
input {
  tcp {
    port => 5000
    codec => json
  }
}
filter {
  grok {
    match => { "message" => "%{COMBINEDAPACHELOG}" }
  }
}
output {
  elasticsearch {
    hosts => ["elasticsearch:9200"]
    index => "app-logs-%{+YYYY.MM.dd}"
  }
}
```
2. **Send Test Log**
```bash
echo '{"message": "127.0.0.1 - - [13/Aug/2025:10:00:00 +0000] \"GET /index.html HTTP/1.1\" 200 2326"}' | nc localhost 5000
```

---

## Lab 3: Kibana Visualization & Dashboards

### Steps
1. **Create Index Pattern**
- In Kibana, go to "Stack Management" > "Index Patterns" > Create index pattern (e.g., `app-logs-*`)

2. **Build Visualizations**
- Create bar charts, pie charts, and tables for log analysis
- Example: HTTP status codes, top endpoints, error rates

3. **Dashboard Example**
- Combine multiple visualizations into a single dashboard for real-time monitoring

---

## Lab 4: Kubernetes Logging with ELK

### Steps
1. **Deploy Filebeat for Kubernetes Log Collection**
```yaml
# filebeat-kubernetes.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: filebeat
  namespace: kube-logging
spec:
  selector:
    matchLabels:
      k8s-app: filebeat
  template:
    metadata:
      labels:
        k8s-app: filebeat
    spec:
      containers:
      - name: filebeat
        image: docker.elastic.co/beats/filebeat:8.13.0
        env:
        - name: ELASTICSEARCH_HOSTS
          value: "http://elasticsearch:9200"
        volumeMounts:
        - name: varlog
          mountPath: /var/log
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
```
2. **Visualize Kubernetes Logs in Kibana**
- Create dashboards for pod logs, error rates, and resource usage

---

## Lab 5: Security, Retention, and Alerting

### Steps
1. **Enable Security (Elasticsearch/Kibana)**
- Configure users, roles, and TLS for production

2. **Log Retention Policy**
- Use ILM (Index Lifecycle Management) to manage log retention and deletion

3. **Alerting with Kibana**
- Set up alerts for error spikes, unauthorized access, or resource exhaustion

---

## Best Practices
- Use structured logging (JSON) for easier parsing
- Secure Elasticsearch and Kibana in production
- Monitor ELK resource usage and scale as needed
- Integrate with monitoring tools (Prometheus, Grafana)
- Document log formats and pipelines

---

## Resources
- [ELK Stack Documentation](https://www.elastic.co/guide/index.html)
- [Kibana Tutorials](https://www.elastic.co/guide/en/kibana/current/tutorials.html)
- [Logstash Pipeline Examples](https://www.elastic.co/guide/en/logstash/current/pipeline.html)
- [Filebeat for Kubernetes](https://www.elastic.co/guide/en/beats/filebeat/current/running-on-kubernetes.html)
- [Index Lifecycle Management](https://www.elastic.co/guide/en/elasticsearch/reference/current/index-lifecycle-management.html)
