FROM ubuntu:24.04

ENV POSTGRES_VERSION=16.6
ENV PGDATA=/var/lib/postgresql/data
ENV LANG=en_US.utf8

# Build arguments for PostgreSQL admin credentials
ARG POSTGRES_ADMIN_USER
ARG POSTGRES_ADMIN_PASSWORD
ARG POSTGRES_DB

# Environment variables for PostgreSQL admin credentials
ENV POSTGRES_ADMIN_USER=${POSTGRES_ADMIN_USER:-"admin"}
ENV POSTGRES_ADMIN_PASSWORD=${POSTGRES_ADMIN_PASSWORD:-"securepassword123"}
ENV POSTGRES_DB=${POSTGRES_DB:-"app_db"}

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    wget curl gnupg git build-essential \
    libreadline-dev zlib1g-dev flex bison libxml2-dev \
    libxslt1-dev libssl-dev libpam0g-dev libedit-dev \
    locales ca-certificates && \
    locale-gen en_US.UTF-8

RUN useradd -ms /bin/bash postgres

WORKDIR /usr/src

RUN wget https://ftp.postgresql.org/pub/source/v${POSTGRES_VERSION}/postgresql-${POSTGRES_VERSION}.tar.gz && \
    tar -xzf postgresql-${POSTGRES_VERSION}.tar.gz && \
    cd postgresql-${POSTGRES_VERSION} && \
    ./configure --prefix=/usr/local/pgsql --without-icu && \
    make -j$(nproc) && \
    make install

ENV PATH="/usr/local/pgsql/bin:$PATH"

RUN mkdir -p /var/lib/postgresql/data && chown -R postgres:postgres /var/lib/postgresql

RUN git clone https://github.com/pgvector/pgvector.git && \
    cd pgvector && \
    make && make install

RUN git clone https://github.com/apache/age.git && \
    cd age && \
    make PG_CONFIG=/usr/local/pgsql/bin/pg_config && \
    make install

USER postgres

RUN /usr/local/pgsql/bin/initdb -D $PGDATA

COPY --chown=postgres:postgres ./init-extensions.sh /init-extensions.sh
RUN chmod +x /init-extensions.sh && /init-extensions.sh

EXPOSE 5432

CMD ["postgres", "-D", "/var/lib/postgresql/data", "-h", "0.0.0.0"]
