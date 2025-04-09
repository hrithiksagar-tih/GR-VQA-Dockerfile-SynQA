FROM nvcr.io/nvidia/pytorch:22.03-py3

# ========== Build Arguments ==========
ARG UID
ARG GID

# ========== Validate UID/GID ==========
RUN if [ -z "$UID" ] || [ -z "$GID" ]; then \
    echo "Error: UID and GID build arguments must be provided." >&2; \
    exit 1; \
    fi

# ========== Environment ==========
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# ========== Install Core Dependencies ==========
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
        keychain \
        openssh-client && \
    ln -fs /usr/share/zoneinfo/$TZ /etc/localtime && \
    dpkg-reconfigure --frontend noninteractive tzdata && \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        python3.11 \
        python3.11-venv \
        python3.11-dev \
        python3-pip && \
    rm -rf /var/lib/apt/lists/*

# ========== Set Python 3.11 as Default ==========
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 2 && \
    update-alternatives --set python3 /usr/bin/python3.11

ENV PATH="/usr/bin:$PATH"

RUN python3 --version

# ========== Add User ==========
RUN groupadd --gid "${GID}" hrithik_sagar && \
    useradd --uid "${UID}" --gid "${GID}" -m -s /bin/bash hrithik_sagar && \
    echo "hrithik_sagar:abcde1234" | chpasswd

# ========== Switch to User ==========
USER hrithik_sagar
WORKDIR /home/hrithik_sagar

# ========== SSH Setup for Git ==========
RUN mkdir -p ~/.ssh && \
    ssh-keyscan github.com >> ~/.ssh/known_hosts && \
    chmod 700 ~/.ssh

# ========== Add keychain to bashrc ==========
RUN echo 'eval $(keychain --eval --agents ssh ~/.ssh/id_rsa)' >> ~/.bashrc

# ========== Install Python Packages ==========
RUN pip install --upgrade pip && pip install \
    natsort==8.4.0 \
    numpy==2.2.4 \
    pandas==2.2.3 \
    Pillow==11.1.0 \
    protobuf==6.30.2 \
    psutil==7.0.0 \
    python-dotenv==1.1.0 \
    PyYAML==6.0.2 \
    scikit_learn==1.6.1 \
    torch==2.6.0 \
    tqdm==4.67.1 \
    transformers==4.50.3 \
    vllm==0.8.2 \
    beautifulsoup4 \
    IPython \
    sentence-transformers

# ========== Final Test ==========
RUN echo "Python version as user: $(python3 --version)"

CMD ["/bin/bash"]
