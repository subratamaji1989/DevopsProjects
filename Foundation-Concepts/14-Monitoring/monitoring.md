# Monitoring Cheat Sheet: Prometheus, Grafana & ELK Stack (Beginner → Expert)

> Covers installation, configuration, metrics, dashboards, alerting, logs, visualization, and best practices for Prometheus, Grafana, and ELK (Elasticsearch, Logstash, Kibana).

---

## Table of Contents

1. Introduction & Principles
2. Prometheus Basics
3. Prometheus Metrics & Queries (PromQL)
4. Grafana Basics & Dashboards
5. Grafana Alerts & Notification Channels
6. ELK Stack Overview
7. Elasticsearch Queries & Indexing
8. Logstash Pipelines
9. Kibana Visualization & Dashboards
10. Alerting & Integrations
11. Exporters & Integrations
12. Best Practices & Tips
13. Troubleshooting

---

# 1. Introduction & Principles

* **Monitoring:** Observability of applications, infrastructure, and services.
* **Metrics vs Logs:** Metrics = numerical data, Logs = events & traces.
* **Tools Overview:**

  * Prometheus: metrics collection & querying
  * Grafana: visualization & alerting
  * ELK Stack: logs aggregation, search, and visualization

---

# 2. Prometheus Basics

**Installation (Docker example)**

```bash
docker run -d --name prometheus -p 9090:9090 prom/prometheus
```

**Basic Config (prometheus.yml)**

```yaml
scrape_configs:
  - job_name: 'node'
    static_configs:
      - targets: ['localhost:9100']
```

**Run Prometheus CLI**

```bash
prometheus --config.file=prometheus.yml
```

---

# 3. Prometheus Metrics & Queries (PromQL)

**Basic Queries**

```promql
# CPU usage
rate(node_cpu_seconds_total{mode="user"}[5m])

# Memory usage
node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes

# Active HTTP requests
sum(rate(http_requests_total[5m]))
```

**Alerts in Prometheus**

```yaml
alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - 'localhost:9093'
```

**Recording rules:**

```yaml
groups:
- name: example.rules
  rules:
  - record: instance:node_cpu:rate5m
    expr: rate(node_cpu_seconds_total[5m])
```

---

# 4. Grafana Basics & Dashboards

**Installation (Docker)**

```bash
docker run -d -p 3000:3000 grafana/grafana
```

**Login:** admin/admin

**Add Data Source:** Prometheus, Elasticsearch

**Create Dashboard:**

* Panels → Visualization (Graph, Gauge, Table)
* Use PromQL queries for metrics

---

# 5. Grafana Alerts & Notification Channels

**Alert Rules:**

* Set thresholds on panels
* Evaluate every N seconds
* Send notifications if alert fires

**Notification Channels:** Slack, Email, PagerDuty

**Example Alert:**

```yaml
- alert: HighCPU
  expr: rate(node_cpu_seconds_total{mode="user"}[5m]) > 0.8
  for: 5m
  labels:
    severity: critical
  annotations:
    summary: "High CPU usage detected"
```

---

# 6. ELK Stack Overview

* **Elasticsearch:** storage & search engine
* **Logstash:** log processing & ingestion
* **Kibana:** visualization & dashboards

**Docker quick start:**

```bash
docker network create elk
# Elasticsearch
docker run -d --name elasticsearch --net elk -p 9200:9200 -e "discovery.type=single-node" elasticsearch:8.10.0
# Kibana
docker run -d --name kibana --net elk -p 5601:5601 kibana:8.10.0
# Logstash
docker run -d --name logstash --net elk -p 5044:5044 logstash:8.10.0
```

---

# 7. Elasticsearch Queries & Indexing

**Index document:**

```json
PUT /my_index/_doc/1
{
  "host": "server1",
  "message": "Service started"
}
```

**Search logs:**

```json
GET /my_index/_search
{
  "query": { "match": { "message": "error" } }
}
```

**List indices:**

```json
GET /_cat/indices?v
```

---

# 8. Logstash Pipelines

**Example pipeline (logstash.conf):**

```conf
input {
  beats {
    port => 5044
  }
}
filter {
  grok {
    match => { "message" => "%{COMMONAPACHELOG}" }
  }
}
output {
  elasticsearch {
    hosts => ["http://elasticsearch:9200"]
    index => "weblogs-%{+YYYY.MM.dd}"
  }
}
```

---

# 9. Kibana Visualization & Dashboards

* Create index pattern → visualize logs
* Use Lens or TSVB for charts
* Dashboards combine multiple visualizations
* Filters & queries to slice data

---

# 10. Alerting & Integrations

* Prometheus Alertmanager → Grafana → Slack/Email
* ELK → Watcher / Kibana Alerting → notification channels
* Integrate with OpsGenie, PagerDuty, Microsoft Teams

---

# 11. Exporters & Integrations

**Prometheus Exporters:**

* node_exporter: OS metrics
* blackbox_exporter: HTTP/S checks
* cadvisor: Docker container metrics

**ELK Inputs:**

* Beats: Filebeat, Metricbeat, Packetbeat
* Logstash: TCP, HTTP, Kafka, Redis

---

# 12. Best Practices & Tips

* Keep Prometheus scrape intervals reasonable (avoid overload)
* Use Grafana dashboards for both metrics & logs correlation
* Archive old metrics/logs to save storage
* Secure access: TLS, authentication
* Tag metrics & logs for easier filtering
* Alert on actionable conditions, avoid alert fatigue
* Centralize logs from multiple services

---

# 13. Troubleshooting

* Prometheus UI: check targets → verify metrics
* Grafana: panel query errors → check PromQL
* Elasticsearch: check cluster health `_cluster/health`
* Logstash: pipeline errors → check logs `/usr/share/logstash/logs/`
* Kibana: index pattern mismatch → refresh index patterns

---

*End of cheat sheet — effective monitoring with Prometheus, Grafana, and ELK Stack!*
