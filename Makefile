include version.env

IMAGE=netscan
ADDON_FILES=$(shell find files -type f)
PORTS= -p 9631:631/tcp -p 9632:632/tcp -p 6570:80/tcp
VOLUMES=
ENV=-e TZ=Europe/Amsterdam -e USER_NAME=lpadm \
		-e USER_PASSWD="$(shell ./rndpwd user.passwd -1 32 )" \
		-e PRINTER=npr1

DOCKER_SHELL = bash

START_OPTS = --detach
#~ DOCKER_AUTO_REMOVE =

help:
	@echo "Options:"
	@echo "- build : build image"
	@echo "- start : start container"
	@echo "- stop : stop container"
	@echo "- shell: start shell on running continer"
	@echo "- clean: clean up folder"

build: Dockerfile $(ADDON_FILES)
	# Create a files tarball
	[ -d files ] && tar -C files -zcf files.tar.gz . || :
	[ -f start ] && docker stop $$(cat start) && sleep 3 || :
	docker rmi $(IMAGE) || :
	docker buildx build -t $(IMAGE) $(BUILD_X_ARGS) .
	docker image inspect $(IMAGE) >$@
	rm -f files.tar.gz

start: build
	name="$(IMAGE).$$$$" ; \
		echo "$$name" | tee $@ ; \
		docker run \
		$(PORTS) $(VOLUMES) $(ENV) \
		$(START_OPTS) $(DOCKER_AUTO_REMOVE) --name $$name $(IMAGE) $(RUN_ARGS) || ( rm -f $@ ; exit 1) ; \
		( docker inspect -f '{{.State.Status}}' $$name| grep -q running ) || \
			rm -fv $@

stop:
	[ -f start ] && ( docker stop $$(cat start) || :) && rm -fv start \
		|| echo Not running

shell: start
	docker exec -it $$(cat start) $(DOCKER_SHELL) -il

clean:
	[ -f start ] && docker stop $$(cat start) && sleep 3 || :
	[ -f build ] && docker rmi $(IMAGE) || :
	rm -fv files.tar.gz build start

