ARG RUBY_VERSION=3.2
FROM ruby:${RUBY_VERSION}-bullseye

ENV DOCKER 1
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update -y && \
    apt-get install -y \
    elinks \
    ghostscript \
    libmagic-dev \
    pdftk \
    poppler-utils \
    postgresql-client \
    sendmail \
    tnef \
    unrtf \
    mutt

# Wait-for-it
RUN git clone https://github.com/vishnubob/wait-for-it.git /tmp/wait-for-it && \
    chmod +x /tmp/wait-for-it/wait-for-it.sh && \
    ln -s /tmp/wait-for-it/wait-for-it.sh /bin/wait-for-it

WORKDIR /alaveteli
RUN git config --global --add safe.directory /alaveteli

RUN gem update --system

EXPOSE 3000
CMD wait-for-it db:5432 --strict -- ./docker/entrypoint.sh
