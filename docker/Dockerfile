FROM ruby:2.6-stretch

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
    python-dev \
    sendmail \
    tnef \
    unrtf \
    mutt

# PyYAML
RUN curl https://bootstrap.pypa.io/pip/2.7/get-pip.py -o /tmp/get-pip.py && \
    python /tmp/get-pip.py && \
    pip install pyyaml==3.13

# Wait-for-it
RUN git clone https://github.com/vishnubob/wait-for-it.git /tmp/wait-for-it && \
    chmod +x /tmp/wait-for-it/wait-for-it.sh && \
    ln -s /tmp/wait-for-it/wait-for-it.sh /bin/wait-for-it

WORKDIR /alaveteli/

EXPOSE 3000
CMD wait-for-it db:5432 --strict -- ./docker/entrypoint.sh
