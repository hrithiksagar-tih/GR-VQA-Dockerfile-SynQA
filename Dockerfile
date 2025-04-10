FROM nvcr.io/nvidia/pytorch:22.03-py3

# Define build arguments
ARG UID
ARG GID

# Ensure UID and GID are provided
RUN if [ -z "$UID" ] || [ -z "$GID" ]; then \
    echo "Error: UID and GID build arguments must be provided." >&2; \
    exit 1; \
    fi

# Set timezone and disable interactive prompts
ENV DEBIAN_FRONTEND=noninteractive TZ=UTC

# 1) Install base packages (including keychain)

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ffmpeg \
        libsm6 \
        libxext6 \
        poppler-utils \
        git \
        sudo \
        vim \
        screen \
        software-properties-common \
        tzdata \
        fonts-noto \
        python3.8-venv \
        python3.8-dev \
        keychain && \
    ln -fs /usr/share/zoneinfo/$TZ /etc/localtime && \
    dpkg-reconfigure --frontend noninteractive tzdata && \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        python3.11 \
        python3.11-venv \
        python3.11-dev \
        python3-pip && \
    rm -rf /var/lib/apt/lists/*  # Cleanup

# 2) Set Python 3.11 as the default

RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 2 && \
    update-alternatives --set python3 /usr/bin/python3.11

ENV PATH="/usr/bin:$PATH"

# Verify Python version as root (should print Python 3.11.x)
RUN python3 --version

# 2b) Install PyTorch 2.6.0 (CUDA 12.1) and flashinfer
RUN python3 -m pip install --upgrade pip && \
    pip install torch==2.6.0 --index-url https://download.pytorch.org/whl/cu121 --extra-index-url https://pypi.org/simple && \
    pip install flashinfer

# 3) Create a group and user

# Create user, add to sudo group, and enable passwordless sudo
RUN groupadd --gid "${GID}" hrithik_sagar && \
    useradd --uid "${UID}" --gid "${GID}" -m -s /bin/bash -G sudo hrithik_sagar && \
    echo "hrithik_sagar:abcde1234" | chpasswd && \
    echo 'hrithik_sagar ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Switch to the new user
USER hrithik_sagar

# Create and set the working directory
WORKDIR /home/hrithik_sagar

# Verify Python version as the new user
RUN echo "Python version: $(python3 --version)"

# (Optional) Create or activate your Python virtual environment here
# Example:
# RUN python3 -m venv .venv && \
#     source .venv/bin/activate && \
#     pip install ...

CMD ["/bin/bash"]
