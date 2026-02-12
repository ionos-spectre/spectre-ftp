# Dockerfile for FTP Server (vsftpd)
FROM alpine:latest

# Install vsftpd
RUN apk add --no-cache vsftpd

# Create FTP user with proper home directory
RUN adduser -D -h /home/ftpuser ftpuser && \
    echo "ftpuser:ftppass" | chpasswd && \
    chown ftpuser:ftpuser /home/ftpuser && \
    chmod 755 /home/ftpuser

# Configure vsftpd
RUN echo "anonymous_enable=NO" > /etc/vsftpd/vsftpd.conf && \
    echo "local_enable=YES" >> /etc/vsftpd/vsftpd.conf && \
    echo "write_enable=YES" >> /etc/vsftpd/vsftpd.conf && \
    echo "local_umask=022" >> /etc/vsftpd/vsftpd.conf && \
    echo "dirmessage_enable=YES" >> /etc/vsftpd/vsftpd.conf && \
    echo "use_localtime=YES" >> /etc/vsftpd/vsftpd.conf && \
    echo "xferlog_enable=YES" >> /etc/vsftpd/vsftpd.conf && \
    echo "connect_from_port_20=YES" >> /etc/vsftpd/vsftpd.conf && \
    echo "secure_chroot_dir=/var/empty" >> /etc/vsftpd/vsftpd.conf && \
    echo "pam_service_name=vsftpd" >> /etc/vsftpd/vsftpd.conf && \
    echo "pasv_enable=YES" >> /etc/vsftpd/vsftpd.conf && \
    echo "pasv_min_port=21100" >> /etc/vsftpd/vsftpd.conf && \
    echo "pasv_max_port=21110" >> /etc/vsftpd/vsftpd.conf && \
    echo "userlist_enable=NO" >> /etc/vsftpd/vsftpd.conf && \
    echo "listen=YES" >> /etc/vsftpd/vsftpd.conf && \
    echo "listen_ipv6=NO" >> /etc/vsftpd/vsftpd.conf && \
    echo "seccomp_sandbox=NO" >> /etc/vsftpd/vsftpd.conf

# Create necessary directory for vsftpd
RUN mkdir -p /var/empty

EXPOSE 21 21100-21110

CMD ["/usr/sbin/vsftpd", "/etc/vsftpd/vsftpd.conf"]
