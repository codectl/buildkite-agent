FROM alpine AS loader

# apk does work well with https when behind proxy
RUN sed -i 's/https/http/' /etc/apk/repositories
RUN apk update
RUN apk add --no-cache curl

WORKDIR /root/

# download kubectl
# steps described on https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/
RUN curl -L "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" -o kubectl
RUN curl -L "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256" -o kubectl.sha256
RUN curl -L "https://getcli.jfrog.io" | sh
RUN echo "$(cat kubectl.sha256)  kubectl" | sha256sum -c

# extend Buildkite agent
FROM buildkite/agent:3

# install dependencies
RUN apk update
RUN apk add postgresql-client gettext

WORKDIR /buildkite-agent/

COPY --from=loader /root/kubectl /tmp/

# install kubectl
RUN install -m 0755 /tmp/kubectl /usr/local/bin/kubectl
RUN rm /tmp/kubectl

# setup hooks
COPY src/hooks hooks/
COPY src/scripts scripts/
RUN chmod -R 0755 hooks/ scripts/

# entrypoint routines
COPY src/entrypoint/* /docker-entrypoint.d/
RUN chmod -R 0755 /docker-entrypoint.d/

ENV BUILDKITE_HOOKS_PATH /buildkite-agent/hooks