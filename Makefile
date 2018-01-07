SHELL:=/bin/bash

ANSIBLE:=$(shell command -v ansible 2> /dev/null)
ROLE_NAME?="$(shell basename $(CURDIR))"
DOCKER_IMAGE?=vgallissot/fedora-ansible:latest

yml_files:=$(shell find . -name "*.yml")
json_files:=$(shell find . -name "*.json")
jinja_files:=$(shell find . -name "*.j2")
ansible_files:=$(shell find ./tasks -name "*.yml")

.PHONY: all header help role test test-docker docker requirements debug

all: header help

header:
	$(info ---)
	$(info - Build Information)
	$(info - Directory: $(CURDIR))
ifdef ANSIBLE
	$(info - Ansible Version: $(shell ansible --version | head -1 || true))
	$(info - Ansible Playbook Version: $(shell ansible-playbook --version | head -1))
else
	$(info - Ansible *NOT DETECTED*)
endif
	$(info - Operating System: $(shell if [ -a /etc/issue ] ; then cat /etc/issue ; fi ; ))
	$(info - Kernel: $(shell uname -prsmn))
	$(info - DOCKER_IMAGE => $(DOCKER_IMAGE))
	$(info - ROLE_NAME => $(ROLE_NAME))
	$(info ---)

help:

	@echo ''
	@echo 'Usage:'
	@echo '    make test			apply role (test/example.yml) and run all tests'
	@echo '    make test-docker		run "make test" in a docker container'
	@echo '    make docker			launch a docker container'
	@echo '    make role			apply role (test/example.yml)'
	@echo '    make checkdiff		apply role (test/example.yml) with --check --diff options (READONLY)'
	@echo '    make requirements		install python and ansible-galaxy requirements'
	@echo ''
	@echo ''
	@echo '    Syntax tests:'
	@echo '        test.syntax		Run all syntax tests'
	@echo '        test.syntax.json		Run syntax tests on .json files'
	@echo '        test.syntax.yml		Run syntax tests on .yml files'
	@echo '        test.syntax.lint		Run lint tests on ansible files'
	@echo '        test.syntax.ansible	Run syntax tests on ansible files'
	@echo ''
	@echo '    test.idempotency		Run idempotency tests'
	@echo ''

## ReadOnly Tests
test.syntax: test.header test.syntax.yml test.syntax.json test.syntax.lint test.syntax.ansible

test.header:
	@echo '==='
	@echo '=== Running syntax tests'
	@echo ''

test.syntax.yml: $(patsubst %,test.syntax.yml/%,$(yml_files))

test.syntax.yml/%:
	python -c "import sys,yaml; yaml.load(open(sys.argv[1]))" $* >/dev/null

test.syntax.json: $(patsubst %,test.syntax.json/%,$(json_files))

test.syntax.json/%:
	jsonlint -v $*

test.syntax.lint: $(patsubst %,test.syntax.lint/%,$(ansible_files))
test.syntax.lint/%:
ifdef LINT_SKIP_LIST
	ansible-lint $* -x $(LINT_SKIP_LIST)
else
	ansible-lint $*
endif

test.syntax.ansible:
	cd tests ; ansible-playbook -i inventory test.yml --syntax-check

## ReadWrite Tests
test: header requirements test.syntax role checkdiff test.idempotency

test.idempotency:
ifndef SKIP_IDEMPOTENCY
	@echo ''
	@echo '=== Running idempotency tests'
	@echo ''
	cd tests ; \
	ansible-playbook -i inventory test.yml -c local | tee /tmp/output.txt ; \
	grep -q 'changed=0.*failed=0' /tmp/output.txt && \
	(echo 'Idempotence test: pass' && exit 0) || (echo 'Idempotence test: fail' && exit 1)
else
	@echo ''
	@echo '=== Skipping idempotency tests'
	@echo ''
endif

checkdiff:
ifndef SKIP_CHECKDIFF
	@echo ''
	@echo '=== Running --check --diff tests'
	@echo ''
	cd tests ; ansible-playbook -i inventory test.yml --connection=local --check --diff
else
	@echo ''
	@echo '=== Skipping --check --diff tests'
	@echo ''
endif

role:
	@echo ''
	@echo "=== Apply role by running playbook"
	@echo ''
	@cd tests ; ansible-playbook -i inventory --connection=local test.yml


## Actions
test-docker:
	docker run -i --rm --name $(ROLE_NAME) -h $(ROLE_NAME) -v $(CURDIR):/ansible/$(ROLE_NAME) $(DOCKER_IMAGE) /bin/bash -c "cd /ansible/$(ROLE_NAME) && make test"

docker:
	docker run -ti --rm --name $(ROLE_NAME) -h $(ROLE_NAME) -v $(CURDIR):/ansible/$(ROLE_NAME) $(DOCKER_IMAGE) /bin/bash


requirements:
	@echo ''
	@echo '=== Installing Python requirements'
	if [ -a requirements.txt ]; then pip install -qr requirements --exists-action w; fi;
	@echo '=== Installing Ansible requirements'
	if [ -a tests/requirements.yml ]; then cd tests && ansible-galaxy install -r requirements.yml --force ; fi;

