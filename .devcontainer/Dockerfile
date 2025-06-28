# FROM golang:buster as builder

# ARG USER=worker
# ARG USER_UID=1000
# ARG USER_GID=1000

# RUN apt-get update; apt-get install -y git
# RUN groupadd -g ${USER_GID} ${USER}; \
#     useradd -m -s /bin/bash -g ${USER_GID} -u ${USER_UID} -G sudo ${USER}
# USER ${USER}
# RUN go install -tags extended github.com/gohugoio/hugo@latest

FROM ubuntu:24.04

ARG USER=worker
ARG USER_UID=1000
ARG USER_GID=1000
RUN apt-get update; apt-get install -y  sudo git
ARG DEBCONF_FRONTEND=noninteractive
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get install -y locales; \
    echo "ja_JP.UTF-8 UTF-8" >> /etc/locale.gen; \
    locale-gen ja_JP.UTF-8
ENV LC_ALL=ja_JP.UTF-8
ENV TZ=JST
RUN ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime; \
    echo 'Asia/Tokyo' > /etc/timezone; \
    apt-get install -y tzdata; \
    dpkg-reconfigure tzdata

COPY --from=klakegg/hugo /bin/hugo /usr/local/bin/
COPY --from=klakegg/hugo /bin/hugo-official /usr/local/bin/
COPY --from=klakegg/hugo /usr/lib/hugo /usr/lib/hugo
RUN if id -u 1000 >/dev/null 2>&1; then \
    userdel -r -f $(getent passwd 1000 | cut -d: -f1); \
    fi; \
    if getent group 1000 >/dev/null 2>&1; then \
    groupdel $(getent group 1000 | cut -d: -f1); \
    fi
RUN groupadd -g ${USER_GID} ${USER}; \
    useradd -m -s /bin/bash -g ${USER_GID} -u ${USER_UID} -G sudo ${USER}
RUN echo "${USER} ALL = (ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USER}; \
    chmod 400  /etc/sudoers.d/${USER}
RUN mkdir /workspace; chown ${USER}:${USER} /workspace
WORKDIR /workspace
USER ${USER}
ENV PATH=/home/${USER}/go/bin:$PATH
