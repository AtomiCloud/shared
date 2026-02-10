---
id: docker-push
title: Docker Push
---

# Docker Push

This document describes the Docker image build and push pattern used in the workspace template.

## Overview

Docker images are built and pushed to GitHub Container Registry (GHCR) as part of CI/CD. The pattern uses a reusable workflow that handles multi-platform builds, tagging strategies, and registry authentication.

## Reusable Workflow Pattern

### Workflow File

`.github/workflows/⚡reusable-docker.yaml`

### Setup

Uses `AtomiCloud/actions.setup-docker@v1` action and runs:

```bash
./scripts/ci/docker.sh [version]
```

## Required Inputs (LPSM-based)

| Input            | Required | Description                                           |
| ---------------- | -------- | ----------------------------------------------------- |
| `atomi_platform` | Yes      | LPSM Platform for cache namespacing                   |
| `atomi_service`  | Yes      | LPSM Service for cache namespacing                    |
| `image_name`     | Yes      | Name for the Docker image                             |
| `dockerfile`     | No       | Path to Dockerfile (default: `Dockerfile`)            |
| `context`        | No       | Build context (default: `.`)                          |
| `platform`       | No       | Target platforms (default: `linux/arm64,linux/amd64`) |
| `version`        | No       | Semver version for release tagging (CD only)          |

## Tagging Strategy

Images are tagged based on the build context:

| Tag    | Format           | When                                     |
| ------ | ---------------- | ---------------------------------------- |
| Commit | `{sha}-{branch}` | Always                                   |
| Branch | `{branch}`       | Always                                   |
| Latest | `latest`         | Only on main branch                      |
| Semver | `v1.2.3`         | Only when version input is provided (CD) |

## Registry

### Domain

`ghcr.io`

### Image Path

```
ghcr.io/{github_repo}/{image_name}
```

For example, if the repository is `AtomiCloud/my-service` and `image_name` is `api`:

```
ghcr.io/atomicloud/my-service/api
```

## Environment Variables

The following environment variables are provided by the reusable workflow:

| Variable             | Source                    | Description                 |
| -------------------- | ------------------------- | --------------------------- |
| `DOMAIN`             | Fixed                     | Registry domain (`ghcr.io`) |
| `DOCKER_PASSWORD`    | `secrets.GITHUB_TOKEN`    | Registry authentication     |
| `DOCKER_USER`        | `github.actor`            | Registry username           |
| `GITHUB_REPO_REF`    | `github.repository`       | Repository reference        |
| `GITHUB_SHA`         | `github.sha`              | Commit SHA                  |
| `GITHUB_BRANCH`      | `GITHUB_REF_SLUG` env var | Branch name                 |
| `CI_DOCKER_IMAGE`    | `inputs.image_name`       | Docker image name           |
| `CI_DOCKER_CONTEXT`  | `inputs.context`          | Build context path          |
| `CI_DOCKERFILE`      | `inputs.dockerfile`       | Dockerfile path             |
| `CI_DOCKER_PLATFORM` | `inputs.platform`         | Target platforms            |

## Adding a New Docker Image

### Step 1: Create Dockerfile

Create a Dockerfile at your desired path (e.g., `Dockerfile` or `./infra/Dockerfile`).

### Step 2: Add CI Job

Add a job to your CI workflow calling the reusable workflow:

```yaml
# .github/workflows/ci.yml
jobs:
  docker-api:
    uses: ./.github/workflows/⚡reusable-docker.yaml
    secrets: inherit
    with:
      atomi_platform: ${{ github.repository_owner }}
      atomi_service: ${{ github.event.repository.name }}
      image_name: api
      dockerfile: Dockerfile
      context: .
```

### Step 3: Add CD Job (Optional)

For release deployments, add a job to your CD workflow:

```yaml
# .github/workflows/cd.yml
jobs:
  docker-api:
    uses: ./.github/workflows/⚡reusable-docker.yaml
    secrets: inherit
    with:
      atomi_platform: ${{ github.repository_owner }}
      atomi_service: ${{ github.event.repository.name }}
      image_name: api
      dockerfile: Dockerfile
      context: .
      version: ${{ github.ref_name }} # e.g., v1.2.3
```

## Examples

### Single Platform Build

```yaml
with:
  atomi_platform: sulfoxide
  atomi_service: hydrogen
  image_name: api
  platform: linux/amd64
```

### Custom Dockerfile Location

```yaml
with:
  atomi_platform: sulfoxide
  atomi_service: hydrogen
  image_name: worker
  dockerfile: ./infra/Dockerfile.worker
  context: ./infra
```

### Multiple Images

You can call the reusable workflow multiple times for different images:

```yaml
jobs:
  docker-api:
    uses: ./.github/workflows/⚡reusable-docker.yaml
    secrets: inherit
    with:
      atomi_platform: ${{ github.repository_owner }}
      atomi_service: ${{ github.event.repository.name }}
      image_name: api

  docker-worker:
    uses: ./.github/workflows/⚡reusable-docker.yaml
    secrets: inherit
    with:
      atomi_platform: ${{ github.repository_owner }}
      atomi_service: ${{ github.event.repository.name }}
      image_name: worker
```

## Trigger Words

When you see these terms, the docker-push pattern applies:

- Docker, container, image
- GHCR, container registry
- Dockerfile, docker build, docker push
- Multi-platform build

## Summary

| Aspect         | Pattern                             |
| -------------- | ----------------------------------- |
| **Workflow**   | `⚡reusable-docker.yaml`            |
| **Script**     | `./scripts/ci/docker.sh`            |
| **Registry**   | `ghcr.io`                           |
| **Image path** | `ghcr.io/{repo}/{image_name}`       |
| **Tags (CI)**  | `{sha}-{branch}`, `{branch}`        |
| **Tags (CD)**  | `v1.2.3` (when version provided)    |
| **Latest tag** | Only on main branch                 |
| **Platforms**  | `linux/arm64,linux/amd64` (default) |

## See Also

- [CI/CD Workflows](./ci-cd.md) - Overall CI/CD architecture
- [Service Tree (LPSM)](./service-tree.md) - LPSM naming conventions
