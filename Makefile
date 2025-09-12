.PHONY: build clean release

# renovate: datasource=github-releases depName=anza-xyz/agave
AGAVE_VERSION ?= v3.0.0
JOBS_NUM ?= $(shell nproc)

CACHE_IMAGE_NAME = ghcr.io/rocket-sol/agave-builder

ENABLE_CACHE ?= 1
ifeq "$(ENABLE_CACHE)" "1"
	DOCKER_BUILD_CACHE_ARGS := --cache-to=type=registry,ref=$(CACHE_IMAGE_NAME):cache,mode=max --cache-from=type=registry,ref=$(CACHE_IMAGE_NAME):cache --cache-from=type=registry,ref=$(CACHE_IMAGE_NAME):latest
endif

build:
	mkdir -p build/bin
	# Useful debug options: --progress=plain --load --target source --no-cache
	docker buildx build . --build-arg JOBS_NUM=$(JOBS_NUM) --build-arg AGAVE_VERSION=$(AGAVE_VERSION) $(DOCKER_BUILD_CACHE_ARGS) --pull --output=build/bin

clean:
	rm -rf build/*
	rm -f agave-*.tar.xz sha256sum.txt sha256sum.txt.sig
	rm -f solana-release-x86_64-unknown-linux-gnu.tar.bz2


release: solana-release-x86_64-unknown-linux-gnu.tar.bz2 sha256sum.txt

sign: sha256sum.txt.sig

publish: release sign
	gh release create --generate-notes $(AGAVE_VERSION) solana-release-x86_64-unknown-linux-gnu.tar.bz2 sha256sum.txt sha256sum.txt.sig

sha256sum.txt: solana-release-x86_64-unknown-linux-gnu.tar.bz2
	sha256sum solana-release-x86_64-unknown-linux-gnu.tar.bz2  > sha256sum.txt

sha256sum.txt.sig: sha256sum.txt
	gpg --detach-sign $^

solana-release-x86_64-unknown-linux-gnu.tar.bz2: build
	tar cvjf $@ -C build .


agave-$(AGAVE_VERSION).tar.xz:
	tar cvJf $@ -C build .
