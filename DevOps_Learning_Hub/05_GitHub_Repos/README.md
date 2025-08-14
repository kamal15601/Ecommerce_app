# DevOps GitHub Repositories 📚

## Overview
This section contains curated GitHub repositories for DevOps tools, sample projects, infrastructure templates, and real-world examples. All repositories are organized by category and include descriptions of their usefulness for learning and practical implementation.

## Table of Contents
- [Awesome Lists](#awesome-lists)
- [Infrastructure as Code](#infrastructure-as-code)
- [Container & Orchestration](#container--orchestration)
- [CI/CD Pipelines](#cicd-pipelines)
- [Monitoring & Observability](#monitoring--observability)
- [Security & Compliance](#security--compliance)
- [Sample Applications](#sample-applications)
- [Learning Projects](#learning-projects)
- [Tool Collections](#tool-collections)
- [Configuration Management](#configuration-management)

## Awesome Lists

### Comprehensive DevOps Lists
- **Awesome DevOps**: https://github.com/awesome-foss/awesome-sysadmin
  - Comprehensive list of DevOps tools and resources
- **Awesome Docker**: https://github.com/veggiemonk/awesome-docker
  - Everything related to Docker ecosystem
- **Awesome Kubernetes**: https://github.com/ramitsurana/awesome-kubernetes
  - Kubernetes tools, tutorials, and resources
- **Awesome Terraform**: https://github.com/shuaibiyy/awesome-terraform
  - Terraform providers, modules, and tools
- **Awesome Ansible**: https://github.com/ansible-community/awesome-ansible
  - Ansible roles, playbooks, and modules
- **Awesome Monitoring**: https://github.com/crazy-canux/awesome-monitoring
  - Monitoring tools and resources
- **Awesome CI/CD**: https://github.com/cicdops/awesome-ciandcd
  - Continuous integration and deployment tools

### Cloud-Specific Lists
- **Awesome AWS**: https://github.com/donnemartin/awesome-aws
  - Amazon Web Services tools and resources
- **Awesome Azure**: https://github.com/kristofferandreasen/awesome-azure
  - Microsoft Azure resources and tools
- **Awesome GCP**: https://github.com/GoogleCloudPlatform/awesome-google-cloud
  - Google Cloud Platform resources

## Infrastructure as Code

### Terraform Repositories
- **Terraform AWS Modules**: https://github.com/terraform-aws-modules
  - Official AWS modules for Terraform
  - Production-ready, well-documented modules
- **Terraform Best Practices**: https://github.com/ozbillwang/terraform-best-practices
  - Best practices and examples for Terraform
- **Terraform Examples**: https://github.com/hashicorp/terraform-provider-aws/tree/main/examples
  - Official AWS provider examples
- **Terraform Kitchen**: https://github.com/newcontext-oss/kitchen-terraform
  - Testing framework for Terraform configurations
- **Terragrunt**: https://github.com/gruntwork-io/terragrunt
  - Terraform wrapper for DRY configurations

### CloudFormation
- **AWS CloudFormation Templates**: https://github.com/aws-samples/aws-cloudformation-templates
  - Official AWS CloudFormation templates
- **AWS CloudFormation Samples**: https://github.com/awslabs/aws-cloudformation-templates
  - Community-contributed templates

### ARM Templates
- **Azure Quickstart Templates**: https://github.com/Azure/azure-quickstart-templates
  - Official Azure Resource Manager templates
- **Azure Resource Manager Tools**: https://github.com/Azure/azure-resource-manager-tools
  - Tools for working with ARM templates

### Pulumi
- **Pulumi Examples**: https://github.com/pulumi/examples
  - Multi-cloud infrastructure examples
- **Pulumi AWS Examples**: https://github.com/pulumi/examples/tree/master/aws-ts-*
  - AWS-specific Pulumi examples

## Container & Orchestration

### Docker Repositories
- **Docker Official Images**: https://github.com/docker-library/official-images
  - Source for Docker Hub official images
- **Docker Compose Examples**: https://github.com/docker/awesome-compose
  - Official Docker Compose examples
- **Dockerfile Best Practices**: https://github.com/hadolint/hadolint
  - Dockerfile linter for best practices
- **Docker Bench Security**: https://github.com/docker/docker-bench-security
  - Security benchmark for Docker

### Kubernetes Repositories
- **Kubernetes Examples**: https://github.com/kubernetes/examples
  - Official Kubernetes examples and tutorials
- **Kubernetes the Hard Way**: https://github.com/kelseyhightower/kubernetes-the-hard-way
  - Manual Kubernetes setup guide
- **Kustomize**: https://github.com/kubernetes-sigs/kustomize
  - Kubernetes native configuration management
- **Kubernetes Ingress Controllers**: https://github.com/kubernetes/ingress-nginx
  - NGINX ingress controller for Kubernetes

### Helm Charts
- **Helm Charts**: https://github.com/helm/charts
  - Official Helm chart repository (archived, see Artifact Hub)
- **Bitnami Charts**: https://github.com/bitnami/charts
  - Production-ready Helm charts
- **Prometheus Community Charts**: https://github.com/prometheus-community/helm-charts
  - Prometheus ecosystem Helm charts

### Service Mesh
- **Istio**: https://github.com/istio/istio
  - Service mesh platform
- **Linkerd**: https://github.com/linkerd/linkerd2
  - Lightweight service mesh
- **Consul Connect**: https://github.com/hashicorp/consul
  - Service mesh from HashiCorp

## CI/CD Pipelines

### GitHub Actions
- **GitHub Actions**: https://github.com/actions
  - Official GitHub Actions organization
- **Awesome GitHub Actions**: https://github.com/sdras/awesome-actions
  - Curated list of GitHub Actions
- **GitHub Actions Examples**: https://github.com/actions/starter-workflows
  - Starter workflow templates

### Jenkins
- **Jenkins Configuration as Code**: https://github.com/jenkinsci/configuration-as-code-plugin
  - JCasC plugin for Jenkins
- **Jenkins Shared Libraries**: https://github.com/mschuchard/jenkins-shared-library
  - Example shared library for Jenkins
- **Blue Ocean**: https://github.com/jenkinsci/blueocean-plugin
  - Modern Jenkins UI

### GitLab CI
- **GitLab CI Templates**: https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates
  - Official GitLab CI templates
- **GitLab CI Examples**: https://docs.gitlab.com/ee/ci/examples/
  - GitLab CI configuration examples

### Azure DevOps
- **Azure DevOps Templates**: https://github.com/microsoft/azure-pipelines-yaml
  - YAML pipeline templates for Azure DevOps

### ArgoCD
- **ArgoCD**: https://github.com/argoproj/argo-cd
  - GitOps continuous delivery tool
- **ArgoCD Examples**: https://github.com/argoproj/argocd-example-apps
  - Example applications for ArgoCD

## Monitoring & Observability

### Prometheus Ecosystem
- **Prometheus**: https://github.com/prometheus/prometheus
  - Monitoring system and time series database
- **Grafana**: https://github.com/grafana/grafana
  - Observability and visualization platform
- **Alert Manager**: https://github.com/prometheus/alertmanager
  - Alert handling for Prometheus
- **Node Exporter**: https://github.com/prometheus/node_exporter
  - Hardware and OS metrics exporter
- **Blackbox Exporter**: https://github.com/prometheus/blackbox_exporter
  - Blackbox probing of endpoints

### Elastic Stack
- **Elasticsearch**: https://github.com/elastic/elasticsearch
  - Distributed search and analytics engine
- **Logstash**: https://github.com/elastic/logstash
  - Data processing pipeline
- **Kibana**: https://github.com/elastic/kibana
  - Data visualization dashboard
- **Beats**: https://github.com/elastic/beats
  - Lightweight data shippers

### Jaeger & OpenTelemetry
- **Jaeger**: https://github.com/jaegertracing/jaeger
  - Distributed tracing platform
- **OpenTelemetry**: https://github.com/open-telemetry
  - Observability framework
- **OpenTelemetry Collector**: https://github.com/open-telemetry/opentelemetry-collector
  - Vendor-agnostic data collection

### Custom Monitoring Solutions
- **Netdata**: https://github.com/netdata/netdata
  - Real-time performance monitoring
- **Zabbix**: https://github.com/zabbix/zabbix
  - Enterprise monitoring solution
- **Victoria Metrics**: https://github.com/VictoriaMetrics/VictoriaMetrics
  - Time series database

## Security & Compliance

### Security Scanning
- **Trivy**: https://github.com/aquasecurity/trivy
  - Vulnerability scanner for containers
- **Clair**: https://github.com/quay/clair
  - Container vulnerability analysis
- **Anchore**: https://github.com/anchore/anchore-engine
  - Container image security analysis
- **Falco**: https://github.com/falcosecurity/falco
  - Runtime security monitoring

### Policy as Code
- **Open Policy Agent**: https://github.com/open-policy-agent/opa
  - Policy-based control framework
- **Gatekeeper**: https://github.com/open-policy-agent/gatekeeper
  - Kubernetes admission controller
- **Conftest**: https://github.com/open-policy-agent/conftest
  - Test your configuration files

### Secrets Management
- **HashiCorp Vault**: https://github.com/hashicorp/vault
  - Secrets management system
- **External Secrets**: https://github.com/external-secrets/external-secrets
  - Kubernetes external secrets operator
- **Sealed Secrets**: https://github.com/bitnami-labs/sealed-secrets
  - Encrypted secrets for GitOps

### Compliance
- **InSpec**: https://github.com/inspec/inspec
  - Compliance and security testing
- **Chef Compliance**: https://github.com/chef/compliance-profiles
  - Compliance profiles for InSpec
- **AWS Config Rules**: https://github.com/awslabs/aws-config-rules
  - AWS compliance automation

## Sample Applications

### Microservices Examples
- **Sock Shop**: https://github.com/microservices-demo/microservices-demo
  - Cloud-native microservices demo
- **Online Boutique**: https://github.com/GoogleCloudPlatform/microservices-demo
  - Google Cloud microservices example
- **WeaveWorks Sock Shop**: https://github.com/microservices-demo/deploy
  - Deployment examples for various platforms

### E-commerce Applications
- **Spring PetClinic**: https://github.com/spring-projects/spring-petclinic
  - Classic Spring Boot application
- **NodeJS Shopping Cart**: https://github.com/gtsopour/nodejs-shopping-cart
  - E-commerce application with Node.js
- **Django E-commerce**: https://github.com/justdjango/django-ecommerce
  - Python Django e-commerce platform

### Full-Stack Applications
- **MEAN Stack**: https://github.com/meanjs/mean
  - MongoDB, Express, Angular, Node.js
- **MERN Stack**: https://github.com/amazingandyyy/mern
  - MongoDB, Express, React, Node.js
- **Django React**: https://github.com/justdjango/django-react-boilerplate
  - Django with React frontend

## Learning Projects

### DevOps Project Ideas
- **DevOps Roadmap Projects**: https://github.com/MichaelCade/90DaysOfDevOps
  - 90 days of DevOps learning projects
- **DevOps Exercises**: https://github.com/bregman-arie/devops-exercises
  - DevOps interview questions and exercises
- **DevOps Projects**: https://github.com/kodekloudhub/certified-kubernetes-administrator-course
  - Hands-on DevOps projects

### Infrastructure Projects
- **AWS Samples**: https://github.com/aws-samples
  - Official AWS sample projects
- **Azure Samples**: https://github.com/azure-samples
  - Official Azure sample projects
- **Google Cloud Samples**: https://github.com/GoogleCloudPlatform
  - Official GCP sample projects

### Automation Projects
- **Ansible Playbooks**: https://github.com/ansible/ansible-examples
  - Example Ansible playbooks
- **Puppet Modules**: https://github.com/puppetlabs
  - Official Puppet modules
- **Chef Cookbooks**: https://github.com/chef-cookbooks
  - Official Chef cookbooks

## Tool Collections

### Multi-Tool Repositories
- **DevOps Toolkit**: https://github.com/vfarcic/devops-toolkit-crossplane
  - Complete DevOps toolkit examples
- **Cloud Native Toolkit**: https://github.com/cloud-native-toolkit
  - Cloud-native development tools
- **K8s Tools**: https://github.com/ramitsurana/awesome-kubernetes#tools
  - Kubernetes ecosystem tools

### Utility Collections
- **DevOps Scripts**: https://github.com/trimstray/the-book-of-secret-knowledge
  - Collection of useful scripts and tools
- **SRE Tools**: https://github.com/dastergon/awesome-sre
  - Site Reliability Engineering tools
- **CLI Tools**: https://github.com/agarrharr/awesome-cli-apps
  - Command-line applications

## Configuration Management

### Ansible
- **Ansible Galaxy**: https://github.com/ansible/galaxy
  - Ansible role and collection sharing
- **Ansible Runner**: https://github.com/ansible/ansible-runner
  - Python library for running Ansible
- **AWX**: https://github.com/ansible/awx
  - Web-based UI for Ansible

### Puppet
- **Puppet**: https://github.com/puppetlabs/puppet
  - Configuration management system
- **Puppet Forge Modules**: https://github.com/puppetlabs
  - Official Puppet modules

### Chef
- **Chef**: https://github.com/chef/chef
  - Configuration management platform
- **Chef Supermarket**: https://github.com/chef/supermarket
  - Community cookbook sharing

### SaltStack
- **Salt**: https://github.com/saltstack/salt
  - Python-based configuration management

## Specialized Areas

### Chaos Engineering
- **Chaos Monkey**: https://github.com/Netflix/chaosmonkey
  - Netflix's failure injection tool
- **Litmus**: https://github.com/litmuschaos/litmus
  - Kubernetes chaos engineering
- **Chaos Toolkit**: https://github.com/chaostoolkit/chaostoolkit
  - Chaos engineering toolkit

### Performance Testing
- **K6**: https://github.com/grafana/k6
  - Modern load testing tool
- **Artillery**: https://github.com/artilleryio/artillery
  - Performance testing toolkit
- **JMeter**: https://github.com/apache/jmeter
  - Performance testing application

### Backup & Disaster Recovery
- **Velero**: https://github.com/vmware-tanzu/velero
  - Kubernetes backup and migration
- **Stash**: https://github.com/stashed/stash
  - Backup solution for Kubernetes
- **Restic**: https://github.com/restic/restic
  - Fast, secure backup program

## Learning Resources

### Interactive Tutorials
- **Play with Docker**: https://github.com/play-with-docker/play-with-docker
  - Docker playground
- **Katacoda Scenarios**: https://github.com/katacoda/scenario-examples
  - Interactive learning scenarios
- **Kubernetes Learning**: https://github.com/kubernetes/website
  - Kubernetes documentation source

### Books & Guides
- **The DevOps Handbook Examples**: https://github.com/devops-handbook/examples
  - Code examples from the DevOps Handbook
- **SRE Book Examples**: https://github.com/google/sre-book
  - Google's SRE book
- **Infrastructure as Code Examples**: https://github.com/terraform-in-action
  - Terraform examples from the book

## How to Use These Repositories

### For Learning
1. **Start with Awesome Lists**: Get overview of tools and concepts
2. **Clone Sample Projects**: Run examples locally
3. **Read Documentation**: Understand how tools work
4. **Modify Examples**: Experiment with configurations
5. **Contribute Back**: Share improvements with community

### For Production
1. **Review Code Quality**: Check stars, contributors, recent activity
2. **Read Issues**: Understand common problems
3. **Check Security**: Review for vulnerabilities
4. **Test Thoroughly**: Always test before production use
5. **Follow Updates**: Subscribe to releases and security advisories

### Contributing Guidelines
- Fork repositories before making changes
- Follow project coding standards
- Write clear commit messages
- Add documentation for new features
- Test changes thoroughly
- Submit pull requests with detailed descriptions

This comprehensive collection of GitHub repositories provides practical examples, templates, and tools for implementing DevOps practices across various technologies and platforms.
