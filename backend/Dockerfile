FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    MODEL_CACHE_DIR=/app/models

WORKDIR /app

COPY requirements.txt constraints.txt ./
# constraints.txt pins every package exactly, so a rebuild cannot change the vectors or memory use
RUN pip install --no-cache-dir -r requirements.txt -c constraints.txt

COPY app ./app
COPY scripts ./scripts

# Download all-MiniLM-L6-v2 at build time so the server never downloads it at run time.
RUN python -m app.embeddings --warm /app/models

EXPOSE 8000
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
