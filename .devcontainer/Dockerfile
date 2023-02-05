# FROM golang:buster as builder

# ARG USER=worker
# ARG USER_UID=1000
# ARG USER_GID=1000

# RUN apt-get update; apt-get install -y git
# RUN groupadd -g ${USER_GID} ${USER}; \
#     useradd -m -s /bin/bash -g ${USER_GID} -u ${USER_UID} -G sudo ${USER}
# USER ${USER}
# RUN go install -tags extended github.com/gohugoio/hugo@latest

FROM ubuntu:22.04

ARG USER=worker
ARG USER_UID=1000
ARG USER_GID=1000

RUN apt-get update; apt-get install -y  sudo git
COPY --from=klakegg/hugo /bin/hugo /usr/local/bin/
COPY --from=klakegg/hugo /bin/hugo-official /usr/local/bin/
COPY --from=klakegg/hugo /usr/lib/hugo /usr/lib/hugo
RUN groupadd -g ${USER_GID} ${USER}; \
    useradd -m -s /bin/bash -g ${USER_GID} -u ${USER_UID} -G sudo ${USER}
RUN echo "${USER} ALL = (ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USER}; \
    chmod 400  /etc/sudoers.d/${USER}
RUN mkdir /workspace; chown ${USER}:${USER} /workspace
WORKDIR /workspace
USER ${USER}
ENV PATH=/home/${USER}/go/bin:$PATH
