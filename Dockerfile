FROM ubuntu:20.04

ENV TZ=Etc/UTC
ENV DEBIAN_FRONTEND=noninteractive

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN echo 'keyboard-configuration keyboard-configuration/layoutcode string us' | debconf-set-selections && \
    echo 'keyboard-configuration keyboard-configuration/modelcode string pc105' | debconf-set-selections

RUN apt-get -y update && \
    apt-get -y install tar curl gnupg sudo wget && \
    rm -rf /var/lib/apt/lists/*

# 1. Installera Node 16
RUN curl -sL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs

# 2. FIXEN: Förhindra byggscriptet från att försöka köra 'apt-get install npm'
# Vi skapar en tom länk så att apt tror att paketet redan är hanterat (eller inte behövs)
RUN apt-mark hold nodejs

# 3. Installera pkg globalt OCH ladda ner den gamla into-stream separat
RUN npm install -g @yao-pkg/pkg@5.11.1

# 2. Installera BARA CMake 3.30.0 (Vi använder -sf för säkerhets skull)
RUN wget https://github.com/Kitware/CMake/releases/download/v3.30.0/cmake-3.30.0-linux-x86_64.tar.gz && \
    tar -xzf cmake-3.30.0-linux-x86_64.tar.gz -C /opt && \
    ln -sf /opt/cmake-3.30.0-linux-x86_64/bin/cmake /usr/local/bin/cmake && \
    ln -sf /opt/cmake-3.30.0-linux-x86_64/bin/ctest /usr/local/bin/ctest && \
    rm cmake-3.30.0-linux-x86_64.tar.gz

RUN update-alternatives --install /usr/bin/cmake cmake /usr/local/bin/cmake 10 --force

ADD . /build_tools
WORKDIR /build_tools

RUN mkdir -p /opt/python3 && \
    wget -P /opt/python3/ https://github.com/ONLYOFFICE-data/build_tools_data/raw/refs/heads/master/python/python3.tar.gz && \
    tar -xzf /opt/python3/python3.tar.gz -C /opt/python3 --strip-components=1

# Viktigt: Vi håller kvar PATH men vi kommer köra 'rm node' i vårt kör-skript sen
ENV PATH="/opt/python3/bin:${PATH}"
RUN ln -s /opt/python3/bin/python3.10 /usr/bin/python

CMD ["sh", "-c", "cd tools/linux && python3 ./automate.py"]
