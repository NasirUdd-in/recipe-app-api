FROM python:3.9-alpine3.13
LABEL maintainer="nasiruddin.com"
ENV PYTHONUNBUFFERED 1

# Copy requirements file
COPY ./requirements.txt /tmp/requirements.txt
COPY ./requirements.dev.txt /tmp/requirements.dev.txt

# Copy the application code
COPY ./app /app

# Set working directory
WORKDIR /app

# Expose port
EXPOSE 8000

ARG DEV=false
# Create a virtual environment, install dependencies, and add a retry mechanism for pip installation
RUN set -eux; \
    python -m venv /py && \
    /py/bin/pip install --upgrade pip; \
    apk add --update --no-cache postgresql-client && \
    apk add --update --no-cache --virtual .tmp-build-deps \
        build-base postgresql-dev musl-dev && \
    for retry in 1 2 3 4 5; do \
        if /py/bin/pip install -r /tmp/requirements.txt; then \
            break; \
        fi; \
        echo "Retrying pip installation (attempt $retry)..."; \
    done; \
    if [ $DEV = "true" ]; \
        then /py/bin/pip install -r /tmp/requirements.dev.txt; \
    fi && \
    rm -rf /tmp; \
    apk del .tmp-build-deps && \
    adduser --disabled-password --no-create-home django-user

# Set the environment path
ENV PATH="/py/bin:$PATH"

# Switch to the non-root user
USER django-user
