FROM golang:buster

ARG USER=worker
ARG USER_UID=1000
ARG USER_GID=1000

RUN apt-get update; apt-get install -y  sudo git
RUN groupadd -g ${USER_GID} ${USER}; \
    useradd -m -s /bin/bash -g ${USER_GID} -u ${USER_UID} -G sudo ${USER}
RUN echo "${USER} ALL = (ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USER}; \
    chmod 400  /etc/sudoers.d/${USER}
RUN mkdir /workspace; chown ${USER}:${USER} /workspace
WORKDIR /workspace
USER ${USER}
RUN go install -tags extended github.com/gohugoio/hugo@latest
ENV PATH=/home/${USER}/go/bin:$PATH
EXPOSE 1313
