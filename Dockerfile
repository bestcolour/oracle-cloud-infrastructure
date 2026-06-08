FROM hashicorp/terraform:1.14

# Install Ansible and SSH
RUN apk add --no-cache openssh-client ansible python3

WORKDIR /workspace
ENTRYPOINT ["/bin/sh"]