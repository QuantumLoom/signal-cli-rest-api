FROM python:3.9-slim

# Create signal-cli user
ENV HOME /srv/signal
RUN addgroup --system --gid 1000 sgn && adduser --system --home $HOME --gid 1000 --uid 999 sgn

# Install java
RUN set -eux; \
    mkdir -p /usr/share/man/man1; \
    apt-get update; \
    apt-get install --no-install-recommends -y \
        ca-certificates \
        openjdk-17-jre-headless \
        wget \
        locales \
    ; \
    rm -rf /var/lib/apt/lists/*

RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen
ENV LANG en_US.UTF-8  
ENV LANGUAGE en_US:en  
ENV LC_ALL en_US.UTF-8

# Download & Install signal-cli
ENV SIGNAL_CLI_VERSION=0.11.11
RUN cd /tmp/ \
    && wget https://github.com/AsamK/signal-cli/releases/download/v"${SIGNAL_CLI_VERSION}"/signal-cli-"${SIGNAL_CLI_VERSION}-Linux".tar.gz \
    && tar xf signal-cli-"${SIGNAL_CLI_VERSION}-Linux".tar.gz -C /opt \
    && rm signal-cli-"${SIGNAL_CLI_VERSION}-Linux".tar.gz \
    && ln -sf /opt/signal-cli-"${SIGNAL_CLI_VERSION}"/bin/signal-cli /usr/bin/si\
gnal-cli

WORKDIR $HOME

# Copy poetry.lock* in case it doesn't exist in the repo
COPY --chown=sgn:sgn ./pyproject.toml ./poetry.lock* ./

# Install Poetry & disable virtualenv creation
RUN pip install --no-cache poetry && \
    poetry config virtualenvs.create false

RUN poetry install --no-root --only main && \
    rm -rf ~/.cache/{pip,pypoetry}

# Copy app
COPY --chown=sgn:sgn ./signal_cli_rest_api/ signal_cli_rest_api/

# Prepare mount point for signal-cli 
RUN mkdir -p $HOME/.local/share/signal-cli
RUN chown -R sgn:sgn $HOME/.local/share/signal-cli

EXPOSE 8000
USER sgn

CMD ["uvicorn", "signal_cli_rest_api.main:app", "--host", "0.0.0.0"]
