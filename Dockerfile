FROM ubuntu:latest

# Set environment variables to avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Update package list and install basic dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    gnupg \
    ca-certificates \
    software-properties-common \
    apt-transport-https \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# Install Git and vim
RUN apt-get update && apt-get install -y \
    git \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Install Zsh and Oh My Zsh dependencies
RUN apt-get update && apt-get install -y \
    zsh \
    && rm -rf /var/lib/apt/lists/*

# Install C++ compilers (gcc and clang) - split into smaller steps to save space
RUN apt-get clean && \
    rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    apt-get update && \
    apt-get install -y --no-install-recommends gcc g++ make binutils && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* /tmp/* /var/tmp/* && \
    apt-get update && \
    apt-get install -y --no-install-recommends clang clang-format && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* /tmp/* /var/tmp/*

# Install Node.js (using NodeSource repository for latest LTS)
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install .NET SDK
RUN wget https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb -O packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && rm packages-microsoft-prod.deb \
    && apt-get clean && \
    rm -rf /var/cache/apt/archives/* && \
    apt-get update \
    && apt-get install -y dotnet-sdk-8.0 \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Install Go
RUN wget -O go.tar.gz https://go.dev/dl/go1.21.5.linux-amd64.tar.gz \
    && tar -C /usr/local -xzf go.tar.gz \
    && rm go.tar.gz

# Install Terraform
RUN wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list \
    && apt-get update \
    && apt-get install -y terraform \
    && rm -rf /var/lib/apt/lists/*

# Install Chromium and dependencies
RUN apt-get clean && \
    rm -rf /var/cache/apt/archives/* && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    chromium-browser \
    chromium-chromedriver \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Install Ghostty terminal emulator (community .deb from mkasberg/ghostty-ubuntu)
RUN GHOSTTY_VERSION="1.2.3-0.ppa1" && \
    ARCH=$(dpkg --print-architecture) && \
    wget -O /tmp/ghostty.deb "https://github.com/mkasberg/ghostty-ubuntu/releases/download/1.2.3-0-ppa1/ghostty_${GHOSTTY_VERSION}_${ARCH}_24.04.deb" && \
    apt-get update && \
    apt-get install -y /tmp/ghostty.deb && \
    rm -f /tmp/ghostty.deb && \
    rm -rf /var/lib/apt/lists/*

# Install Docker CLI only (no daemon - connect to external Docker daemon via socket mount)
# Usage: docker run -v /var/run/docker.sock:/var/run/docker.sock ...
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y docker-ce-cli docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/*

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && chmod +x kubectl \
    && mv kubectl /usr/local/bin/kubectl

# Set up environment variables
ENV PATH="/usr/local/go/bin:${PATH}"
ENV GOPATH="/go"
ENV PATH="${GOPATH}/bin:${PATH}"

# Install desktop environment, VNC, and noVNC for web-based RDP
# Using --no-install-recommends to reduce package size
RUN apt-get clean && \
    rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/* && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    xfce4 \
    xfce4-goodies \
    x11vnc \
    xvfb \
    dbus-x11 \
    python3 \
    python3-pip \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* && \
    cd /tmp && \
    git clone --depth 1 https://github.com/novnc/noVNC.git /opt/noVNC && \
    git clone --depth 1 https://github.com/novnc/websockify.git /opt/websockify && \
    cd /opt/websockify && pip3 install --no-cache-dir --break-system-packages . && \
    rm -rf /tmp/* /root/.cache

# Install sudo and create a non-root user for development with zsh as default shell
RUN apt-get update && apt-get install -y sudo \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -m -s /bin/zsh developer \
    && echo 'developer ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
    && mkdir -p /go /home/developer/workspace \
    && chown -R developer:developer /go /home/developer /opt/noVNC

# Copy and set up startup script for web RDP
COPY start-rdp.sh /usr/local/bin/start-rdp.sh
RUN chmod +x /usr/local/bin/start-rdp.sh

# Install Visual Studio Code via Microsoft APT repository
RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/packages.microsoft.gpg && \
    install -D -o root -g root -m 644 /tmp/packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list && \
    rm -f /tmp/packages.microsoft.gpg && \
    apt-get update && \
    apt-get install -y code && \
    rm -rf /var/lib/apt/lists/*

# Install opencode-ai (AI coding agent for the terminal)
RUN npm install -g opencode-ai

# Expose port 8080 for web RDP
EXPOSE 8080

# Switch to developer user
USER developer
WORKDIR /home/developer

# Install Oh My Zsh with robbyrussell theme and plugins
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended \
    && sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="robbyrussell"/' ~/.zshrc || echo 'ZSH_THEME="robbyrussell"' >> ~/.zshrc \
    && sed -i 's/^plugins=(.*)/plugins=(git terraform kubectl)/' ~/.zshrc || echo 'plugins=(git terraform kubectl)' >> ~/.zshrc \
    && echo 'alias k=kubectl' >> ~/.zshrc

# Create auth directories for AI coding tools (mount from host to persist auth)
RUN mkdir -p /home/developer/.claude /home/developer/.config/opencode

VOLUME ["/home/developer/.claude", "/home/developer/.config/opencode"]

WORKDIR /home/developer/workspace

# Set default shell to zsh for all RUN commands
SHELL ["/bin/zsh", "-c"]

# Default command - start web RDP on port 8080
CMD ["/usr/local/bin/start-rdp.sh"]

