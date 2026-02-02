FROM archlinux/archlinux:latest AS base

# Update package database and install base dependencies
RUN pacman -Syu --noconfirm --needed \
    ca-certificates \
    curl \
    wget \
    gnupg \
    base-devel \
    man-db \
    man-pages \
    sudo \
    shadow \
    unzip \
    xz \
    && rm -rf /var/cache/pacman/pkg/*

FROM base AS core-tools

# Install core dev tools
RUN pacman -S --noconfirm --needed \
    git \
    vim \
    zsh \
    && rm -rf /var/cache/pacman/pkg/*

FROM core-tools AS compilers

# Install C/C++ toolchains
RUN pacman -S --noconfirm --needed \
    gcc \
    clang \
    make \
    binutils \
    && rm -rf /var/cache/pacman/pkg/*

FROM compilers AS runtimes

# Install language runtimes
RUN pacman -S --noconfirm --needed \
    nodejs \
    npm \
    go \
    && rm -rf /var/cache/pacman/pkg/*

FROM runtimes AS tooling

# Install infrastructure tools
RUN pacman -S --noconfirm --needed \
    terraform \
    docker \
    docker-compose \
    kubectl \
    && rm -rf /var/cache/pacman/pkg/*

FROM tooling AS desktop

# Install desktop environment, VNC, and noVNC for web-based RDP
RUN pacman -S --noconfirm --needed \
    $(pacman -Sgq xfce4) \
    $(pacman -Sgq xfce4-goodies) \
    x11vnc \
    xorg-server-xvfb \
    dbus \
    python \
    && rm -rf /var/cache/pacman/pkg/* \
    && git clone --depth 1 https://github.com/novnc/noVNC.git /opt/noVNC \
    && git clone --depth 1 https://github.com/novnc/websockify.git /opt/websockify \
    && rm -rf /root/.cache

FROM desktop AS final

# Set up non-root user for development with zsh as default shell
RUN useradd -m -s /bin/zsh developer \
    && echo 'developer ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
    && mkdir -p /go /home/developer/workspace \
    && chown -R developer:developer /go /home/developer /opt/noVNC

# Copy and set up startup script for web RDP
COPY start-rdp.sh /usr/local/bin/start-rdp.sh
RUN chmod +x /usr/local/bin/start-rdp.sh

# Install Visual Studio Code
RUN pacman -S --noconfirm --needed code \
    && rm -rf /var/cache/pacman/pkg/*

# Install AI coding agents
RUN npm install -g @anthropic-ai/claude-code opencode-ai @openai/codex

# Expose port 8080 for web RDP
EXPOSE 8080

# Switch to developer user
USER developer
WORKDIR /home/developer

# Create desktop shortcuts
RUN <<'EOF'
mkdir -p /home/developer/Desktop
cat > /home/developer/Desktop/vscode.desktop <<'EOT'
[Desktop Entry]
Type=Application
Name=Visual Studio Code
Exec=code
Icon=code
Terminal=false
Categories=Development;IDE;
EOT
chmod +x /home/developer/Desktop/*.desktop
EOF

# Install Oh My Zsh with robbyrussell theme and plugins
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended \
    && sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="robbyrussell"/' ~/.zshrc || echo 'ZSH_THEME="robbyrussell"' >> ~/.zshrc \
    && sed -i 's/^plugins=(.*)/plugins=(git terraform kubectl)/' ~/.zshrc || echo 'plugins=(git terraform kubectl)' >> ~/.zshrc \
    && echo 'alias k=kubectl' >> ~/.zshrc

WORKDIR /home/developer/workspace

# Set default shell to zsh for all RUN commands
SHELL ["/bin/zsh", "-c"]

# Default command - start web RDP on port 8080
CMD ["/usr/local/bin/start-rdp.sh"]
