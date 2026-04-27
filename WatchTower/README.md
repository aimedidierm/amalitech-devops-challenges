# WatchTower — Reyla Logistics Observability Stack

Full observability stack for three backend services: metrics collection with Prometheus, dashboards with Grafana, and alerting rules.

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                   Docker Network: reyla-net          │
│                                                     │
│  order-service :3001  ──┐                           │
│  tracking-service :3002 ──┼──► Prometheus :9090     │
│  notification-service :3003 ─┘        │             │
│                                       ▼             │
│                               Grafana :3000          │
│                               (dashboards + alerts)  │
└─────────────────────────────────────────────────────┘
```

## Services

| Service              | Port | Endpoints                          |
|----------------------|------|------------------------------------|
| order-service        | 3001 | `/health`, `/metrics`, `/orders`   |
| tracking-service     | 3002 | `/health`, `/metrics`, `/track/:id`|
| notification-service | 3003 | `/health`, `/metrics`, `/notify`   |
| Prometheus           | 9090 | `/targets`, `/alerts`              |
| Grafana              | 3000 | Dashboards UI                      |

## Setup

### Prerequisites

- Docker and Docker Compose

### Start the stack

```bash
cp .env.example .env
docker compose up --build
```

### Verify everything is running

1. **Prometheus targets** — open `http://localhost:9090/targets`
   All three services must show **State: UP**.

2. **Grafana dashboard** — open `http://localhost:3000`
   Login: `admin` / `admin` (or whatever you set in `.env`)
   The **Reyla Logistics — Service Overview** dashboard loads automatically.

## Dashboard Walkthrough

The dashboard has five panels:

| Panel | Type | Query |
|-------|------|-------|
| HTTP Request Rate | Time series | `sum(rate(http_requests_total[5m])) by (job)` |
| 5xx Error Rate | Time series | 5xx requests / total requests per service |
| Order Service Health | Stat (green/red) | `up{job="order-service"}` |
| Tracking Service Health | Stat (green/red) | `up{job="tracking-service"}` |
| Notification Service Health | Stat (green/red) | `up{job="notification-service"}` |

## Alert Rules

Defined in [prometheus/alerts.yml](prometheus/alerts.yml):

| Alert | Condition | Severity |
|-------|-----------|----------|
| `ServiceDown` | `up == 0` for 1 minute | critical |
| `HighErrorRate` | >5% 5xx over 5 minutes | warning |
| `ServiceNotScraping` | No metrics received for 2 minutes | warning |

### How I tested each alert

**ServiceDown**
```bash
# Stop one service
docker compose stop order-service
# Wait 1 minute, then check
curl http://localhost:9090/api/v1/alerts
# ServiceDown fires for order-service
docker compose start order-service
```

**HighErrorRate**
```bash
# Send requests that hit the 400 path (services return 4xx, not 5xx by default)
# To trigger 5xx you'd need to corrupt the service — tested by temporarily
# modifying order-service to return 500 and watching the rate climb above 5%
```

**ServiceNotScraping**
```bash
# Remove the service from the network entirely
docker compose stop notification-service && docker compose rm -f notification-service
# Wait 2 minutes
curl http://localhost:9090/api/v1/alerts
# ServiceNotScraping fires
```

## Log Commands

### View live logs from all services at once

```bash
docker compose logs -f order-service tracking-service notification-service
```

### Filter logs to show only errors from a specific service

```bash
# Show only error-level log lines from order-service
docker compose logs order-service | grep '"level":"error"'

# Or stream live errors from notification-service
docker compose logs -f notification-service | grep '"level":"error"'
```

**Example output:**
```json
{"level":"error","service":"order-service","msg":"Unhandled exception","err":"..."}
```

## Project Structure

```
WatchTower/
├── app/
│   ├── order-service/
│   ├── tracking-service/
│   └── notification-service/
├── prometheus/
│   ├── prometheus.yml        # Scrape config (15s interval, all 3 services)
│   └── alerts.yml            # ServiceDown, HighErrorRate, ServiceNotScraping
├── grafana/
│   ├── provisioning/
│   │   ├── datasources/      # Auto-configures Prometheus as data source
│   │   └── dashboards/       # Auto-loads dashboards from /var/lib/grafana/dashboards
│   └── dashboards/
│       └── reyla-overview.json
├── docker-compose.yml
├── .env.example
└── README.md
```
