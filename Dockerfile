FROM archlinux:latest

RUN pacman -Syu ruby --noconfirm && \
    gem install --no-document colorize

COPY . .

ENTRYPOINT ["./rinha-de-compiler"]
