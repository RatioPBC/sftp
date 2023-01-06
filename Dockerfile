FROM atmoz/sftp:latest AS gcsfuse

# install https://github.com/GoogleCloudPlatform/gcsfuse
#
RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install -y curl gnupg && \
    echo "deb http://packages.cloud.google.com/apt gcsfuse-bullseye main" > /etc/apt/sources.list.d/gcsfuse.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    apt-get update && \
    apt-get install -y gcsfuse && \
    rm -rf /var/lib/apt/lists/*

# ---

FROM gcsfuse AS rsyslog

# install rsyslog
#
RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install -y rsyslog && \
    rm -rf /var/lib/apt/lists/*

# create shared logging socket for chroots
#
RUN echo 'input(type="imuxsock" Socket="/home/.sharedlogsocket" CreatePath="on")' > /etc/rsyslog.d/sftp.conf

# create dir and link rsyslogd for entrypoint to run
#
RUN mkdir /etc/sftp.d && \
    ln -s /usr/sbin/rsyslogd /etc/sftp.d/rsyslogd

# comment out imklog module
#
RUN sed -i -e 's/module(load="imklog")/#module(load="imklog")/' /etc/rsyslog.conf

# ---

FROM golang:1.19 AS build

COPY gcs_get_secret /var/tmp
RUN cd /var/tmp && go build

# ---

FROM rsyslog AS sftp

COPY --from=build /var/tmp/gcs_get_secret /usr/local/bin/

# update /etc/ssh/sshd_config
#
RUN sed -i -e 's/internal-sftp/internal-sftp -l INFO/' /etc/ssh/sshd_config && \
    echo "Port 2222" >> /etc/ssh/sshd_config

# copy gcs_entrypoint (execs original entrypoint)
#
COPY gcs_entrypoint /
ENTRYPOINT ["/gcs_entrypoint"]

# copy sshd_tail_log CMD script
#
COPY sshd_tail_log /usr/local/sbin/
CMD ["/usr/local/sbin/sshd_tail_log"]
