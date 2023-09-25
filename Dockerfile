FROM archlinux:latest

RUN pacman -Syu ruby --noconfirm && \
    gem install --no-document colorize

RUN mkdir /var/rinha
WORKDIR /var/rinha
COPY . .

ENTRYPOINT ["/var/rinha/rinha-de-compiler", "/var/rinha/source.rinha"]
