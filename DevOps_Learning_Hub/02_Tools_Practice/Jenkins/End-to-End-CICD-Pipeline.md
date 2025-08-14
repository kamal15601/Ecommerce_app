# End-to-End CI/CD Pipeline with Jenkins

This guide provides a comprehensive walkthrough for creating a complete end-to-end CI/CD pipeline using Jenkins, covering all stages from code commit to production deployment.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Pipeline Overview](#pipeline-overview)
3. [Jenkins Setup](#jenkins-setup)
4. [Pipeline as Code (Jenkinsfile)](#pipeline-as-code-jenkinsfile)
5. [Pipeline Stages in Detail](#pipeline-stages-in-detail)
6. [Environment-Specific Deployments](#environment-specific-deployments)
7. [Advanced Jenkins Features](#advanced-jenkins-features)
8. [Monitoring Your Pipeline](#monitoring-your-pipeline)
9. [Hands-on Exercises](#hands-on-exercises)
10. [Troubleshooting](#troubleshooting)

## Prerequisites

Before getting started, ensure you have:

- Jenkins server (v2.303.1+)
- Jenkins Plugins:
  - Pipeline
  - Blue Ocean
  - Docker Pipeline
  - Kubernetes
  - SonarQube Scanner
  - JaCoCo
  - OWASP Dependency-Check
  - Email Extension
  - Slack Notification
- Docker and/or Kubernetes environment
- Source code repository (Git)

## Pipeline Overview

Our end-to-end CI/CD pipeline consists of the following stages:

```
Code Commit → Build → Test → Static Analysis → Security Scan → Artifact Creation → Deploy to Dev → Integration Tests → Deploy to Staging → Performance Tests → Manual Approval → Deploy to Production → Monitoring
```

![Jenkins Pipeline Flow](https://example.com/jenkins-pipeline-diagram.png)

## Jenkins Setup

### 1. Installing Jenkins

```bash
# Using Docker
docker run -d -p 8080:8080 -p 50000:50000 -v jenkins_home:/var/jenkins_home jenkins/jenkins:lts

# Or on Ubuntu
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt-get update
sudo apt-get install jenkins
```

### 2. Initial Configuration

1. Access Jenkins at http://localhost:8080
2. Enter the initial admin password from `/var/jenkins_home/secrets/initialAdminPassword`
3. Install suggested plugins
4. Create an admin user
5. Configure Jenkins URL

### 3. Plugin Installation

Navigate to `Manage Jenkins > Manage Plugins > Available` and install:

- Pipeline
- Blue Ocean
- Docker Pipeline
- Kubernetes
- SonarQube Scanner
- Slack Notification

### 4. Credentials Setup

Add the following credentials in `Manage Jenkins > Manage Credentials`:

- Git repository credentials
- Docker registry credentials
- Kubernetes config
- SonarQube token
- Slack/Email notification settings

## Pipeline as Code (Jenkinsfile)

Create a `Jenkinsfile` in your repository root:

```groovy
pipeline {
    agent {
        kubernetes {
            yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: maven
    image: maven:3.8.4-openjdk-11
    command:
    - cat
    tty: true
  - name: docker
    image: docker:20.10.12-dind
    command:
    - cat
    tty: true
    privileged: true
  - name: kubectl
    image: bitnami/kubectl:1.23.0
    command:
    - cat
    tty: true
"""
        }
    }
    
    environment {
        DOCKER_REGISTRY = "your-docker-registry.com"
        APP_NAME = "your-app-name"
        VERSION = "${BUILD_NUMBER}"
        SONARQUBE_URL = "http://sonarqube:9000"
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build') {
            steps {
                container('maven') {
                    sh 'mvn clean compile'
                }
            }
        }
        
        stage('Unit Tests') {
            steps {
                container('maven') {
                    sh 'mvn test'
                    junit '**/target/surefire-reports/TEST-*.xml'
                    jacoco execPattern: 'target/jacoco.exec'
                }
            }
        }
        
        stage('Static Code Analysis') {
            steps {
                container('maven') {
                    withSonarQubeEnv('SonarQube') {
                        sh """
                            mvn sonar:sonar \
                              -Dsonar.projectKey=${APP_NAME} \
                              -Dsonar.host.url=${SONARQUBE_URL}
                        """
                    }
                    
                    timeout(time: 10, unit: 'MINUTES') {
                        waitForQualityGate abortPipeline: true
                    }
                }
            }
        }
        
        stage('Security Scan') {
            steps {
                container('maven') {
                    sh 'mvn dependency-check:check'
                    publishHTML([
                        allowMissing: false, 
                        alwaysLinkToLastBuild: true, 
                        keepAll: true, 
                        reportDir: 'target/dependency-check-report', 
                        reportFiles: 'dependency-check-report.html', 
                        reportName: 'Dependency Check Report'
                    ])
                }
            }
        }
        
        stage('Package') {
            steps {
                container('maven') {
                    sh 'mvn package -DskipTests'
                    archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                container('docker') {
                    sh """
                        docker build -t ${DOCKER_REGISTRY}/${APP_NAME}:${VERSION} .
                        docker tag ${DOCKER_REGISTRY}/${APP_NAME}:${VERSION} ${DOCKER_REGISTRY}/${APP_NAME}:latest
                    """
                }
            }
        }
        
        stage('Push Docker Image') {
            steps {
                container('docker') {
                    withCredentials([usernamePassword(credentialsId: 'docker-registry-credentials', passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
                        sh '''
                            docker login ${DOCKER_REGISTRY} -u ${DOCKER_USERNAME} -p ${DOCKER_PASSWORD}
                            docker push ${DOCKER_REGISTRY}/${APP_NAME}:${VERSION}
                            docker push ${DOCKER_REGISTRY}/${APP_NAME}:latest
                        '''
                    }
                }
            }
        }
        
        stage('Deploy to Development') {
            steps {
                container('kubectl') {
                    withKubeConfig([credentialsId: 'kubeconfig']) {
                        sh """
                            kubectl apply -f k8s/dev/namespace.yaml
                            kubectl apply -f k8s/dev/configmap.yaml
                            kubectl apply -f k8s/dev/service.yaml
                            
                            # Update deployment with new image
                            kubectl set image deployment/${APP_NAME} ${APP_NAME}=${DOCKER_REGISTRY}/${APP_NAME}:${VERSION} -n dev
                            
                            # Wait for deployment to complete
                            kubectl rollout status deployment/${APP_NAME} -n dev --timeout=180s
                        """
                    }
                }
            }
        }
        
        stage('Integration Tests') {
            steps {
                container('maven') {
                    sh 'mvn failsafe:integration-test'
                    junit '**/target/failsafe-reports/TEST-*.xml'
                }
            }
        }
        
        stage('Deploy to Staging') {
            when {
                branch 'main'
            }
            steps {
                container('kubectl') {
                    withKubeConfig([credentialsId: 'kubeconfig']) {
                        sh """
                            kubectl apply -f k8s/staging/namespace.yaml
                            kubectl apply -f k8s/staging/configmap.yaml
                            kubectl apply -f k8s/staging/service.yaml
                            
                            # Update deployment with new image
                            kubectl set image deployment/${APP_NAME} ${APP_NAME}=${DOCKER_REGISTRY}/${APP_NAME}:${VERSION} -n staging
                            
                            # Wait for deployment to complete
                            kubectl rollout status deployment/${APP_NAME} -n staging --timeout=180s
                        """
                    }
                }
            }
        }
        
        stage('Performance Tests') {
            when {
                branch 'main'
            }
            steps {
                sh 'jmeter -n -t performance-test.jmx -l results.jtl'
                perfReport sourceDataFiles: 'results.jtl'
            }
        }
        
        stage('Manual Approval') {
            when {
                branch 'main'
            }
            steps {
                slackSend channel: '#deployments', 
                          message: "Deployment to production requires approval: ${BUILD_URL}"
                
                input message: 'Deploy to production?', ok: 'Deploy'
            }
        }
        
        stage('Deploy to Production') {
            when {
                branch 'main'
            }
            steps {
                container('kubectl') {
                    withKubeConfig([credentialsId: 'kubeconfig']) {
                        sh """
                            kubectl apply -f k8s/prod/namespace.yaml
                            kubectl apply -f k8s/prod/configmap.yaml
                            kubectl apply -f k8s/prod/service.yaml
                            
                            # Update deployment with new image
                            kubectl set image deployment/${APP_NAME} ${APP_NAME}=${DOCKER_REGISTRY}/${APP_NAME}:${VERSION} -n prod
                            
                            # Wait for deployment to complete
                            kubectl rollout status deployment/${APP_NAME} -n prod --timeout=180s
                        """
                    }
                }
            }
        }
    }
    
    post {
        always {
            // Clean workspace
            cleanWs()
        }
        success {
            slackSend channel: '#deployments', 
                      color: 'good', 
                      message: "Deployment successful: ${APP_NAME}:${VERSION}"
            
            emailext subject: "Deployment Successful: ${APP_NAME}:${VERSION}",
                     body: "The deployment of ${APP_NAME}:${VERSION} was successful.",
                     to: 'team@example.com'
        }
        failure {
            slackSend channel: '#deployments', 
                      color: 'danger', 
                      message: "Deployment failed: ${APP_NAME}:${VERSION}"
            
            emailext subject: "Deployment Failed: ${APP_NAME}:${VERSION}",
                     body: "The deployment of ${APP_NAME}:${VERSION} failed. Check the build log: ${BUILD_URL}",
                     to: 'team@example.com'
        }
    }
}
```

## Pipeline Stages in Detail

### 1. Code Checkout

This stage retrieves the source code from the repository:

```groovy
stage('Checkout') {
    steps {
        checkout scm
    }
}
```

### 2. Build

Compiles the application code:

```groovy
stage('Build') {
    steps {
        container('maven') {
            sh 'mvn clean compile'
        }
    }
}
```

### 3. Unit Tests

Runs unit tests and collects test and coverage reports:

```groovy
stage('Unit Tests') {
    steps {
        container('maven') {
            sh 'mvn test'
            junit '**/target/surefire-reports/TEST-*.xml'
            jacoco execPattern: 'target/jacoco.exec'
        }
    }
}
```

### 4. Static Code Analysis

Performs code quality analysis with SonarQube:

```groovy
stage('Static Code Analysis') {
    steps {
        container('maven') {
            withSonarQubeEnv('SonarQube') {
                sh """
                    mvn sonar:sonar \
                      -Dsonar.projectKey=${APP_NAME} \
                      -Dsonar.host.url=${SONARQUBE_URL}
                """
            }
            
            timeout(time: 10, unit: 'MINUTES') {
                waitForQualityGate abortPipeline: true
            }
        }
    }
}
```

### 5. Security Scan

Checks for known vulnerabilities in dependencies:

```groovy
stage('Security Scan') {
    steps {
        container('maven') {
            sh 'mvn dependency-check:check'
            publishHTML([
                allowMissing: false, 
                alwaysLinkToLastBuild: true, 
                keepAll: true, 
                reportDir: 'target/dependency-check-report', 
                reportFiles: 'dependency-check-report.html', 
                reportName: 'Dependency Check Report'
            ])
        }
    }
}
```

### 6. Package

Creates the application artifact:

```groovy
stage('Package') {
    steps {
        container('maven') {
            sh 'mvn package -DskipTests'
            archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
        }
    }
}
```

### 7-8. Build and Push Docker Image

Creates and publishes a Docker image:

```groovy
stage('Build Docker Image') {
    steps {
        container('docker') {
            sh """
                docker build -t ${DOCKER_REGISTRY}/${APP_NAME}:${VERSION} .
                docker tag ${DOCKER_REGISTRY}/${APP_NAME}:${VERSION} ${DOCKER_REGISTRY}/${APP_NAME}:latest
            """
        }
    }
}

stage('Push Docker Image') {
    steps {
        container('docker') {
            withCredentials([usernamePassword(credentialsId: 'docker-registry-credentials', passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
                sh '''
                    docker login ${DOCKER_REGISTRY} -u ${DOCKER_USERNAME} -p ${DOCKER_PASSWORD}
                    docker push ${DOCKER_REGISTRY}/${APP_NAME}:${VERSION}
                    docker push ${DOCKER_REGISTRY}/${APP_NAME}:latest
                '''
            }
        }
    }
}
```

### 9. Deploy to Development

Deploys the application to the development environment:

```groovy
stage('Deploy to Development') {
    steps {
        container('kubectl') {
            withKubeConfig([credentialsId: 'kubeconfig']) {
                sh """
                    kubectl apply -f k8s/dev/namespace.yaml
                    kubectl apply -f k8s/dev/configmap.yaml
                    kubectl apply -f k8s/dev/service.yaml
                    
                    # Update deployment with new image
                    kubectl set image deployment/${APP_NAME} ${APP_NAME}=${DOCKER_REGISTRY}/${APP_NAME}:${VERSION} -n dev
                    
                    # Wait for deployment to complete
                    kubectl rollout status deployment/${APP_NAME} -n dev --timeout=180s
                """
            }
        }
    }
}
```

### 10. Integration Tests

Runs integration tests against the development environment:

```groovy
stage('Integration Tests') {
    steps {
        container('maven') {
            sh 'mvn failsafe:integration-test'
            junit '**/target/failsafe-reports/TEST-*.xml'
        }
    }
}
```

### 11. Deploy to Staging

Deploys to the staging environment:

```groovy
stage('Deploy to Staging') {
    when {
        branch 'main'
    }
    steps {
        container('kubectl') {
            withKubeConfig([credentialsId: 'kubeconfig']) {
                sh """
                    kubectl apply -f k8s/staging/namespace.yaml
                    kubectl apply -f k8s/staging/configmap.yaml
                    kubectl apply -f k8s/staging/service.yaml
                    
                    # Update deployment with new image
                    kubectl set image deployment/${APP_NAME} ${APP_NAME}=${DOCKER_REGISTRY}/${APP_NAME}:${VERSION} -n staging
                    
                    # Wait for deployment to complete
                    kubectl rollout status deployment/${APP_NAME} -n staging --timeout=180s
                """
            }
        }
    }
}
```

### 12. Performance Tests

Runs performance tests against the staging environment:

```groovy
stage('Performance Tests') {
    when {
        branch 'main'
    }
    steps {
        sh 'jmeter -n -t performance-test.jmx -l results.jtl'
        perfReport sourceDataFiles: 'results.jtl'
    }
}
```

### 13. Manual Approval

Requires manual approval before deploying to production:

```groovy
stage('Manual Approval') {
    when {
        branch 'main'
    }
    steps {
        slackSend channel: '#deployments', 
                  message: "Deployment to production requires approval: ${BUILD_URL}"
        
        input message: 'Deploy to production?', ok: 'Deploy'
    }
}
```

### 14. Deploy to Production

Deploys to the production environment:

```groovy
stage('Deploy to Production') {
    when {
        branch 'main'
    }
    steps {
        container('kubectl') {
            withKubeConfig([credentialsId: 'kubeconfig']) {
                sh """
                    kubectl apply -f k8s/prod/namespace.yaml
                    kubectl apply -f k8s/prod/configmap.yaml
                    kubectl apply -f k8s/prod/service.yaml
                    
                    # Update deployment with new image
                    kubectl set image deployment/${APP_NAME} ${APP_NAME}=${DOCKER_REGISTRY}/${APP_NAME}:${VERSION} -n prod
                    
                    # Wait for deployment to complete
                    kubectl rollout status deployment/${APP_NAME} -n prod --timeout=180s
                """
            }
        }
    }
}
```

## Environment-Specific Deployments

### Using Environment Variables

Create environment-specific variables in Jenkins:

1. Go to `Manage Jenkins > Configure System > Global properties`
2. Add environment variables for each environment

Or define them in the pipeline:

```groovy
environment {
    DEV_NAMESPACE = "dev"
    STAGING_NAMESPACE = "staging"
    PROD_NAMESPACE = "production"
    
    DEV_URL = "dev.example.com"
    STAGING_URL = "staging.example.com"
    PROD_URL = "example.com"
}
```

### Using Kubernetes Manifests

Organize Kubernetes manifests by environment:

```
k8s/
├── dev/
│   ├── configmap.yaml
│   ├── deployment.yaml
│   ├── namespace.yaml
│   └── service.yaml
├── staging/
│   ├── configmap.yaml
│   ├── deployment.yaml
│   ├── namespace.yaml
│   └── service.yaml
└── prod/
    ├── configmap.yaml
    ├── deployment.yaml
    ├── namespace.yaml
    └── service.yaml
```

### Using Helm

For more complex deployments, use Helm charts:

```groovy
stage('Deploy to Development') {
    steps {
        container('helm') {
            withKubeConfig([credentialsId: 'kubeconfig']) {
                sh """
                    helm upgrade --install ${APP_NAME} ./helm \
                      --namespace dev \
                      --create-namespace \
                      --set image.repository=${DOCKER_REGISTRY}/${APP_NAME} \
                      --set image.tag=${VERSION} \
                      --set environment=development \
                      --values ./helm/values-dev.yaml
                """
            }
        }
    }
}
```

## Advanced Jenkins Features

### Parallel Execution

Run stages in parallel to speed up the pipeline:

```groovy
stage('Tests') {
    parallel {
        stage('Unit Tests') {
            steps {
                container('maven') {
                    sh 'mvn test'
                }
            }
        }
        stage('Static Analysis') {
            steps {
                container('maven') {
                    sh 'mvn sonar:sonar'
                }
            }
        }
        stage('Security Scan') {
            steps {
                container('maven') {
                    sh 'mvn dependency-check:check'
                }
            }
        }
    }
}
```

### Shared Libraries

Extract common functionality into shared libraries:

1. Create a Git repository for the shared library
2. Configure it in Jenkins under `Manage Jenkins > Configure System > Global Pipeline Libraries`

Example shared library structure:
```
vars/
├── dockerBuild.groovy
├── deploy.groovy
└── notify.groovy
```

Usage in Jenkinsfile:
```groovy
@Library('my-shared-library') _

pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                dockerBuild(
                    registry: 'your-docker-registry.com',
                    image: 'your-app-name',
                    tag: "${BUILD_NUMBER}"
                )
            }
        }
    }
}
```

### Conditional Execution

Execute stages based on conditions:

```groovy
stage('Deploy to Production') {
    when {
        allOf {
            branch 'main'
            environment name: 'DEPLOY_TO_PROD', value: 'true'
        }
    }
    steps {
        // deployment steps
    }
}
```

## Monitoring Your Pipeline

### Build History and Metrics

Access key metrics in Jenkins:

1. Build history and trends
2. Test results and coverage
3. SonarQube quality gates
4. Performance test results

### Pipeline Visualization

Use Blue Ocean for better visualization:

1. Click on "Open Blue Ocean" in the Jenkins UI
2. View the entire pipeline and stage details

### Notifications

Configure notifications:

```groovy
post {
    always {
        junit '**/target/surefire-reports/TEST-*.xml'
    }
    success {
        slackSend channel: '#deployments', 
                  color: 'good', 
                  message: "Deployment successful: ${APP_NAME}:${VERSION}"
    }
    failure {
        slackSend channel: '#deployments', 
                  color: 'danger', 
                  message: "Deployment failed: ${APP_NAME}:${VERSION}"
    }
}
```

## Hands-on Exercises

### Exercise 1: Create a Basic Jenkins Pipeline

1. Set up Jenkins locally or on a server
2. Create a simple Java/Maven project
3. Add a basic Jenkinsfile
4. Configure Jenkins to build the project

### Exercise 2: Add Unit Tests and Quality Gates

1. Add unit tests to your project
2. Configure SonarQube
3. Add test and analysis stages to the pipeline
4. Configure quality gates

### Exercise 3: Containerize Your Application

1. Create a Dockerfile for your application
2. Add Docker build and push stages
3. Configure Docker registry credentials
4. Test the container build

### Exercise 4: Implement Kubernetes Deployment

1. Create Kubernetes manifests
2. Add deployment stages for different environments
3. Configure Kubernetes credentials
4. Test the deployment process

### Exercise 5: Create a Complete CI/CD Pipeline

1. Combine all previous exercises
2. Add integration and performance tests
3. Implement manual approval for production
4. Configure notifications
5. Test the entire pipeline

## Troubleshooting

### Common Issues and Solutions

1. **Pipeline fails during checkout**
   - Check repository URL and credentials
   - Ensure Jenkins has access to the repository

2. **Build failures**
   - Check for compilation errors
   - Verify that the correct JDK/tools are installed

3. **Test failures**
   - Review test reports
   - Fix failing tests or update expectations

4. **Docker build issues**
   - Ensure Docker daemon is running
   - Check Dockerfile syntax
   - Verify registry credentials

5. **Kubernetes deployment failures**
   - Check kubeconfig and permissions
   - Verify that manifests are valid
   - Check for resource constraints

### Debugging Pipeline Scripts

1. Use the `sh "set -x"` command for verbose shell output
2. Add echo statements for debugging:
   ```groovy
   echo "Building image: ${DOCKER_REGISTRY}/${APP_NAME}:${VERSION}"
   ```

3. Use the Jenkins Script Console for advanced debugging

### Getting Help

- Check Jenkins logs
- Review pipeline syntax at https://jenkins.io/doc/book/pipeline/syntax/
- Use the Jenkins community forums and Stack Overflow
- Consult the documentation for specific plugins

## Additional Resources

- [Jenkins Pipeline Documentation](https://jenkins.io/doc/book/pipeline/)
- [Jenkins Pipeline Examples](https://github.com/jenkinsci/pipeline-examples)
- [Jenkins Shared Libraries](https://jenkins.io/doc/book/pipeline/shared-libraries/)
- [Blue Ocean Documentation](https://jenkins.io/doc/book/blueocean/)
- [Kubernetes Plugin Documentation](https://plugins.jenkins.io/kubernetes/)
