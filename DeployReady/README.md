# DeployReady — Kora Analytics API

A fully containerised Node.js API with an automated CI/CD pipeline and AWS EC2 deployment.

## Architecture

```
GitHub push to main
        │
        ▼
┌───────────────────────────────────────────┐
│ GitHub Actions                            │
│  1. Test  →  npm test                     │
│  2. Build →  docker build (commit SHA tag)│
│  3. Push  →  ghcr.io (GHCR)              │
│  4. Deploy→  SSH → EC2 → docker run       │
└───────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────┐
│ AWS EC2 (t2.micro)      │
│  Docker container       │
│  Port 80 → container 3000│
│  Security Group:        │
│   HTTP 80  — 0.0.0.0/0  │
│   SSH  22  — your IP    │
└─────────────────────────┘
```

## API Endpoints

| Method | Route      | Description                        |
|--------|------------|------------------------------------|
| GET    | `/health`  | Returns `{ "status": "ok" }`       |
| GET    | `/metrics` | Returns uptime and memory stats    |
| POST   | `/data`    | Echoes back the JSON request body  |

## Local Development

### Prerequisites

- Docker and Docker Compose

### Run locally

```bash
cp .env.example .env
docker compose up --build
```

The API is available at `http://localhost:3000`.

```bash
curl http://localhost:3000/health
# {"status":"ok"}
```

## CI/CD Pipeline

The pipeline lives in [.github/workflows/deploy.yml](.github/workflows/deploy.yml) and runs on every push to `main`:

1. **Test** — runs `npm test` inside the `app/` directory. A failing test stops the pipeline.
2. **Build** — builds the Docker image tagged with the short commit SHA and `latest`.
3. **Push** — pushes to GitHub Container Registry (GHCR) using `GITHUB_TOKEN`.
4. **Deploy** — SSHs into the EC2 instance, pulls the new image, and restarts the container. A health check confirms the deployment succeeded.

### Required GitHub secrets

| Secret        | Description                           |
|---------------|---------------------------------------|
| `EC2_HOST`    | Public IP or DNS of the EC2 instance  |
| `EC2_USER`    | SSH username (`ec2-user`)             |
| `EC2_SSH_KEY` | Contents of the EC2 `.pem` key file   |

## Deployment

See [DEPLOYMENT.md](DEPLOYMENT.md) for full EC2 setup and Docker installation instructions.

## Project Structure

```
DeployReady/
├── app/
│   ├── index.js          # Express API
│   ├── index.test.js     # Jest + Supertest tests
│   └── package.json
├── .github/
│   └── workflows/
│       └── deploy.yml    # CI/CD pipeline
├── Dockerfile
├── docker-compose.yml
├── .env.example
├── DEPLOYMENT.md
└── README.md
```

## Decisions

- **Node 20 Alpine** — minimal image size; Alpine reduces the attack surface compared to full Debian-based images.
- **Non-root user** — the container runs as `appuser`, not `root`, following the principle of least privilege.
- **`npm ci --omit=dev`** — installs only production dependencies in the image, keeping it lean and reproducible.
- **GHCR over ECR** — GitHub Container Registry is free for public repos and needs no extra AWS IAM setup for the push step, keeping secrets minimal.
- **Health check in deploy step** — a `curl -f http://localhost/health` after container start ensures the pipeline fails fast if the new image is broken, making rollback straightforward.
