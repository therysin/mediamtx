GITHUB_REPOSITORY = ghcr.io/therysin/mediamtx

define DOCKERFILE_DOCKERHUB
FROM scratch
ARG TARGETPLATFORM
ADD tmp/binaries/$$TARGETPLATFORM.tar.gz /
ENTRYPOINT [ "/mediamtx" ]
endef
export DOCKERFILE_DOCKERHUB

define DOCKERFILE_DOCKERHUB_FFMPEG
FROM $(ALPINE_IMAGE)
RUN apk add --no-cache ffmpeg
ARG TARGETPLATFORM
ADD tmp/binaries/$$TARGETPLATFORM.tar.gz /
ENTRYPOINT [ "/mediamtx" ]
endef
export DOCKERFILE_DOCKERHUB_FFMPEG

githubcontainer:
	$(eval VERSION := $(shell git describe --tags | tr -d v))

	docker login ghcr.io -u $(G_username) -p $(G_password)

	rm -rf tmp
	mkdir -p tmp tmp/binaries/linux/arm tmp/rpi_base/linux/arm

	cp binaries/*linux_amd64.tar.gz tmp/binaries/linux/amd64.tar.gz
	cp binaries/*linux_armv6.tar.gz tmp/binaries/linux/arm/v6.tar.gz
	cp binaries/*linux_armv7.tar.gz tmp/binaries/linux/arm/v7.tar.gz
	cp binaries/*linux_arm64v8.tar.gz tmp/binaries/linux/arm64.tar.gz

	docker buildx rm builder 2>/dev/null || true
	rm -rf $$HOME/.docker/manifests/*
	docker buildx create --name=builder --use

	echo "$$DOCKERFILE_DOCKERHUB_FFMPEG" | docker buildx build . -f - \
	--provenance=false \
	--platform=linux/amd64,linux/arm/v6,linux/arm/v7,linux/arm64/v8 \
	-t $(GITHUB_REPOSITORY):latest-ffmpeg-c-5 \
	--push

	echo "$$DOCKERFILE_DOCKERHUB" | docker buildx build . -f - \
	--provenance=false \
	--platform=linux/amd64,linux/arm/v6,linux/arm/v7,linux/arm64/v8 \
	-t $(GITHUB_REPOSITORY):latest-c-5 \
	--push

	docker buildx rm builder
	rm -rf $$HOME/.docker/manifests/*
