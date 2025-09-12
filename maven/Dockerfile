FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Install base tools
RUN apt-get update && apt-get install -y \
    openjdk-11-jdk maven git ssh openssh-client openssh-server \
    sudo curl unzip zip nano ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Create user 'alessio' with home dir
RUN useradd -ms /bin/bash alessio && echo "alessio:onos" | chpasswd

# passwordless sudo privileges
RUN usermod -aG sudo alessio && \
    echo "alessio ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/alessio && \
    chmod 0440 /etc/sudoers.d/alessio

# Prepare SSH server for IntelliJ remote development
RUN mkdir /var/run/sshd
EXPOSE 22

# --- Detect architecture and set JAVA_HOME accordingly ---
# This runs at build time and writes a persistent shell profile file
RUN arch=$(dpkg --print-architecture) && \
    if [ "$arch" = "arm64" ]; then \
    echo "export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-arm64" >> /etc/profile.d/java_home.sh; \
    else \
    echo "export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64" >> /etc/profile.d/java_home.sh; \
    fi && \
    echo 'export PATH=$PATH:$JAVA_HOME/bin' >> /etc/profile.d/java_home.sh

# Make sure the file is executable
RUN chmod +x /etc/profile.d/java_home.sh

USER alessio
WORKDIR /home/alessio/work

# Source profile.d by default in bash shells
SHELL ["/bin/bash", "-c"]