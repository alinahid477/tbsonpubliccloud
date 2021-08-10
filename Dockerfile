FROM debian:buster-slim

# culr (optional) for downloading/browsing stuff
# openssh-client (required) for creating ssh tunnel
# psmisc (optional) I needed it to test port binding after ssh tunnel (eg: netstat -ntlp | grep 6443)
# nano (required) buster-slim doesn't even have less. so I needed an editor to view/edit file (eg: /etc/hosts) 
# libdigest-sha-perl needed to execute carvel/install.sh
# stern for looking at log across multiple k8s pods
RUN apt-get update && apt-get install -y \
	apt-transport-https \
	ca-certificates \
	unzip \
	curl \
    openssh-client \
	psmisc \
	nano \
	net-tools \
	libdigest-sha-perl \
	# groff \
	&& curl -L https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl \
	&& chmod +x /usr/local/bin/kubectl \
	# && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    # && unzip awscliv2.zip \
    # && ./aws/install \
    # && rm -rf awscliv2.zip \
	&& curl -L https://github.com/wercker/stern/releases/download/$(curl -s https://api.github.com/repos/wercker/stern/releases/latest | grep tag_name | cut -d '"' -f 4)/stern_linux_amd64 -o /usr/local/bin/stern \
	&& chmod +x /usr/local/bin/stern


# RUN curl -L https://raw.githubusercontent.com/alinahid477/VMW/main/tbs/carvel/install.sh | bash
RUN curl -L https://carvel.dev/install.sh | bash
RUN curl -sSL https://get.docker.com/ | sh

COPY tbsfiles/default-builder.yaml /usr/local/
COPY binaries/tbsinstall.sh /usr/local/
COPY binaries/kp /usr/local/bin/ 
RUN chmod +x /usr/local/bin/kp && chmod +x /usr/local/tbsinstall.sh

COPY binaries/tmc /usr/local/bin/
RUN chmod +x /usr/local/bin/tmc

# COPY binaries/kubectl-vsphere /usr/local/bin/ 
# RUN chmod +x /usr/local/bin/kubectl-vsphere

ENTRYPOINT [ "/usr/local/tbsinstall.sh"]