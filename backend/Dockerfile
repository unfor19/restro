
ARG PYTHON_VERSION=3.9
FROM python:${PYTHON_VERSION}-alpine as base

ENV PYTHONUNBUFFERED=1 \
  PYTHONDONTWRITEBYTECODE=1



FROM base as build
RUN apk add --no-cache \
  gcc \
  musl-dev \
  libffi-dev
RUN python -m pip install -U pip setuptools wheel
WORKDIR /app
COPY requirements.txt .
RUN python -m pip install --no-cache-dir -r requirements.txt



FROM base as final
ARG PYTHON_VERSION
# Install runtime dependencies
COPY --from=build /usr/local/lib/python${PYTHON_VERSION}/site-packages /usr/local/lib/python${PYTHON_VERSION}/site-packages
COPY --from=build /usr/local/bin /usr/local/bin

# Set the working directory
WORKDIR /app

# Copy the application code
COPY . .

# Expose the application port
EXPOSE 8000

ARG PACKAGE_VERSION="1.0.0"
ENV PACKAGE_VERSION=${PACKAGE_VERSION}

# Define the entrypoint
ENTRYPOINT ["gunicorn", "--bind", "0.0.0.0:8000", "app:app"]
