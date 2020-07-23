FROM nvidia/cuda:10.1-runtime-ubuntu16.04

# WORKDIR /app

# apt-get
RUN apt-get update
RUN apt-get install libsndfile1 espeak python3-pip python-pip git curl -y 

# http://bugs.python.org/issue19846
# > At the moment, setting "LANG=C" on a Linux system *fundamentally breaks Python 3*, and that's not OK.
ENV LANG C.UTF-8

# set python 3.6
ENV PATH=/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates netbase && rm -rf /var/lib/apt/lists/*
ENV GPG_KEY=0D96DF4D4110E5C43FBFB17F2D347EA6AA65421D
ENV PYTHON_VERSION=3.6.11
RUN set -ex && savedAptMark="$(apt-mark showmanual)" && apt-get update && apt-get install -y --no-install-recommends dpkg-dev gcc libbluetooth-dev libbz2-dev libc6-dev libexpat1-dev libffi-dev libgdbm-dev liblzma-dev libncursesw5-dev libreadline-dev libsqlite3-dev libssl-dev make tk-dev wget xz-utils zlib1g-dev $(command -v gpg > /dev/null || echo 'gnupg dirmngr') && wget -O python.tar.xz "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz" && wget -O python.tar.xz.asc "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz.asc" && export GNUPGHOME="$(mktemp -d)" && gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$GPG_KEY" && gpg --batch --verify python.tar.xz.asc python.tar.xz && { command -v gpgconf > /dev/null && gpgconf --kill all || :; } && rm -rf "$GNUPGHOME" python.tar.xz.asc && mkdir -p /usr/src/python && tar -xJC /usr/src/python --strip-components=1 -f python.tar.xz && rm python.tar.xz && cd /usr/src/python && gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" && ./configure --build="$gnuArch" --enable-loadable-sqlite-extensions --enable-optimizations --enable-option-checking=fatal --enable-shared --with-system-expat --with-system-ffi --without-ensurepip && make -j "$(nproc)" LDFLAGS="-Wl,--strip-all" PROFILE_TASK='-m test.regrtest --pgo test_array test_base64 test_binascii test_binhex test_binop test_bytes test_c_locale_coercion test_class test_cmath test_codecs test_compile test_complex test_csv test_decimal test_dict test_float test_fstring test_hashlib test_io test_iter test_json test_long test_math test_memoryview test_pickle test_re test_set test_slice test_struct test_threading test_time test_traceback test_unicode ' && make install && ldconfig && apt-mark auto '.*' > /dev/null && apt-mark manual $savedAptMark && find /usr/local -type f -executable -not \( -name '*tkinter*' \) -exec ldd '{}' ';' | awk '/=>/ { print $(NF-1) }' | sort -u | xargs -r dpkg-query --search | cut -d: -f1 | sort -u | xargs -r apt-mark manual && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false && rm -rf /var/lib/apt/lists/* && find /usr/local -depth \( \( -type d -a \( -name test -o -name tests -o -name idle_test \) \) -o \( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \) -exec rm -rf '{}' + && rm -rf /usr/src/python && python3 --version
RUN cd /usr/local/bin && ln -s idle3 idle && ln -s pydoc3 pydoc && ln -s python3 python && ln -s python3-config python-config
ENV PYTHON_PIP_VERSION=20.1.1
ENV PYTHON_GET_PIP_URL=https://github.com/pypa/get-pip/raw/eff16c878c7fd6b688b9b4c4267695cf1a0bf01b/get-pip.py
ENV PYTHON_GET_PIP_SHA256=b3153ec0cf7b7bbf9556932aa37e4981c35dc2a2c501d70d91d2795aa532be79
RUN set -ex; savedAptMark="$(apt-mark showmanual)"; apt-get update; apt-get install -y --no-install-recommends wget; wget -O get-pip.py "$PYTHON_GET_PIP_URL"; echo "$PYTHON_GET_PIP_SHA256 *get-pip.py" | sha256sum --check --strict -; apt-mark auto '.*' > /dev/null; [ -z "$savedAptMark" ] || apt-mark manual $savedAptMark; apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; rm -rf /var/lib/apt/lists/*; python get-pip.py --disable-pip-version-check --no-cache-dir "pip==$PYTHON_PIP_VERSION" ; pip --version; find /usr/local -depth \( \( -type d -a \( -name test -o -name tests -o -name idle_test \) \) -o \( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \) -exec rm -rf '{}' +; rm -f get-pip.py

WORKDIR /
RUN git clone https://github.com/samchim/TTS.git
WORKDIR /TTS/
RUN git checkout sam
# RUN mkdir TTS
# COPY TTS /TTS/
# WORKDIR /TTS/
WORKDIR /TTS/
RUN pip3 install Jinja2==2.10.1
# CMD /bin/bash
# RUN pip3 install -r requirements.txt
RUN python3 setup.py install
RUN pip3 install numba==0.48

WORKDIR /TTS/
RUN git pull
WORKDIR /usr/lib/x86_64-linux-gnu/espeak-data
RUN cp /TTS/espeak_zhy/* .
RUN espeak --compile=zhy

ENV PYTHONPATH="/"

RUN mkdir -p /Oscar/
RUN mkdir -p /Oscar/wavs
ADD Oscar/wavs/* /Oscar/wavs/

ARG CACHEBUST=1
ADD Oscar/metadata_train.csv /Oscar/
ADD Oscar/metadata_val.csv /Oscar/
ADD Oscar/config.json /Oscar/

# # RUN pwd > docker.log
WORKDIR /TTS/
CMD git pull && python train.py --config_path ../Oscar/config.json
