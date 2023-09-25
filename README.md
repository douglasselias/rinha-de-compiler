# rinha-de-compiler

Compiler built using [Odin](https://odin-lang.org/)

## Setup

Add the files you wish to run inside the `tests` directory __before__ building the image

## Build

`docker build --tag rinha .`

## Run

`docker run -it rinha examples/fib.rinha`

`docker run -it rinha tests/your_file.rinha`