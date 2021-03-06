FROM circleci/python:2.7

USER root
RUN apt-get update && apt-get install -y \
    git-buildpackage \
    xsltproc docbook-xml docbook-xsl

WORKDIR /tmp

RUN git clone https://github.com/AGWA/git-crypt.git && cd /tmp/git-crypt && git checkout debian && git-buildpackage -uc -us

FROM circleci/python:2.7

ARG BUILD_DATE
ARG GIT_SHA1
ARG GIT_TAG

ARG KUBERNETES_VERSION="v1.6.4"
ARG HELM_VERSION="v2.5.0"
ARG TERRAFORM_VERSION="0.10.2"

LABEL maintainer="Nan Liu" \
      org.label-schema.name="circleci" \
      org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-url="https://github.com/nanliu/circleci" \
      org.label-schema.vcs-ref=$GIT_SHA1 \
      org.label-schema.version=$GIT_TAG

USER root

ENV SHELL "/bin/bash"

RUN apt-get update && apt-get install -y \
    parallel \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY --from=0 /tmp/*.deb /tmp/
RUN dpkg -i /tmp/*.deb

RUN curl -sfL https://storage.googleapis.com/kubernetes-release/release/${KUBERNETES_VERSION}/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl && \
   chmod 755 /usr/local/bin/kubectl
RUN curl -sfL http://storage.googleapis.com/kubernetes-helm/helm-${HELM_VERSION}-linux-amd64.tar.gz -o /tmp/helm-${HELM_VERSION}-linux-amd64.tar.gz && \
    tar xzf /tmp/helm-${HELM_VERSION}-linux-amd64.tar.gz && \
    mv linux-amd64/helm /usr/local/bin && \
    rm /tmp/helm-${HELM_VERSION}-linux-amd64.tar.gz && rm -r linux-amd64
RUN curl -sfL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -o /tmp/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    unzip /tmp/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    cp terraform /usr/local/bin && \
    rm /tmp/terraform_${TERRAFORM_VERSION}_linux_amd64.zip

USER circleci

RUN mkdir -p "$(helm home)/plugins" && \
    helm plugin install https://github.com/databus23/helm-diff

# NOTE: Silent parallel
RUN echo "will cite\n" | parallel --bibtex

CMD ["/bin/bash"]
