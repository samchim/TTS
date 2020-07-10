FROM pytorch/pytorch:1.0.1-cuda10.0-cudnn7-runtime

WORKDIR /srv/app

RUN apt-get update && \
	apt-get install -y libsndfile1 espeak && \
	apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy Source later to enable dependency caching
COPY requirements.txt /srv/app/
RUN pip install -r requirements.txt
RUN pip install numba==0.48

COPY . /srv/app

# http://bugs.python.org/issue19846
# > At the moment, setting "LANG=C" on a Linux system *fundamentally breaks Python 3*, and that's not OK.
ENV LANG C.UTF-8

WORKDIR /srv/
RUN mkdir TTS
RUN cp -r /srv/app/* /srv/TTS
RUN rm -R /srv/app
RUN cp /srv/TTS/zhy_* /usr/lib/x86_64-linux-gnu/espeak-data
RUN espeak --compile=zhy
WORKDIR /srv/

CMD /bin/bash
#CMD espeak -v zhy "你 好 "
#CMD python3 -m TTS.server.server
