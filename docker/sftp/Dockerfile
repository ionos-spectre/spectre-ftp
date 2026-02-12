# Dockerfile for SFTP Server
FROM alpine:latest

# Install OpenSSH
RUN apk add --no-cache openssh

# Create SFTP user
RUN adduser -D -h /home/sftpuser sftpuser && \
    echo "sftpuser:sftppass" | chpasswd

# Create SFTP directory structure
RUN mkdir -p /home/sftpuser/upload && \
    chown sftpuser:sftpuser /home/sftpuser/upload && \
    chmod 755 /home/sftpuser/upload

# Generate SSH host keys
RUN ssh-keygen -A

# Configure SSHD for SFTP
RUN echo "Port 22" > /etc/ssh/sshd_config && \
    echo "PermitRootLogin no" >> /etc/ssh/sshd_config && \
    echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config && \
    echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config && \
    echo "ChallengeResponseAuthentication no" >> /etc/ssh/sshd_config && \
    echo "UsePAM yes" >> /etc/ssh/sshd_config && \
    echo "Subsystem sftp internal-sftp" >> /etc/ssh/sshd_config && \
    echo "AllowUsers sftpuser" >> /etc/ssh/sshd_config

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D", "-e"]
