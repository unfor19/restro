FROM python:3.9-slim as base
ENV \
  PYTHONUNBUFFERED=1 \
  PYTHONDONTWRITEBYTECODE=1

RUN apt-get update && apt-get install -y gcc

FROM base as app
RUN python -m pip install -U pip setuptools build wheel

WORKDIR /app
COPY requirements.txt /app/requirements.txt
RUN python -m pip install -r requirements.txt

COPY . .

EXPOSE 8000

ARG PACKAGE_VERSION="1.0.0"
ENV PACKAGE_VERSION=${PACKAGE_VERSION}

ENTRYPOINT [ "python", "-m" ]
CMD [ "gunicorn", "--bind", "0.0.0.0:8000", "app:app"]
