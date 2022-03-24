_sections_dir := $(dir $(abspath $(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST))))
_sections_dir := $(_sections_dir:/=)

build:
	cd "${_sections_dir}" && \
	terraform apply -auto-approve && \
	"${_sections_dir}/04-provisioning-a-ca-and-generating-tls-certificates/run.sh" && \
	"${_sections_dir}/05-generating-kubernetes-configuration-files-for-authentication/run.sh" && \
	"${_sections_dir}/06-generating-the-data-encryption-config-and-key/run.sh" && \
	sync && \
	sleep 5 && \
	"${_sections_dir}/07-bootstrapping-the-etcd-cluster/01-upload-files-to-controller.sh" && \
	"${_sections_dir}/08-bootstrapping-the-kubernetes-control-plane/01-upload-files-to-controller.sh" && \
	"${_sections_dir}/09-bootstrapping-the-kubernetes-worker-nodes/01-upload-files-to-worker.sh"

.PHONY: build
