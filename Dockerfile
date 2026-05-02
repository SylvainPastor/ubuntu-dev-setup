# Dockerfile — Clean Ubuntu 24.04 to test the dev-setup installation.
#
# Image is intentionally minimal: bootstrap.sh must install the rest
# itself. If we pre-installed packages here, we'd hide bugs in the
# script.
#
# Build: docker build -t dev-setup-test:ubuntu-24.04 .
# Run  : docker run --rm -it dev-setup-test:ubuntu-24.04 ./bootstrap.sh

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# Minimum prerequisites for bootstrap.sh to start:
#   - sudo            : used by every script for apt-get
#   - ca-certificates : for HTTPS downloads (curl, git)
#   - locales         : 01-shell and 07/08 generate locales
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        sudo \
        ca-certificates \
        locales \
    && rm -rf /var/lib/apt/lists/*

# Configure passwordless sudo for the `ubuntu` user (already present in
# the official ubuntu:24.04 image). The 90- prefix ensures this file is
# read after others, and `visudo -cf` validates the syntax at build time.
RUN usermod -aG sudo ubuntu \
    && echo 'ubuntu ALL=(ALL:ALL) NOPASSWD: ALL' > /etc/sudoers.d/90-ubuntu-nopasswd \
    && chmod 0440 /etc/sudoers.d/90-ubuntu-nopasswd \
    && visudo -cf /etc/sudoers.d/90-ubuntu-nopasswd

# The ubuntu:24.04 image already provides a `ubuntu` user (UID 1000).
USER ubuntu
WORKDIR /home/ubuntu/dev-setup

# Copy only what's needed (see .dockerignore).
COPY --chown=ubuntu:ubuntu bootstrap.sh ./
COPY --chown=ubuntu:ubuntu lib/         ./lib/
COPY --chown=ubuntu:ubuntu topics/      ./topics/

# In case executable bits weren't preserved during COPY.
RUN find . -name '*.sh' -exec chmod +x {} +

CMD ["bash"]
