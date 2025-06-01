# Use Amazon Linux base image
FROM amazonlinux:2023

# Update & install required packages
RUN yum update -y
RUN yum install -y git wget openssh-server
RUN yum install -y shadow-utils-2:4.9-12.amzn2023.0.2.x86_64
RUN yum install python3 -y

# Install Oracle JDK 17
RUN wget https://download.oracle.com/java/17/archive/jdk-17.0.8_linux-x64_bin.rpm
RUN yum install -y jdk-17.0.8_linux-x64_bin.rpm    

# Set root password
RUN echo 'root:redhat' | chpasswd

# Configure SSH server
RUN ssh-keygen -A
RUN sed -i 's/^#PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config 
RUN sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config 
RUN sed -i 's/^#PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config 
RUN echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config 
RUN echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config

# Expose SSH port
EXPOSE 22

# Start SSH daemon in foreground when container runs
CMD ["/usr/sbin/sshd", "-D"]
