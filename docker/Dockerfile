FROM ruby:2.7.8-bullseye

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

WORKDIR /alaveteli/

RUN gem update --system
RUN gem install sqlite3 -v 1.4.2
RUN gem install net-imap -v 0.3.8
RUN gem install mailcatcher -v 0.8.0 --conservative

EXPOSE 3000
EXPOSE 1080
CMD wait-for-it db:5432 --strict -- ./docker/entrypoint.sh
