just:
  rm -f source.rinha
  docker build --tag rinha .
  cp examples/fib.rinha ./
  mv fib.rinha source.rinha
  docker run -v ./source.rinha:/var/rinha/source.rinha --memory=2gb --cpus=2 rinha