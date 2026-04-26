FROM python:3.12-slim

RUN pip install --no-cache-dir cloudflare

WORKDIR /app
COPY ddns/cloudflare-api.py .

CMD ["python", "cloudflare-api.py"]
