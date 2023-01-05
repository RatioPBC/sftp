sftp
====

SFTP service image with audit logs and gcsfuse that descends from
[atmoz/sftp](https://github.com/atmoz/sftp).

Goals:

1. Run on Compute Engine with persistent backend
2. Audit log all user activity to STDOUT for view in Logging
3. Use SSH host key stored in Secret Manager

Added packages:

* [gcsfuse](https://github.com/GoogleCloudPlatform/gcsfuse)
* [rsyslog](https://github.com/rsyslog/rsyslog)

Changed configuration:

* use `imuxsock` rsyslog module for shared log socket in chroots - ripped
  from [aptible/docker-sftp](https://github.com/aptible/docker-sftp)
* comment out `imklog` rsyslog module
* symlink `/usr/sbin/rsyslogd` in to `/etc/sftp.d/`
* add `-l INFO` to sftp options for audit logging

Added scripts:

* `/gcs_entrypoint` - writes SSH host key files from env vars then execs
  original entrypoint. This script is set as the image ENTRYPOINT.
* `/usr/local/sbin/sshd_tail_log` - links shared log socket into each user
  chroot, runs `/usr/sbin/sshd`, tails `/var/log/auth.log` to STDOUT. This
  script is set as the image CMD.
