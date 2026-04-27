# Deployment Guide

## Infrastructure

| | |
|---|---|
| **Provider** | DigitalOcean |
| **Droplet IP** | `139.59.160.145` |
| **OS** | Ubuntu 24.04 LTS |
| **Size** | 1 vCPU, 1GB RAM |
| **Container Registry** | GitHub Container Registry (GHCR) |

---

## 1. Provision the Droplet

Create a Droplet on DigitalOcean with the following settings:

- **Image:** Ubuntu 24.04 LTS
- **Size:** Basic, $6/month (1 vCPU, 1GB RAM)
- **Authentication:** SSH Key
- **Firewall rules:**

  | Type | Protocol | Port | Source         |
  |------|----------|------|----------------|
  | HTTP | TCP      | 80   | 0.0.0.0/0      |
  | SSH  | TCP      | 22   | Your IP only   |

---

## 2. Install Docker (first-time setup)

SSH into the Droplet:

```bash
ssh -i ~/.ssh/kora_deploy root@139.59.160.145
```

Install Docker:

```bash
apt update && apt install -y docker.io
systemctl enable --now docker
```

---

## 3. First-time manual run (before the pipeline runs)

Before the pipeline has run for the first time, pull and start the container manually:

```bash
# Log in to GitHub Container Registry (use a GitHub Personal Access Token with read:packages scope)
echo "<YOUR_GITHUB_PAT>" | docker login ghcr.io -u aimedidierm --password-stdin

# Pull the latest image
docker pull ghcr.io/aimedidierm/kora-analytics-api:latest

# Run the container
docker run -d \
  --name kora-api \
  --restart unless-stopped \
  -p 80:3000 \
  -e PORT=3000 \
  ghcr.io/aimedidierm/kora-analytics-api:latest
```

After the first successful pipeline run, all subsequent deployments are handled automatically.

---

## 4. Checking container status

```bash
# List running containers
docker ps

# Verify the health endpoint responds
curl http://localhost/health
# Expected: {"status":"ok"}

# Full container details
docker inspect kora-api
```

---

## 5. Viewing application logs

```bash
# Stream live logs
docker logs -f kora-api

# Show the last 100 lines
docker logs --tail 100 kora-api
```

---

## 6. GitHub Secrets

Add these in your repo under **Settings → Secrets and variables → Actions**:

| Secret        | Value                                              |
|---------------|----------------------------------------------------|
| `EC2_HOST`    | `139.59.160.145`                                   |
| `EC2_USER`    | `root`                                             |
| `EC2_SSH_KEY` | Full contents of `~/.ssh/kora_deploy` private key  |

`GITHUB_TOKEN` is provided automatically by GitHub Actions — no manual setup needed.

---

## 7. Rollback

If the health check after a deploy fails, the pipeline exits with a non-zero code. To manually roll back to a previous image:

```bash
# Replace <sha> with the short commit SHA of the last known good build
# (visible in the GitHub Actions run history or with: docker images ghcr.io/aimedidierm/kora-analytics-api)

docker stop kora-api && docker rm kora-api
docker run -d \
  --name kora-api \
  --restart unless-stopped \
  -p 80:3000 \
  -e PORT=3000 \
  ghcr.io/aimedidierm/kora-analytics-api:<sha>
```
