FROM alpine:latest


RUN apk add curl multipath-tools qemu packer

ARG USER_ID
ARG GROUP_ID

RUN addgroup --gid $GROUP_ID user
RUN adduser --disabled-password --gecos '' --uid $USER_ID --gid $GROUP_ID -s app

USER app
WORKDIR /home/app

ARG PACKER_BUILDER_ARM_VERSION=v0.1.6
RUN mkdir -p ~/.packer.d/plugins/ && \
    curl -L -o ~/.packer.d/plugins/packer-builder-arm-image \
      https://github.com/solo-io/packer-builder-arm-image/releases/download/${PACKER_BUILDER_ARM_VERSION}/packer-builder-arm-image && \
    chmod +x ~/.packer.d/plugins/packer-builder-arm-image

ENTRYPOINT [ "packer" ]
