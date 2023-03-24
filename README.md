# Requirements

  1. Install the AWS command-line tool `aws`

  2. Install the Kubernetes command-line tool `kubectl`

  3. Install Terraform

  4. Install the Python package manager `pip`

  5. Install the following Python modules: `ansible`, `pyyaml`, and `cryptography`

  6. Install the Cloudflare SSL tools: `cfssl` and `cfssljson`

# Kubernetes The Hard Way - AWS - Terraform, Ansible

This project is based on [Kubernetes The Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way) and [Kubernetes The Hard Way - AWS](https://github.com/slawekzachcial/kubernetes-the-hard-way-aws). It takes [Kubernetes The Hard Way - AWS](https://github.com/slawekzachcial/kubernetes-the-hard-way-aws) a step further by using Terraform to provision AWS resources, Ansible for configuration management, and Python and shell scripts for various glue code. It automates the whole process of bringing up a Kubernetes cluster while maintaining a lab-style flow and file structure similar to [Kubernetes The Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way). It was created for the purpose of learning Kubernetes.


To quote [Kubernetes The Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way):

> Kubernetes The Hard Way is optimized for learning, which means taking the long route to ensure you understand each task required to bootstrap a Kubernetes cluster.

> The results of this tutorial should not be viewed as production ready, and may receive limited support from the community, but don't let that stop you from learning!

One should be a little bit familiar with [Kubernetes The Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way) and [Kubernetes The Hard Way - AWS](https://github.com/slawekzachcial/kubernetes-the-hard-way-aws) before using this project.

## AWS Costs Disclaimer

This project uses AWS resources. The authors shall not be responsible for AWS costs that this project might incur.

## Usage

1. Clone this repository

2. Change directory into the clone repository

3. Change the Terraform backend to your backend. If you're not familiar with Terraform, it's probably better to just use a local backend. Make sure that git ignores the backend/state files that will be produced when running Terraform (TODO).

4. `make build` will build your Kubernetes cluster

5. `make destroy` will delete all provisioned resources

## Configuration

You can change the configuration file, `config.yml`, to suit your needs. Under the `controllers` and `workers` block, you can change the number of instances used as Kubernetes controllers and workers. Just make sure the names, IP addresses, etc. don't conflict with each other.

## Idempotency

- [x] Section 10

- [x] Section 11

- [x] Section 12

- [x] Section 13

## TODO

- [x] Automate the checking of prerequisites

- [x] Check if client tools are installed

- [ ] Fix the "error dialing backend...127.0.0.1:53: no such host" intermittent issue

- [ ] Write clearer explanation of how to deal with Terraform backend

- [ ] Write tests
