FROM alpine:latest

ARG USER=worker
ARG USER_UID=1000
ARG USER_GID=1000

RUN apk add --no-cache sudo git
RUN apk add --no-cache nodejs npm
RUN apk add --no-cache tzdata
ENV TZ=Asia/Tokyo

COPY --from=klakegg/hugo /bin/hugo /usr/local/bin/
COPY --from=klakegg/hugo /bin/hugo-official /usr/local/bin/
COPY --from=klakegg/hugo /usr/lib/hugo /usr/lib/hugo

RUN if getent passwd ${USER_UID} >/dev/null 2>&1; then \
    deluser --remove-home $(getent passwd ${USER_UID} | cut -d: -f1); \
    fi; \
    if getent group ${USER_GID} >/dev/null 2>&1; then \
    delgroup $(getent group ${USER_GID} | cut -d: -f1); \
    fi

RUN addgroup -g ${USER_GID} ${USER} && \
    adduser -s /bin/ash -G ${USER} -u ${USER_UID} -D ${USER} && \
    echo "${USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USER} && \
    chmod 0440 /etc/sudoers.d/${USER}

RUN mkdir /workspace && chown ${USER}:${USER} /workspace
WORKDIR /workspace
RUN npm install -g @google/gemini-cli
USER ${USER}
ENV PATH=/home/${USER}/go/bin:/home/${USER}/node_modules/.bin:$PATH
# RUN <<EOM
#     cd ~
#     npm install -g @google/gemini-cli || npm install @google/gemini-cli
#     which gemini
# EOM
