# Azure DevOps - Comprehensive Guide (2025 Edition)

Azure DevOps provides development collaboration tools including high-performance pipelines, free private Git repositories, configurable Kanban boards, and extensive automated and continuous testing capabilities. This guide covers the latest features and best practices as of 2025.

## Table of Contents

1. [Introduction to Azure DevOps](#introduction-to-azure-devops)
2. [Key Components](#key-components)
3. [Setting Up Your Environment](#setting-up-your-environment)
4. [Azure Boards - Project Management](#azure-boards---project-management)
5. [Azure Repos - Source Control](#azure-repos---source-control)
6. [Azure Pipelines - CI/CD](#azure-pipelines---cicd)
7. [Azure Test Plans - Testing](#azure-test-plans---testing)
8. [Azure Artifacts - Package Management](#azure-artifacts---package-management)
9. [Integration with Other Tools](#integration-with-other-tools)
10. [Best Practices](#best-practices)
11. [Hands-on Exercises](#hands-on-exercises)
12. [Advanced Topics](#advanced-topics)

## Introduction to Azure DevOps

Azure DevOps is a set of development tools and services that helps teams plan work, collaborate on code development, and build and deploy applications. It provides an integrated solution that covers the entire application lifecycle, from planning and development to delivery and operations.

### Benefits of Azure DevOps

- **Comprehensive Solution**: Covers the entire DevOps lifecycle
- **Flexibility**: Works with any language, platform, and cloud
- **Scalability**: Scales to handle enterprise workloads
- **Integration**: Connects with popular tools and services
- **Security**: Enterprise-grade security and governance
- **AI-Assisted Development**: Leverages AI to improve productivity and quality

## Key Components

Azure DevOps consists of five main services:

1. **Azure Boards**: Agile planning, work item tracking, visualization, and reporting tool
2. **Azure Repos**: Git repositories for source control of your code
3. **Azure Pipelines**: CI/CD that works with any language, platform, and cloud
4. **Azure Test Plans**: Manual and exploratory testing tools
5. **Azure Artifacts**: Repository for hosting packages like npm, NuGet, or Maven

## Setting Up Your Environment

### Creating an Azure DevOps Organization

1. Go to [dev.azure.com](https://dev.azure.com)
2. Sign in with your Microsoft account
3. Create a new organization by clicking on "New organization"
4. Follow the prompts to complete setup

### Creating Your First Project

1. Once in your organization, click "New project"
2. Enter a project name
3. Choose between public or private visibility
4. Select your version control (Git) and work item process (Agile, Scrum, or Basic)
5. Click "Create project"

## Azure Boards - Project Management

Azure Boards provides a flexible, customizable set of tools to manage your work throughout the development cycle.

### Work Item Types

- **Epics**: Large bodies of work that can be broken down into smaller features
- **Features**: Functionality that delivers business value
- **User Stories/Product Backlog Items**: Units of work that fit within a sprint
- **Tasks**: Specific activities required to complete a user story
- **Bugs**: Defects in the code that need to be fixed

### Setting Up Sprints

```bash
# Example using Azure DevOps CLI extension
az boards iteration project-team add --team "MyTeam" --name "Sprint 1" --start-date "2023-06-01" --finish-date "2023-06-15" --project "MyProject"
```

### Creating and Managing Boards

1. Navigate to Boards > Boards in your project
2. Select or create a team board
3. Customize columns based on your workflow (To Do, Doing, Done)
4. Add work items by clicking the "+" button in any column

## Azure Repos - Source Control

Azure Repos provides Git repositories that help you store and collaborate on your code.

### Setting Up Your Repository

```bash
# Initialize a new Git repository locally
git init

# Add the Azure DevOps remote
git remote add origin https://dev.azure.com/organization/project/_git/repository

# Push your code
git push -u origin main
```

### Branch Policies

1. Navigate to Repos > Branches
2. Select the branch you want to protect (e.g., main)
3. Click on the three dots and select "Branch policies"
4. Configure required reviewers, build validation, and other policies

## Azure Pipelines - CI/CD

Azure Pipelines automatically builds and tests code projects to make them available to others. It works with just about any language or project type and combines continuous integration (CI) and continuous delivery (CD) to test and build your code and ship it to any target.

### YAML Pipeline Example

```yaml
# azure-pipelines.yml
trigger:
- main

pool:
  vmImage: 'ubuntu-latest'

steps:
- task: NodeTool@0
  inputs:
    versionSpec: '14.x'
  displayName: 'Install Node.js'

- script: |
    npm install
    npm run build
  displayName: 'npm install and build'

- task: PublishBuildArtifacts@1
  inputs:
    pathtoPublish: '$(Build.ArtifactStagingDirectory)'
    artifactName: 'drop'
```

### Multi-Stage Pipeline Example

```yaml
# azure-pipelines.yml with stages
trigger:
- main

stages:
- stage: Build
  jobs:
  - job: BuildJob
    pool:
      vmImage: 'ubuntu-latest'
    steps:
    - script: echo "Building the application"
      displayName: 'Build'
    - task: PublishBuildArtifacts@1
      inputs:
        pathtoPublish: '$(Build.ArtifactStagingDirectory)'
        artifactName: 'drop'

- stage: Test
  dependsOn: Build
  jobs:
  - job: TestJob
    pool:
      vmImage: 'ubuntu-latest'
    steps:
    - script: echo "Running tests"
      displayName: 'Test'

- stage: Deploy
  dependsOn: Test
  jobs:
  - job: DeployJob
    pool:
      vmImage: 'ubuntu-latest'
    steps:
    - script: echo "Deploying the application"
      displayName: 'Deploy'
```

## Azure Test Plans - Testing

Azure Test Plans provides a browser-based test management solution for exploratory, planned manual, and user acceptance testing.

### Creating a Test Plan

1. Navigate to Test Plans > Test Plans
2. Click "New Test Plan"
3. Enter a name and select an iteration
4. Click "Create"

### Creating Test Cases

1. In your test plan, click "New Test Case"
2. Define the test steps, expected results, and other parameters
3. Save the test case

## Azure Artifacts - Package Management

Azure Artifacts allows teams to share packages such as Maven, npm, NuGet, and more from public and private sources and integrate package sharing into your CI/CD pipelines.

### Creating a Feed

1. Navigate to Artifacts
2. Click "Create Feed"
3. Enter a name and configure visibility settings
4. Click "Create"

### Publishing a Package

```bash
# For npm packages
npm publish --registry https://pkgs.dev.azure.com/organization/project/_packaging/feed-name/npm/registry/

# For NuGet packages
dotnet nuget push package.nupkg --source https://pkgs.dev.azure.com/organization/project/_packaging/feed-name/nuget/v3/index.json --api-key az
```

## Integration with Other Tools

Azure DevOps integrates with numerous tools and services:

- **GitHub**: Connect Azure Boards with GitHub repositories
- **Microsoft Teams/Slack**: Get notifications about DevOps events
- **Jenkins**: Use Jenkins for CI and Azure DevOps for the rest of your pipeline
- **Selenium**: Integrate Selenium tests into your pipeline
- **SonarQube**: Add code quality checks to your pipeline

### GitHub Integration Example

```yaml
# azure-pipelines.yml for GitHub repository
trigger:
  branches:
    include:
    - main

pool:
  vmImage: 'ubuntu-latest'

steps:
- checkout: self
  persistCredentials: true
  
- script: |
    git config --global user.email "you@example.com"
    git config --global user.name "Your Name"
    echo "Making changes and pushing to GitHub"
  displayName: 'Setup Git'
```

## Best Practices

### Azure Boards

- Use a consistent naming convention for work items
- Link work items to commits and pull requests
- Use tags for easy filtering
- Review and update your board regularly

### Azure Repos

- Protect your main branch with policies
- Use feature branches and pull requests
- Write meaningful commit messages
- Keep your repositories clean and organized

### Azure Pipelines

- Use YAML pipelines for version control
- Break complex pipelines into stages and jobs
- Cache dependencies to speed up builds
- Use variables and templates for reusability
- Implement quality gates and approvals

### Security Best Practices

- Use service connections instead of personal credentials
- Implement the principle of least privilege
- Regularly audit access to your projects
- Scan code for vulnerabilities

## Hands-on Exercises

### Exercise 1: Create a Basic CI/CD Pipeline

**Objective**: Create a pipeline that builds and deploys a simple web application.

1. Fork the sample repository from: https://github.com/microsoft/DevOps-For-Azure-Applications
2. Create a new pipeline in Azure DevOps pointing to your forked repository
3. Configure the pipeline to build and test the application
4. Add a deployment stage to deploy to Azure App Service

### Exercise 2: Implement a Branching Strategy

**Objective**: Implement a Gitflow branching strategy in your repository.

1. Create a development branch from main
2. Create feature branches from development
3. Implement branch policies for both main and development
4. Practice merging a feature into development and then into main

### Exercise 3: Set Up a Complete DevOps Workflow

**Objective**: Implement a complete DevOps workflow with planning, development, testing, and deployment.

1. Create a new project with Scrum process template
2. Create a product backlog with user stories and tasks
3. Set up a Git repository with branch policies
4. Create a multi-stage pipeline for CI/CD
5. Add automated testing and code quality checks
6. Configure release approvals and gates

## Advanced Topics

### DevOps for Containers and Kubernetes

```yaml
# azure-pipelines.yml for Kubernetes deployment
trigger:
- main

variables:
  containerRegistry: 'mycontainerregistry.azurecr.io'
  imageName: 'myapp'
  tag: '$(Build.BuildId)'

stages:
- stage: Build
  jobs:
  - job: BuildImage
    pool:
      vmImage: 'ubuntu-latest'
    steps:
    - task: Docker@2
      inputs:
        containerRegistry: 'myAzureContainerRegistry'
        repository: '$(imageName)'
        command: 'buildAndPush'
        Dockerfile: '**/Dockerfile'
        tags: '$(tag)'

- stage: Deploy
  jobs:
  - job: DeployToAKS
    pool:
      vmImage: 'ubuntu-latest'
    steps:
    - task: KubernetesManifest@0
      inputs:
        action: 'deploy'
        kubernetesServiceConnection: 'myAKSConnection'
        namespace: 'default'
        manifests: 'kubernetes/deployment.yml'
        containers: '$(containerRegistry)/$(imageName):$(tag)'
```

### Infrastructure as Code with Azure DevOps

```yaml
# azure-pipelines.yml for Terraform
trigger:
- main

pool:
  vmImage: 'ubuntu-latest'

steps:
- task: TerraformInstaller@0
  inputs:
    terraformVersion: 'latest'

- task: TerraformTaskV2@2
  inputs:
    provider: 'azurerm'
    command: 'init'
    workingDirectory: '$(System.DefaultWorkingDirectory)/terraform'
    backendServiceArm: 'Azure Service Connection'
    backendAzureRmResourceGroupName: 'terraform-backend-rg'
    backendAzureRmStorageAccountName: 'tfstate$(uniqueId)'
    backendAzureRmContainerName: 'tfstate'
    backendAzureRmKey: 'terraform.tfstate'

- task: TerraformTaskV2@2
  inputs:
    provider: 'azurerm'
    command: 'apply'
    workingDirectory: '$(System.DefaultWorkingDirectory)/terraform'
    environmentServiceNameAzureRM: 'Azure Service Connection'
```

### Security and Compliance

- **Static Application Security Testing (SAST)**
- **Dynamic Application Security Testing (DAST)**
- **Compliance as Code**
- **Security Scanning in Pipelines**

## Resources

- [Azure DevOps Documentation](https://docs.microsoft.com/en-us/azure/devops/)
- [Azure DevOps Labs](https://azuredevopslabs.com/)
- [Microsoft Learn Modules](https://docs.microsoft.com/en-us/learn/browse/?products=azure-devops)
- [Azure DevOps YouTube Channel](https://www.youtube.com/channel/UC-ikyViYMM69joIAv7dlMsQ)

## Conclusion

Azure DevOps provides a comprehensive set of tools for implementing DevOps practices in your organization. By leveraging Azure Boards, Repos, Pipelines, Test Plans, and Artifacts, teams can collaborate more effectively, automate their workflows, and deliver high-quality software at scale.

Whether you're a small team just getting started with DevOps or an enterprise organization looking to optimize your processes, Azure DevOps offers the flexibility, scalability, and integration capabilities to meet your needs.
