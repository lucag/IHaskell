FROM ubuntu:16.04

# Install all necessary Ubuntu packages
RUN \
    # Install stack from the FPComplete repositories. 
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 575159689BEFB442 \
    && echo 'deb http://download.fpcomplete.com/ubuntu trusty main' > /etc/apt/sources.list.d/fpco.list \
    && apt-get update \
    && apt-get install -y python3 python3-dev python3-setuptools libmagic-dev libtinfo-dev \
                          libzmq3-dev libcairo2-dev libpango1.0-dev libblas-dev \
                          liblapack-dev gcc g++ git stack \
    && stack upgrade \
    \ 
    # Install Jupyter notebook 
    && easy_install3 -U pip \
    && pip3 install -U jupyter \
    && git clone https://github.com/jupyter/jupyter-drive \
    && pip3 install -e jupyter-drive \
    \
    && useradd -c "IHaskell User" -m ihaskell \
    && usermod -L ihaskell

WORKDIR /home/ihaskell

# Install dependencies for IHaskell
COPY  ihaskell.cabal   ihaskell.cabal
COPY  ipython-kernel   ipython-kernel
COPY  ghc-parser       ghc-parser
COPY  ihaskell-display ihaskell-display

# Install IHaskell itself. Don't just COPY . so that
# changes in e.g. README.md don't trigger rebuild.
COPY  src              src
COPY  html             html
COPY  main             main
COPY  LICENSE          LICENSE

ENV PATH /home/ihaskell/.stack/bin:/usr/bin:/bin

# Set up stack
#COPY stack.yaml stack.yaml
COPY  stack-full.yaml stack.yaml

RUN   chown -R ihaskell:ihaskell /home/ihaskell 

# Switch to the new user
USER  ihaskell

RUN   stack setup \
      #&& stack build --only-snapshot \
      #&& stack build \
      && stack install \
      \
      # Run the notebook 
      && mkdir /home/ihaskell/notebooks \
      && ihaskell install \
      && python3 -m jupyterdrive --mixed

EXPOSE 8888

ENTRYPOINT stack exec -- \
           jupyter notebook --NotebookApp.port=8888 \
                           '--NotebookApp.ip=*'\
                            --NotebookApp.notebook_dir=/home/ihaskell/notebooks 
