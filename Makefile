# 2022 03 31: make reset  113.29s user 17.57s system 17% cpu 12:16.37 total
#             make reset  111.15s user 17.29s system 17% cpu 12:25.55 total
# 2022 04 01: make build  116.34s user 19.78s system 20% cpu 10:58.99 total

_main_dir := $(dir $(abspath $(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST))))
_main_dir := $(_main_dir:/=)

_main_app_dir := ${_main_dir}
_main_sections_dir := ${_main_app_dir}/sections
_main_terraform_cmd := ${_main_app_dir}/terraform.sh

plan:
	"${_main_terraform_cmd}" plan

apply:
	"${_main_terraform_cmd}" apply

destroy:
	make delete-key-pair; \
	"${_main_terraform_cmd}" destroy && \
	rm -rf "${_main_app_dir}/secrets"

build:
	cd "${_main_app_dir}" && \
	"${_main_sections_dir}/01-prerequisites/run.sh" && \
	make create-key-pair && \
	make apply  && \
	"${_main_sections_dir}/04-provisioning-a-ca-and-generating-tls-certificates/run.py" && \
	"${_main_sections_dir}/05-generating-kubernetes-configuration-files-for-authentication/run.py" && \
	"${_main_sections_dir}/06-generating-the-data-encryption-config-and-key/run.py" && \
	"${_main_sections_dir}/07-bootstrapping-the-etcd-cluster/run-cm.py" && \
	"${_main_sections_dir}/08-bootstrapping-the-kubernetes-control-plane/01-run-cm.py" && \
	"${_main_sections_dir}/08-bootstrapping-the-kubernetes-control-plane/03-the-kubernetes-frontend-load-balancer_verification.py" && \
	"${_main_sections_dir}/09-bootstrapping-the-kubernetes-worker-nodes/run-cm.py" && \
	"${_main_sections_dir}/10-configuring-kubectl-for-remote-access/run.py" && \
	"${_main_sections_dir}/11-provisioning-pod-network-routes/02-verification.sh" && \
	"${_main_sections_dir}/12-deploying-the-dns-cluster-add-on/01-run-cm.py" && \
	"${_main_sections_dir}/12-deploying-the-dns-cluster-add-on/02-run.sh" && \
	"${_main_sections_dir}/13-smoke-test/01-data-encryption-and-nginx.py" && \
	"${_main_sections_dir}/13-smoke-test/02-port-forward-localhost-curl-test.py" && \
	"${_main_sections_dir}/13-smoke-test/03-logs-and-exec.py" && \
	"${_main_sections_dir}/13-smoke-test/04-create-nginx-service.py" && \
	"${_main_sections_dir}/13-smoke-test/07-create-nginx-node-port-firewall-rule.sh" && \
	"${_main_sections_dir}/13-smoke-test/09-curl-nginx-test.py"

reset:
	cd "${_main_app_dir}" && \
	make destroy && \
	make build

create-key-pair:
	cd "${_main_app_dir}" && \
	"${_main_app_dir}/lib/key_pair.py" create

delete-key-pair:
	cd "${_main_app_dir}" && \
	"${_main_app_dir}/lib/key_pair.py" destroy

.PHONY: build key-pair delete-key-pair reset key-pair delete-key-pair tests
