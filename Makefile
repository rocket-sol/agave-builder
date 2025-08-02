.PHONY: build clean release

# renovate: datasource=github-releases depName=anza-xyz/agave
AGAVE_VERSION ?= v2.3.6
JOBS_NUM ?= $(shell nproc)

CACHE_IMAGE_NAME = ghcr.io/rocket-sol/agave-builder

ENABLE_CACHE ?= 1
ifeq "$(ENABLE_CACHE)" "1"
	DOCKER_BUILD_CACHE_ARGS := --cache-to=type=registry,ref=$(CACHE_IMAGE_NAME):cache,mode=max --cache-from=type=registry,ref=$(CACHE_IMAGE_NAME):cache --cache-from=type=registry,ref=$(CACHE_IMAGE_NAME):latest
endif

build:
	mkdir -p build
	# Useful debug options: --progress=plain --load --target source --no-cache
	docker buildx build . --build-arg JOBS_NUM=$(JOBS_NUM) --build-arg AGAVE_VERSION=$(AGAVE_VERSION) $(DOCKER_BUILD_CACHE_ARGS) --pull --output=build

clean:
	rm -rf build/*
	rm -f agave-*.tar.xz sha256sum.txt sha256sum.txt.sig

release: agave-$(AGAVE_VERSION).tar.xz sha256sum.txt

sign: sha256sum.txt.sig
	gh release upload $(AGAVE_VERSION) sha256sum.txt.sig

publish: release
	gh release create --generate-notes $(AGAVE_VERSION) agave-$(AGAVE_VERSION).tar.xz sha256sum.txt sha256sum.txt.sig

sha256sum.txt: agave-$(AGAVE_VERSION).tar.xz
	sha256sum agave-$(AGAVE_VERSION).tar.xz > sha256sum.txt

sha256sum.txt.sig: sha256sum.txt
	gpg --detach-sign $^

agave-$(AGAVE_VERSION).tar.xz:
	tar cvJf $@ -C build .
