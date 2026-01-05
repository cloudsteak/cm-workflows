# cm-workflows

Reusable GitHub Actions workflows for building and publishing Docker images.

## Workflow Usage Order

For a complete CI/CD pipeline, use the workflows in this order:

1. **Staging Build** - Runs on every PR and push to main branch for testing and staging environments
2. **New Release** - Manually triggered to create a new semantic version tag
3. **Production Build** - Automatically triggered by the version tag to build and publish production images

## Workflows

### New Release

**Workflow file**: [`.github/workflows/new-release.yml`](.github/workflows/new-release.yml)

This reusable workflow automates the semantic versioning and release creation process. It calculates the next version based on the release type, creates a Git tag, and generates a GitHub Release with automatically generated release notes.

#### Features

- Automatically calculates the next semantic version (major, minor, or patch)
- Fetches the latest existing tag and bumps version accordingly
- Creates and pushes a new Git tag
- Generates a GitHub Release with automatic release notes
- Outputs the new version for use in subsequent jobs
- If no previous tags exist, starts from `0.0.0`

#### Usage

To use this workflow in your repository, create a workflow file (e.g., `.github/workflows/create-release.yml`) with the following content:

```yaml
name: Create Release

on:
  workflow_dispatch:
    inputs:
      release_type:
        description: 'Release type'
        required: true
        type: choice
        options:
          - patch
          - minor
          - major
      branch:
        description: 'Branch to release from'
        required: true
        type: string
        default: 'main'

jobs:
  create-release:
    uses: cloudsteak/cm-workflows/.github/workflows/new-release.yml@main
    with:
      release_type: ${{ inputs.release_type }}
      branch: ${{ inputs.branch }}
    permissions:
      contents: write

  # Optional: Chain with production build
  build-production:
    needs: create-release
    uses: cloudsteak/cm-workflows/.github/workflows/production-build-push.yml@main
    with:
      image_name: "my-app"
```

#### Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `release_type` | Yes | - | Type of version bump: `major`, `minor`, or `patch` |
| `branch` | Yes | - | Branch to create the release from (typically `main`) |

#### Outputs

| Output | Description |
|--------|-------------|
| `new_version` | The newly created semantic version tag (e.g., `1.2.3`) |

#### Permissions

This workflow requires the following permissions:
- `contents: write` - To create tags and GitHub Releases

#### Version Bumping Logic

- **Patch** (`1.2.3` → `1.2.4`) - Bug fixes and small updates
- **Minor** (`1.2.3` → `1.3.0`) - New features, backward compatible
- **Major** (`1.2.3` → `2.0.0`) - Breaking changes

#### Example

When you manually trigger this workflow with:
- `release_type`: `minor`
- `branch`: `main`
- Current latest tag: `1.5.2`

The workflow will:
1. Fetch all existing tags
2. Find the latest tag (`1.5.2`)
3. Calculate the new version (`1.6.0`)
4. Create and push the tag `1.6.0`
5. Create a GitHub Release with auto-generated release notes
6. Output `new_version: 1.6.0` for chained workflows

---

### New Release (Monorepo)

**Workflow file**: [`.github/workflows/new-release-monorepo.yml`](.github/workflows/new-release-monorepo.yml)

This reusable workflow automates semantic versioning and release creation for **monorepo projects** where multiple services live in the same repository. It creates service-specific tags (e.g., `messenger/v1.2.3`) to enable independent versioning for each service.

#### Features

- Service-scoped semantic versioning (tags like `service/vX.Y.Z`)
- Automatically calculates the next version per service
- Fetches the latest service-specific tag and bumps version accordingly
- Creates and pushes service-scoped Git tags
- Generates GitHub Releases with automatic release notes
- Outputs both the version and full tag for use in subsequent jobs
- If no previous service tags exist, starts from `v0.0.0`

#### Usage

To use this workflow in your monorepo, create a workflow file (e.g., `.github/workflows/release-service.yml`) with the following content:

```yaml
name: Create Service Release

on:
  workflow_dispatch:
    inputs:
      service:
        description: 'Service name (folder under services/)'
        required: true
        type: choice
        options:
          - messenger
          - api
          - worker
      release_type:
        description: 'Release type'
        required: true
        type: choice
        options:
          - patch
          - minor
          - major
      branch:
        description: 'Branch to release from'
        required: true
        type: string
        default: 'main'

jobs:
  create-release:
    uses: cloudsteak/cm-workflows/.github/workflows/new-release-monorepo.yml@main
    with:
      service: ${{ inputs.service }}
      release_type: ${{ inputs.release_type }}
      branch: ${{ inputs.branch }}
    permissions:
      contents: write

  # Optional: Chain with production build for the specific service
  build-production:
    needs: create-release
    uses: cloudsteak/cm-workflows/.github/workflows/production-build-push.yml@main
    with:
      image_name: ${{ inputs.service }}
      dockerfile_path: "./services/${{ inputs.service }}/Dockerfile"
      build_context: "./services/${{ inputs.service }}"
```

#### Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `service` | Yes | - | Service name (e.g., folder name under `services/`) |
| `release_type` | Yes | - | Type of version bump: `major`, `minor`, or `patch` |
| `branch` | Yes | - | Branch to create the release from (typically `main`) |

#### Outputs

| Output | Description |
|--------|-------------|
| `new_version` | The newly created semantic version (e.g., `v1.2.3`) |
| `new_tag` | The full service-scoped tag created (e.g., `messenger/v1.2.3`) |

#### Permissions

This workflow requires the following permissions:
- `contents: write` - To create tags and GitHub Releases

#### Tag Structure

Tags follow the format: `<service>/vX.Y.Z`

Examples:
- `messenger/v1.0.0`
- `api/v2.3.4`
- `worker/v0.1.5`

This allows each service to maintain its own independent version history.

#### Version Bumping Logic

- **Patch** (`messenger/v1.2.3` → `messenger/v1.2.4`) - Bug fixes and small updates
- **Minor** (`messenger/v1.2.3` → `messenger/v1.3.0`) - New features, backward compatible
- **Major** (`messenger/v1.2.3` → `messenger/v2.0.0`) - Breaking changes

#### Example

When you manually trigger this workflow with:
- `service`: `messenger`
- `release_type`: `minor`
- `branch`: `main`
- Current latest tag for messenger: `messenger/v1.5.2`

The workflow will:
1. Fetch all existing tags
2. Find the latest tag for the messenger service (`messenger/v1.5.2`)
3. Calculate the new version (`v1.6.0`)
4. Create and push the tag `messenger/v1.6.0`
5. Create a GitHub Release with auto-generated release notes
6. Output `new_version: v1.6.0` and `new_tag: messenger/v1.6.0` for chained workflows

---

### Staging Build and Push

**Workflow file**: [`.github/workflows/staging-build-push.yml`](.github/workflows/staging-build-push.yml)

This reusable workflow builds and pushes Docker images to GitHub Container Registry (GHCR) for development and staging purposes. It's designed to run on pull requests, pushes to main branch, or any non-production builds.

#### Features

- Builds Docker images using Docker Buildx
- Pushes images to GitHub Container Registry (GHCR)
- Tags images with both `latest` and short commit SHA (first 7 characters)
- Supports custom Dockerfile paths and build contexts
- Multi-platform build support

#### Usage

To use this workflow in your repository, create a workflow file (e.g., `.github/workflows/staging.yml`) with the following content:

```yaml
name: Staging Build

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  build:
    uses: cloudsteak/cm-workflows/.github/workflows/staging-build-push.yml@main
    with:
      image_name: "my-app"
      dockerfile_path: "./Dockerfile"      # optional, default: ./Dockerfile
      build_context: "."                   # optional, default: .
      platforms: "linux/amd64,linux/arm64" # optional, default: linux/amd64
```

#### Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `image_name` | Yes | - | Docker image name (will be pushed to `ghcr.io/<owner>/<image_name>`) |
| `dockerfile_path` | No | `./Dockerfile` | Path to the Dockerfile |
| `build_context` | No | `.` | Build context directory |
| `platforms` | No | `linux/amd64` | Target platforms (comma-separated) |

#### Permissions

This workflow requires the following permissions:
- `contents: read` - To checkout the repository
- `packages: write` - To push images to GitHub Container Registry

#### Image Tagging

Images are tagged with two tags:
- `latest` - Always points to the most recent build
- Short commit SHA (7 characters) - Unique identifier for each commit

Example:
- Commit SHA: `abc1234def5678` 
- Tags created:
  - `ghcr.io/<owner>/<image_name>:latest`
  - `ghcr.io/<owner>/<image_name>:abc1234`

#### Example

When you push to the main branch or create a pull request, the workflow will:
1. Checkout the code from the PR or branch
2. Build the Docker image from the specified Dockerfile
3. Push the image with both `latest` and commit SHA tags

---

### Production Build from Tag

**Workflow file**: [`.github/workflows/production-build-push.yml`](.github/workflows/production-build-push.yml)

This reusable workflow builds and pushes Docker images to GitHub Container Registry (GHCR) when triggered by a semantic version tag.

#### Features

- Validates that the trigger is a semantic version tag (e.g., `1.0.0`)
- Builds Docker images using Docker Buildx
- Pushes images to GitHub Container Registry (GHCR)
- Supports custom Dockerfile paths and build contexts
- Multi-platform build support

#### Usage

To use this workflow in your repository, create a workflow file (e.g., `.github/workflows/release.yml`) with the following content:

```yaml
name: Release

on:
  push:
    tags:
      - '[0-9]+.[0-9]+.[0-9]+'

jobs:
  build:
    uses: cloudsteak/cm-workflows/.github/workflows/production-build-push.yml@main
    with:
      image_name: "my-app"
      dockerfile_path: "./Dockerfile"      # optional, default: ./Dockerfile
      build_context: "."                   # optional, default: .
      platforms: "linux/amd64,linux/arm64" # optional, default: linux/amd64
```

#### Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `image_name` | Yes | - | Docker image name (will be pushed to `ghcr.io/<owner>/<image_name>`) |
| `dockerfile_path` | No | `./Dockerfile` | Path to the Dockerfile |
| `build_context` | No | `.` | Build context directory |
| `platforms` | No | `linux/amd64` | Target platforms (comma-separated) |

#### Permissions

This workflow requires the following permissions:
- `contents: read` - To checkout the repository
- `packages: write` - To push images to GitHub Container Registry

#### Image Tagging

Images are tagged with the semantic version from the Git tag:
- Tag: `1.0.0` → Image: `ghcr.io/<owner>/<image_name>:1.0.0`

#### Example

When you push a tag like `1.2.3` to your repository, the workflow will:
1. Validate that `1.2.3` is a valid semantic version
2. Build the Docker image from the specified Dockerfile
3. Push the image as `ghcr.io/<owner>/<image_name>:1.2.3`

## License

This project is open source and available for use.
