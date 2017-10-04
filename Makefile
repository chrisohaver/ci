

integration: integration-setup integration-test integration-teardown

.PHONY: integration-setup
integration-setup:

	# Get coredns code
	mkdir -p ${GOPATH}/src/${COREDNSPATH}
	cd ${GOPATH}/src/${COREDNSPATH} && \
	  git clone https://${COREDNSPATH}/coredns.git && \
	  cd coredns && \
	  git fetch origin ${PR}:${GOPATH} && \
	  git checkout ${GOPATH}

	# Start local docker image repo (k8s must pull images from a repo)
	docker run -d -p 5000:5000 --restart=always --name registry registry:2.6.2

	# Build coredns docker image, and push to local repo
	cd $GOPATH/src/${COREDNSPATH}/coredns && \
	  $(MAKE) coredns SYSTEM="GOOS=linux" && \
	  docker build -t coredns . && \
	  docker tag coredns localhost:5000/coredns && \
	  docker push localhost:5000/coredns && \

	# Set up minikube
	sh ./build/kubernetes/minikube_setup.sh

.PHONY: integration-test
integration-test:
	go test -v -tags 'etcd k8s' ./test/...

.PHONY: integration-teardown
integration-teardown:
	sh ./build/kubernetes/minikube_teardown.sh

.PHONY: install-webhook
install-webhook:
	cp ./build/pr-comment-hook.sh /opt/bin/
	# For now, update /etc/webhook.conf and /etc/caddy/Caddyfile are manual

PHONY: install-minikube
install-minikube:
	# Install minikube
	sh ./build/kubernetes/minikube_install.sh

