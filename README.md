# rinha-de-compiler

Compiler built using [Odin](https://odin-lang.org/)

## Build

`docker build --tag rinha .`

## Run

`docker run -v ./source.rinha:/var/rinha/source.rinha --memory=2gb --cpus=2 rinha`
