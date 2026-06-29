ARG BASE_IMAGE=ubuntu:22.04
FROM ${BASE_IMAGE}

# ── System dependencies ───────────────────────────────────────────────────────
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
        python3.11 python3.11-venv python3-pip \
        ffmpeg \
        libsndfile1 \
        wget curl git \
        fonts-urw-base35 \
        zstd \
    && rm -rf /var/lib/apt/lists/*

# ── Python alias ─────────────────────────────────────────────────────────────
RUN ln -sf /usr/bin/python3.11 /usr/local/bin/python && \
    ln -sf /usr/bin/pip3 /usr/local/bin/pip

# ── Piper TTS ─────────────────────────────────────────────────────────────────
ARG PIPER_VERSION=2023.11.14-2
RUN wget -q "https://github.com/rhasspy/piper/releases/download/${PIPER_VERSION}/piper_linux_x86_64.tar.gz" \
        -O /tmp/piper.tar.gz \
    && tar -xzf /tmp/piper.tar.gz -C /usr/local/bin \
    && rm /tmp/piper.tar.gz \
    && chmod +x /usr/local/bin/piper

# ── Ollama ────────────────────────────────────────────────────────────────────
RUN curl -fsSL https://ollama.ai/install.sh | sh

WORKDIR /app

# ── PyTorch ───────────────────────────────────────────────────────────────────
# CPU by default; GPU build overrides TORCH_INDEX_URL via docker-compose.gpu.yml
ARG TORCH_INDEX_URL=https://download.pytorch.org/whl/cpu
RUN pip install --no-cache-dir \
        torch torchvision torchaudio \
        --index-url ${TORCH_INDEX_URL}

# ── Audiocraft (install without deps to skip the torchtext==0.16.0 pin) ──────
RUN pip install --no-cache-dir --no-deps audiocraft>=1.3.0

# ── Remaining Python dependencies ─────────────────────────────────────────────
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# ── App code ──────────────────────────────────────────────────────────────────
COPY . .

# ── Create output directories ─────────────────────────────────────────────────
RUN mkdir -p outputs/{scripts,audio,music,images,videos,subtitles} \
             models/piper credentials

# ── Ports ─────────────────────────────────────────────────────────────────────
EXPOSE 7860
# Gradio UI
EXPOSE 11434
# Ollama API

# ── Entrypoint ────────────────────────────────────────────────────────────────
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["--host", "0.0.0.0", "--port", "7860"]
