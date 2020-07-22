FROM pytorch/pytorch:1.5-cuda10.1-cudnn7-runtime

# WORKDIR /app

RUN apt-get update
RUN apt-get install libsndfile1 espeak python3-pip -y 
	# apt-get clean && \
	# rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy Source later to enable dependency caching
# WORKDIR /app

WORKDIR /
# RUN git clone https://github.com/samchim/TTS.git
# RUN git checkout sam
RUN mkdir TTS
COPY TTS /TTS/
WORKDIR /TTS/
# WORKDIR /TTS/
RUN pip3 install Jinja2==2.10.1
RUN pip3 install -r requirements.txt
RUN pip3 install numba==0.48

RUN mkdir -p /Oscar/
ADD Oscar/* /Oscar/

# CMD /bin/bash

# http://bugs.python.org/issue19846
# > At the moment, setting "LANG=C" on a Linux system *fundamentally breaks Python 3*, and that's not OK.
ENV LANG C.UTF-8

# RUN pwd > docker.log
WORKDIR /TTS/
CMD python3 train.py --config_path ../Oscar/config.json
