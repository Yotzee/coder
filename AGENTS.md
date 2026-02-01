# AGENTS.md — Coder Development Container

## Project Overview

This repository builds a comprehensive Ubuntu-based Docker development container
image with a web-based XFCE desktop (via noVNC). It is **not** an application
codebase — it is an infrastructure/DevOps project consisting of a Dockerfile,
a shell script, a VERSION file, and documentation.

Repository: `https://github.com/Yotzee/coder.git`
Branch: `master`

### File Inventory

| File           | Purpose                                              |
|----------------|------------------------------------------------------|
| `Dockerfile`   | Defines the Ubuntu-based dev container image         |
| `start-rdp.sh` | Bash startup script for web RDP (Xvfb/XFCE/noVNC)  |
| `VERSION`      | Semver version string (currently `1.0.0`)            |
| `README.md`    | User-facing documentation                            |
| `AGENTS.md`    | This file — instructions for AI coding agents        |

---

## Build Commands

There is no traditional build system (no Makefile, package.json, go.mod, etc.).
The only build artifact is the Docker image.

```bash
# Standard build
docker build -t coder-dev .

# Build with BuildKit (recommended — more efficient disk usage)
DOCKER_BUILDKIT=1 docker build -t coder-dev .
```

If the build fails with "not enough free space":
```bash
docker system prune -a --volumes
```

## Run Commands

```bash
# Web RDP (default) — access desktop at http://localhost:8080
docker run --rm -d -p 8080:8080 \
  -v $(pwd):/home/developer/workspace \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --name coder-dev coder-dev

# Shell only (no RDP)
docker run --rm -it coder-dev /bin/zsh
```

## Testing

There is **no test suite**. No unit tests, integration tests, or CI pipeline
exist. Validation is manual: build the image and verify tools work inside it.

```bash
# Quick smoke test after building
docker run --rm coder-dev bash -c \
  "node --version && dotnet --version && go version && terraform version && gcc --version"
```

## Linting

There are no linters configured for this repository. No ESLint, golangci-lint,
Prettier, ShellCheck, or hadolint configurations exist.

When modifying files, consider running:
```bash
# Dockerfile linting (if hadolint is available locally)
hadolint Dockerfile

# Shell script linting (if shellcheck is available locally)
shellcheck start-rdp.sh
```

---

## Code Style Guidelines

### Dockerfile Conventions

- **Base image**: `ubuntu:latest` — do not pin to a specific Ubuntu version
- **Layer cleanup**: Every `apt-get install` block MUST end with
  `rm -rf /var/lib/apt/lists/*` to reduce image size
- **Minimize layers**: Use `&&` to chain related commands in a single `RUN`
- **Use `--no-install-recommends`** for large package groups to reduce bloat
- **Comments**: Each `RUN` block should have a comment above it explaining
  what is being installed and why
- **Ordering**: Install tools in this order:
  1. Base dependencies (curl, wget, gnupg, ca-certificates)
  2. Core dev tools (git, vim, zsh)
  3. Language runtimes/SDKs (C++, Node.js, .NET, Go)
  4. Infrastructure tools (Terraform, Docker CLI, kubectl)
  5. Browser/testing tools (Chromium, chromedriver)
  6. Desktop environment (XFCE, VNC, noVNC)
  7. User setup and configuration
- **Non-root user**: The container runs as `developer`, not root. All user-space
  configuration (Oh My Zsh, shell rc files) happens after `USER developer`
- **ENV variables**: Set PATH additions via `ENV`, not in shell rc files

### Shell Script Conventions (start-rdp.sh)

- **Shebang**: Always use `#!/bin/bash`
- **Error handling**: Always include `set -e` immediately after the shebang
- **Comments**: Add an inline comment for each significant command
- **Background processes**: Use `&` for daemons, `wait` at the end to keep
  the container running
- **No hardcoded passwords**: VNC/noVNC runs without authentication by default
  (`-nopw` flag)

### VERSION File

- Contains a single semver string (e.g., `1.0.0`) with a trailing newline
- Bump according to semver: major for breaking changes to the container
  interface, minor for new tool additions, patch for version bumps of
  existing tools

### README.md Conventions

- Use H2 (`##`) for main sections
- Use fenced code blocks with `bash` language tag for all commands
- Bold tool names and important URLs
- Keep the structure: Overview → Tools → Building → Running → Notes

---

## Architecture Notes

### Container Runtime

- **User**: `developer` (non-root, UID assigned by `useradd`)
- **Shell**: Zsh with Oh My Zsh (robbyrussell theme, plugins: git, terraform, kubectl)
- **Working directory**: `/home/developer/workspace` (mount point for host code)
- **Default CMD**: `/usr/local/bin/start-rdp.sh` (web RDP on port 8080)
- **Exposed port**: 8080 (noVNC web interface)

### Web RDP Stack

`Xvfb` (virtual framebuffer at 1920x1080x24)
→ `XFCE4` (desktop environment)
→ `x11vnc` (VNC server on localhost:5900)
→ `noVNC` (WebSocket proxy on port 8080)

### Installed Tools (inside the container)

Node.js LTS, .NET SDK 8.0, GCC/G++, Clang/clang-format, Go 1.21.5,
Terraform (latest), Chromium + chromedriver, Docker CLI + Compose plugin,
kubectl (latest stable), Git, Vim, Zsh + Oh My Zsh.

### Docker Socket

The container does NOT run a Docker daemon. It expects the host Docker socket
to be mounted at `/var/run/docker.sock` for Docker CLI access.

---

## Common Tasks for Agents

### Adding a New Tool

1. Add a new `RUN` block in the Dockerfile in the correct section (see ordering above)
2. Include `rm -rf /var/lib/apt/lists/*` cleanup
3. Add a comment explaining what is being installed
4. Update the "Included Tools" list in README.md
5. Bump the minor version in the VERSION file

### Updating a Tool Version

1. Find the version string in the Dockerfile (e.g., `go1.21.5` or `dotnet-sdk-8.0`)
2. Replace with the new version
3. Update README.md if the version is mentioned there
4. Bump the patch version in the VERSION file

### Modifying the RDP Setup

Edit `start-rdp.sh`. The script must:
- Start Xvfb before any X11 clients
- Include sleep delays between service starts for initialization
- End with `wait` to keep the container process alive
