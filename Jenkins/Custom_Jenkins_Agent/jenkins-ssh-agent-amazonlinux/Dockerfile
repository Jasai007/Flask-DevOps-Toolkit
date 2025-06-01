FROM amazonlinux:2023

# Update and install required packages
RUN yum update -y && \
    yum install -y git wget openssh-server shadow-utils python3

# Install Oracle JDK 17
RUN wget https://download.oracle.com/java/17/archive/jdk-17.0.8_linux-x64_bin.rpm && \
    yum install -y jdk-17.0.8_linux-x64_bin.rpm && \
    rm -f jdk-17.0.8_linux-x64_bin.rpm

# Create Jenkins user (no password set)
RUN useradd -m jenkins

# Prepare SSH for Jenkins user
RUN mkdir -p /home/jenkins/.ssh && \
    chmod 700 /home/jenkins/.ssh && \
    chown -R jenkins:jenkins /home/jenkins/.ssh

# Accept public key as build argument and add to authorized_keys
ARG JENKINS_PUB_KEY
RUN echo "${JENKINS_PUB_KEY}" > /home/jenkins/.ssh/authorized_keys && \
    chmod 600 /home/jenkins/.ssh/authorized_keys && \
    chown jenkins:jenkins /home/jenkins/.ssh/authorized_keys

# Configure SSH server: allow key auth, disable root login
RUN ssh-keygen -A && \
    sed -i 's/^#PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    sed -i 's/^#PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config && \
    sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config && \
    echo 'AllowUsers jenkins' >> /etc/ssh/sshd_config

# Expose SSH port
EXPOSE 22

# Start SSH daemon in foreground when container runs
CMD ["/usr/sbin/sshd", "-D"]