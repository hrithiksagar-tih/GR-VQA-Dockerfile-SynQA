FROM nvcr.io/nvidia/pytorch:24.03-py3

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

# Verify Python version as root
RUN python3 --version

# 3) Create a group and user
RUN groupadd --gid "${GID}" hrithik_sagar && \
    useradd --uid "${UID}" --gid "${GID}" -m -s /bin/bash -G sudo hrithik_sagar && \
    echo "hrithik_sagar:abcde1234" | chpasswd && \
    echo 'hrithik_sagar ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Switch to the new user
USER hrithik_sagar

# Create and set the working directory
WORKDIR /home/hrithik_sagar

# 4) Set up Python virtual environment and install dependencies
RUN python3 -m venv .venv && \
    . .venv/bin/activate && \
    pip install --upgrade pip && \
    pip install packaging ninja && \
    pip install torch && \
    pip install flash-attn --no-build-isolation && \
    pip install vllm --pre --extra-index-url https://wheels.vllm.ai/nightly

# Set environment variable to enforce FlashAttention usage
ENV VLLM_ATTENTION_BACKEND=FLASH_ATTN

CMD ["/bin/bash"]
