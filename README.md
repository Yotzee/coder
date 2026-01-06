# Coder Development Container

A comprehensive Ubuntu-based Docker development environment with all the essential tools for modern software development.

## Included Tools

- **Node.js** (LTS)
- **.NET SDK 8.0**
- **C++ Compilers** (gcc, g++, clang, clang-format)
- **Go** (1.21.5)
- **Terraform**
- **Chromium** browser and chromedriver
- **Docker CLI** (connects to external Docker daemon)
- **kubectl**
- **Git**
- **Zsh** with Oh My Zsh (robbyrussell theme)

## Building the Image

```bash
docker build -t coder-dev .
```

## Running the Container

### Basic Usage

```bash
docker run --rm -it coder-dev
```

### With Volume Mount (Recommended)

Mount your local workspace into the container:

```bash
docker run --rm -it -v $(pwd):/home/developer/workspace coder-dev
```

### With Docker Socket (for Docker CLI)

To use Docker commands inside the container (connects to host Docker daemon):

```bash
docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock coder-dev
```

### Complete Setup (Volume + Docker Socket)

```bash
docker run --rm -it \
  -v $(pwd):/home/developer/workspace \
  -v /var/run/docker.sock:/var/run/docker.sock \
  coder-dev
```

### With Port Forwarding

If you need to expose ports (e.g., for web development):

```bash
docker run --rm -it -p 3000:3000 -p 8080:8080 \
  -v $(pwd):/home/developer/workspace \
  coder-dev
```

### Detached Mode (Background)

Run container in detached mode (use `docker exec` to access):

```bash
docker run --rm -d --name coder-dev \
  -v $(pwd):/home/developer/workspace \
  -v /var/run/docker.sock:/var/run/docker.sock \
  coder-dev

# Access the container
docker exec -it coder-dev /bin/zsh
```

## Quick Commands

### Verify Installed Tools

```bash
node --version
dotnet --version
go version
terraform version
docker --version
kubectl version --client
gcc --version
clang --version
```

### Access Container Shell

The container starts with zsh by default. You can also access it with:

```bash
docker exec -it <container-id> /bin/zsh
```

## Notes

- The container runs as a non-root user (`developer`)
- Default working directory: `/home/developer/workspace`
- Docker CLI connects to the host's Docker daemon (no Docker daemon runs inside the container)
- All tools are installed system-wide and available in PATH


