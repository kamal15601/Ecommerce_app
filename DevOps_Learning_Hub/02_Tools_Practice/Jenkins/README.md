# Jenkins CI/CD Hands-On Labs 🚀

## Overview
Jenkins is an open-source automation server that enables developers to build, test, and deploy applications efficiently. This comprehensive guide provides hands-on labs from basic setup to advanced enterprise-grade CI/CD pipelines.

## Prerequisites
- Docker installed
- Git installed
- Basic knowledge of CI/CD concepts
- GitHub/GitLab account

## Labs Structure

### Lab 1: Jenkins Installation and Setup

#### Option 1: Docker Installation
```bash
# Pull Jenkins LTS image
docker pull jenkins/jenkins:lts

# Create Jenkins volume
docker volume create jenkins_home

# Run Jenkins container
docker run -d \
  --name jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts

# Get initial admin password
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

#### Option 2: Kubernetes Deployment
```yaml
# jenkins-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jenkins
spec:
  replicas: 1
  selector:
    matchLabels:
      app: jenkins
  template:
    metadata:
      labels:
        app: jenkins
    spec:
      containers:
      - name: jenkins
        image: jenkins/jenkins:lts
        ports:
        - containerPort: 8080
        - containerPort: 50000
        volumeMounts:
        - name: jenkins-home
          mountPath: /var/jenkins_home
        env:
        - name: JAVA_OPTS
          value: "-Djenkins.install.runSetupWizard=false"
      volumes:
      - name: jenkins-home
        persistentVolumeClaim:
          claimName: jenkins-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: jenkins-service
spec:
  selector:
    app: jenkins
  ports:
  - name: http
    port: 8080
    targetPort: 8080
  - name: jnlp
    port: 50000
    targetPort: 50000
  type: LoadBalancer
```

#### Initial Setup Steps
1. Access Jenkins at `http://localhost:8080`
2. Enter initial admin password
3. Install suggested plugins
4. Create admin user
5. Configure Jenkins URL

### Lab 2: First Pipeline Job

#### Freestyle Project
1. **Create New Item** → **Freestyle project**
2. **Source Code Management** → **Git**
3. **Repository URL**: `https://github.com/your-username/sample-app`
4. **Build Triggers** → **Poll SCM**: `H/5 * * * *`
5. **Build Steps** → **Execute shell**:

```bash
#!/bin/bash
echo "Starting build process..."
npm install
npm test
npm run build
echo "Build completed successfully!"
```

#### Pipeline as Code (Jenkinsfile)
```groovy
pipeline {
    agent any
    
    stages {
        stage('Checkout') {
            steps {
                git 'https://github.com/your-username/sample-app.git'
            }
        }
        
        stage('Build') {
            steps {
                sh 'npm install'
            }
        }
        
        stage('Test') {
            steps {
                sh 'npm test'
            }
        }
        
        stage('Deploy') {
            steps {
                sh 'npm run build'
                archiveArtifacts artifacts: 'dist/**/*', allowEmptyArchive: true
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
```

### Lab 3: Multi-Branch Pipeline

#### Setup Multi-Branch Pipeline
1. **New Item** → **Multibranch Pipeline**
2. **Branch Sources** → **Git**
3. **Repository URL**: `https://github.com/your-username/sample-app`
4. **Credentials**: Add GitHub credentials
5. **Scan Multibranch Pipeline Triggers**: Every minute

#### Advanced Jenkinsfile
```groovy
pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = "myapp:${env.BUILD_NUMBER}"
        REGISTRY_URL = "docker.io/myusername"
    }
    
    stages {
        stage('Preparation') {
            steps {
                script {
                    env.GIT_COMMIT_SHORT = sh(
                        script: "git rev-parse --short HEAD",
                        returnStdout: true
                    ).trim()
                }
            }
        }
        
        stage('Code Quality') {
            parallel {
                stage('Lint') {
                    steps {
                        sh 'npm run lint'
                    }
                }
                stage('Security Scan') {
                    steps {
                        sh 'npm audit'
                    }
                }
            }
        }
        
        stage('Build & Test') {
            steps {
                sh 'npm install'
                sh 'npm run build'
                sh 'npm test'
            }
            post {
                always {
                    publishTestResults testResultsPattern: 'test-results.xml'
                    publishHTML([
                        allowMissing: false,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'coverage',
                        reportFiles: 'index.html',
                        reportName: 'Coverage Report'
                    ])
                }
            }
        }
        
        stage('Docker Build') {
            when {
                anyOf {
                    branch 'main'
                    branch 'develop'
                }
            }
            steps {
                script {
                    docker.build("${DOCKER_IMAGE}")
                }
            }
        }
        
        stage('Deploy') {
            when {
                branch 'main'
            }
            steps {
                script {
                    docker.withRegistry("https://${REGISTRY_URL}", 'docker-hub-credentials') {
                        docker.image("${DOCKER_IMAGE}").push()
                        docker.image("${DOCKER_IMAGE}").push("latest")
                    }
                }
                
                // Deploy to staging
                sh '''
                    kubectl set image deployment/myapp-staging \
                        myapp=${REGISTRY_URL}/${DOCKER_IMAGE} \
                        --namespace=staging
                '''
            }
        }
        
        stage('Production Deploy') {
            when {
                branch 'main'
            }
            steps {
                input message: 'Deploy to production?', ok: 'Deploy'
                
                sh '''
                    kubectl set image deployment/myapp-production \
                        myapp=${REGISTRY_URL}/${DOCKER_IMAGE} \
                        --namespace=production
                '''
            }
        }
    }
    
    post {
        success {
            slackSend(
                channel: '#deployments',
                color: 'good',
                message: "✅ Build ${env.BUILD_NUMBER} succeeded for ${env.BRANCH_NAME}"
            )
        }
        failure {
            slackSend(
                channel: '#deployments',
                color: 'danger',
                message: "❌ Build ${env.BUILD_NUMBER} failed for ${env.BRANCH_NAME}"
            )
        }
    }
}
```

### Lab 4: Jenkins Agents and Distributed Builds

#### Setting up Jenkins Agents
**Docker Agent:**
```groovy
pipeline {
    agent {
        docker {
            image 'node:16'
            args '-v /var/run/docker.sock:/var/run/docker.sock'
        }
    }
    
    stages {
        stage('Build') {
            steps {
                sh 'npm install'
                sh 'npm run build'
            }
        }
    }
}
```

**Kubernetes Agent:**
```groovy
pipeline {
    agent {
        kubernetes {
            yaml '''
                apiVersion: v1
                kind: Pod
                spec:
                  containers:
                  - name: node
                    image: node:16
                    command:
                    - sleep
                    args:
                    - 99d
                  - name: docker
                    image: docker:dind
                    securityContext:
                      privileged: true
                    volumeMounts:
                    - name: docker-sock
                      mountPath: /var/run/docker.sock
                  volumes:
                  - name: docker-sock
                    hostPath:
                      path: /var/run/docker.sock
            '''
        }
    }
    
    stages {
        stage('Build') {
            steps {
                container('node') {
                    sh 'npm install'
                    sh 'npm run build'
                }
            }
        }
        
        stage('Docker Build') {
            steps {
                container('docker') {
                    sh 'docker build -t myapp .'
                }
            }
        }
    }
}
```

### Lab 5: Pipeline Libraries and Shared Code

#### Creating Shared Library
**vars/buildDockerImage.groovy:**
```groovy
def call(String imageName, String dockerfile = 'Dockerfile') {
    script {
        def image = docker.build("${imageName}:${env.BUILD_NUMBER}", "-f ${dockerfile} .")
        return image
    }
}
```

**vars/deployToKubernetes.groovy:**
```groovy
def call(Map config) {
    script {
        sh """
            kubectl set image deployment/${config.deployment} \
                ${config.container}=${config.image} \
                --namespace=${config.namespace}
            
            kubectl rollout status deployment/${config.deployment} \
                --namespace=${config.namespace} \
                --timeout=300s
        """
    }
}
```

**Using Shared Library:**
```groovy
@Library('jenkins-shared-library') _

pipeline {
    agent any
    
    stages {
        stage('Build Docker Image') {
            steps {
                script {
                    def image = buildDockerImage('myapp')
                    env.DOCKER_IMAGE = image.id
                }
            }
        }
        
        stage('Deploy') {
            steps {
                deployToKubernetes([
                    deployment: 'myapp',
                    container: 'app',
                    image: env.DOCKER_IMAGE,
                    namespace: 'production'
                ])
            }
        }
    }
}
```

### Lab 6: Blue-Green Deployment Pipeline

```groovy
pipeline {
    agent any
    
    environment {
        APP_NAME = 'myapp'
        NAMESPACE = 'production'
        NEW_VERSION = "${env.BUILD_NUMBER}"
    }
    
    stages {
        stage('Determine Current Color') {
            steps {
                script {
                    def currentColor = sh(
                        script: "kubectl get service ${APP_NAME} -n ${NAMESPACE} -o jsonpath='{.spec.selector.color}'",
                        returnStdout: true
                    ).trim()
                    
                    env.CURRENT_COLOR = currentColor ?: 'blue'
                    env.NEW_COLOR = (currentColor == 'blue') ? 'green' : 'blue'
                    
                    echo "Current color: ${env.CURRENT_COLOR}"
                    echo "New color: ${env.NEW_COLOR}"
                }
            }
        }
        
        stage('Deploy New Version') {
            steps {
                sh '''
                    # Update deployment with new color and version
                    kubectl patch deployment ${APP_NAME}-${NEW_COLOR} \
                        -n ${NAMESPACE} \
                        -p '{"spec":{"template":{"spec":{"containers":[{"name":"app","image":"myapp:'${NEW_VERSION}'"}]},"metadata":{"labels":{"version":"'${NEW_VERSION}'"}}}}}'
                    
                    # Wait for rollout
                    kubectl rollout status deployment/${APP_NAME}-${NEW_COLOR} -n ${NAMESPACE}
                '''
            }
        }
        
        stage('Health Check') {
            steps {
                script {
                    def healthCheck = sh(
                        script: "kubectl run health-check-${NEW_VERSION} --image=curlimages/curl --rm -i --restart=Never -- curl -f http://${APP_NAME}-${NEW_COLOR}.${NAMESPACE}.svc.cluster.local/health",
                        returnStatus: true
                    )
                    
                    if (healthCheck != 0) {
                        error("Health check failed for ${NEW_COLOR} deployment")
                    }
                }
            }
        }
        
        stage('Switch Traffic') {
            steps {
                input message: "Switch traffic to ${NEW_COLOR}?", ok: 'Switch'
                
                sh '''
                    # Update service selector to point to new color
                    kubectl patch service ${APP_NAME} \
                        -n ${NAMESPACE} \
                        -p '{"spec":{"selector":{"color":"'${NEW_COLOR}'"}}}'
                '''
            }
        }
        
        stage('Cleanup Old Version') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    input message: "Delete old ${CURRENT_COLOR} deployment?", ok: 'Delete'
                }
                
                sh '''
                    kubectl scale deployment ${APP_NAME}-${CURRENT_COLOR} \
                        --replicas=0 -n ${NAMESPACE}
                '''
            }
        }
    }
    
    post {
        failure {
            sh '''
                # Rollback on failure
                kubectl patch service ${APP_NAME} \
                    -n ${NAMESPACE} \
                    -p '{"spec":{"selector":{"color":"'${CURRENT_COLOR}'"}}}'
            '''
        }
    }
}
```

### Lab 7: Security and Compliance

#### Security Scanning Pipeline
```groovy
pipeline {
    agent any
    
    stages {
        stage('Code Security Scan') {
            parallel {
                stage('SAST - SonarQube') {
                    steps {
                        withSonarQubeEnv('SonarQube') {
                            sh 'sonar-scanner'
                        }
                        
                        timeout(time: 10, unit: 'MINUTES') {
                            waitForQualityGate abortPipeline: true
                        }
                    }
                }
                
                stage('Dependency Check') {
                    steps {
                        sh 'npm audit --audit-level high'
                        
                        // OWASP Dependency Check
                        dependencyCheck additionalArguments: '--format XML --format HTML', odcInstallation: 'OWASP-DC'
                        dependencyCheckPublisher pattern: 'dependency-check-report.xml'
                    }
                }
                
                stage('Secret Scanning') {
                    steps {
                        sh '''
                            # Use truffleHog for secret detection
                            docker run --rm -v $(pwd):/pwd \
                                trufflesecurity/trufflehog:latest \
                                filesystem /pwd \
                                --json > secrets-report.json
                        '''
                        
                        script {
                            def secretsFound = sh(
                                script: "jq '.[] | select(.verified == true)' secrets-report.json | wc -l",
                                returnStdout: true
                            ).trim()
                            
                            if (secretsFound.toInteger() > 0) {
                                error("Secrets found in code!")
                            }
                        }
                    }
                }
            }
        }
        
        stage('Container Security') {
            steps {
                script {
                    // Build image
                    def image = docker.build("myapp:${env.BUILD_NUMBER}")
                    
                    // Scan with Trivy
                    sh """
                        docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
                            aquasec/trivy image \
                            --format json \
                            --output trivy-report.json \
                            --severity CRITICAL,HIGH \
                            myapp:${env.BUILD_NUMBER}
                    """
                    
                    // Parse results
                    def trivyReport = readJSON file: 'trivy-report.json'
                    if (trivyReport.Results && trivyReport.Results.size() > 0) {
                        def vulnerabilities = trivyReport.Results[0].Vulnerabilities ?: []
                        def criticalVulns = vulnerabilities.findAll { it.Severity == 'CRITICAL' }
                        
                        if (criticalVulns.size() > 0) {
                            error("Critical vulnerabilities found: ${criticalVulns.size()}")
                        }
                    }
                }
            }
        }
        
        stage('Infrastructure Security') {
            steps {
                // Terraform security scan
                sh '''
                    # Install tfsec
                    curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash
                    
                    # Scan Terraform files
                    tfsec ./terraform --format json --out tfsec-report.json
                '''
                
                // Kubernetes manifest security
                sh '''
                    # Use kubesec for K8s manifest scanning
                    docker run --rm -v $(pwd):/data \
                        kubesec/kubesec:latest \
                        scan /data/k8s/*.yaml > kubesec-report.json
                '''
            }
        }
    }
    
    post {
        always {
            // Archive security reports
            archiveArtifacts artifacts: '*-report.json', allowEmptyArchive: true
            
            // Publish reports
            publishHTML([
                allowMissing: false,
                alwaysLinkToLastBuild: true,
                keepAll: true,
                reportDir: 'dependency-check-report',
                reportFiles: 'dependency-check-report.html',
                reportName: 'OWASP Dependency Check'
            ])
        }
    }
}
```

### Lab 8: Monitoring and Observability

#### Pipeline with Monitoring
```groovy
pipeline {
    agent any
    
    environment {
        PROMETHEUS_URL = 'http://prometheus:9090'
        GRAFANA_URL = 'http://grafana:3000'
    }
    
    stages {
        stage('Deploy with Monitoring') {
            steps {
                sh '''
                    # Deploy application with monitoring
                    kubectl apply -f k8s/app-deployment.yaml
                    kubectl apply -f k8s/service-monitor.yaml
                    
                    # Wait for deployment
                    kubectl rollout status deployment/myapp
                '''
                
                // Send deployment event to monitoring
                sh '''
                    curl -X POST ${PROMETHEUS_URL}/api/v1/alerts \
                        -H "Content-Type: application/json" \
                        -d '{
                            "alerts": [{
                                "labels": {
                                    "alertname": "DeploymentStarted",
                                    "service": "myapp",
                                    "version": "'${BUILD_NUMBER}'"
                                },
                                "annotations": {
                                    "summary": "Deployment started for myapp",
                                    "description": "Build '${BUILD_NUMBER}' deployment initiated"
                                }
                            }]
                        }'
                '''
            }
        }
        
        stage('Performance Testing') {
            steps {
                sh '''
                    # Run load test with k6
                    docker run --rm -v $(pwd):/data \
                        grafana/k6 run /data/load-test.js \
                        --out influxdb=http://influxdb:8086/k6
                '''
                
                // Check performance metrics
                script {
                    def response = sh(
                        script: """
                            curl -s '${PROMETHEUS_URL}/api/v1/query?query=rate(http_requests_total[5m])' | \
                            jq -r '.data.result[0].value[1]'
                        """,
                        returnStdout: true
                    ).trim()
                    
                    def requestRate = response.toFloat()
                    if (requestRate < 100) {
                        error("Performance threshold not met: ${requestRate} req/s")
                    }
                }
            }
        }
        
        stage('Health Monitoring') {
            steps {
                script {
                    // Monitor deployment health for 5 minutes
                    for (int i = 0; i < 10; i++) {
                        def healthStatus = sh(
                            script: "kubectl get pods -l app=myapp -o jsonpath='{.items[*].status.phase}'",
                            returnStdout: true
                        ).trim()
                        
                        if (healthStatus.contains('Failed')) {
                            error("Pod failure detected during health monitoring")
                        }
                        
                        sleep(30)
                    }
                }
            }
        }
    }
    
    post {
        always {
            // Send deployment completion event
            sh '''
                curl -X POST ${PROMETHEUS_URL}/api/v1/alerts \
                    -H "Content-Type: application/json" \
                    -d '{
                        "alerts": [{
                            "labels": {
                                "alertname": "DeploymentCompleted",
                                "service": "myapp",
                                "version": "'${BUILD_NUMBER}'",
                                "status": "'${currentBuild.result ?: 'SUCCESS'}'"
                            }
                        }]
                    }'
            '''
        }
        
        success {
            // Create Grafana annotation
            sh '''
                curl -X POST ${GRAFANA_URL}/api/annotations \
                    -H "Content-Type: application/json" \
                    -H "Authorization: Bearer ${GRAFANA_API_KEY}" \
                    -d '{
                        "text": "Deployment v'${BUILD_NUMBER}' successful",
                        "tags": ["deployment", "success"],
                        "time": '$(date +%s000)'
                    }'
            '''
        }
    }
}
```

### Lab 9: Advanced Pipeline Patterns

#### Matrix Builds
```groovy
pipeline {
    agent none
    
    stages {
        stage('Matrix Build') {
            matrix {
                axes {
                    axis {
                        name 'NODE_VERSION'
                        values '14', '16', '18'
                    }
                    axis {
                        name 'OS'
                        values 'linux', 'windows'
                    }
                }
                stages {
                    stage('Build & Test') {
                        agent {
                            docker {
                                image "node:${NODE_VERSION}"
                                label "${OS}"
                            }
                        }
                        steps {
                            sh 'npm install'
                            sh 'npm test'
                        }
                    }
                }
            }
        }
    }
}
```

#### Fan-out/Fan-in Pattern
```groovy
pipeline {
    agent any
    
    stages {
        stage('Fan-out') {
            parallel {
                stage('Service A') {
                    steps {
                        build job: 'service-a-pipeline', 
                              parameters: [string(name: 'VERSION', value: env.BUILD_NUMBER)]
                    }
                }
                stage('Service B') {
                    steps {
                        build job: 'service-b-pipeline', 
                              parameters: [string(name: 'VERSION', value: env.BUILD_NUMBER)]
                    }
                }
                stage('Service C') {
                    steps {
                        build job: 'service-c-pipeline', 
                              parameters: [string(name: 'VERSION', value: env.BUILD_NUMBER)]
                    }
                }
            }
        }
        
        stage('Fan-in - Integration Test') {
            steps {
                script {
                    // All services built, now run integration tests
                    build job: 'integration-test-pipeline',
                          parameters: [string(name: 'VERSION', value: env.BUILD_NUMBER)]
                }
            }
        }
        
        stage('Deploy All') {
            steps {
                script {
                    // Deploy all services together
                    def services = ['service-a', 'service-b', 'service-c']
                    def deployJobs = [:]
                    
                    services.each { service ->
                        deployJobs[service] = {
                            build job: "${service}-deploy",
                                  parameters: [string(name: 'VERSION', value: env.BUILD_NUMBER)]
                        }
                    }
                    
                    parallel deployJobs
                }
            }
        }
    }
}
```

### Lab 10: Jenkins Configuration as Code (JCasC)

#### jenkins.yaml
```yaml
jenkins:
  systemMessage: "Jenkins configured automatically by Jenkins Configuration as Code plugin"
  
  globalNodeProperties:
  - envVars:
      env:
      - key: "DOCKER_REGISTRY"
        value: "docker.io"
      - key: "KUBERNETES_NAMESPACE"
        value: "default"

  securityRealm:
    local:
      allowsSignup: false
      users:
      - id: "admin"
        password: "${JENKINS_ADMIN_PASSWORD}"

  authorizationStrategy:
    globalMatrix:
      permissions:
      - "Overall/Administer:admin"
      - "Overall/Read:authenticated"

  remotingSecurity:
    enabled: true

tool:
  git:
    installations:
    - name: "Default"
      home: "git"

  nodejs:
    installations:
    - name: "NodeJS 16"
      properties:
      - installSource:
          installers:
          - nodeJSInstaller:
              id: "16.17.0"
              npmPackagesRefreshHours: 72

  dockerTool:
    installations:
    - name: "Docker"
      properties:
      - installSource:
          installers:
          - dockerInstaller:
              version: "latest"

credentials:
  system:
    domainCredentials:
    - credentials:
      - usernamePassword:
          scope: GLOBAL
          id: "docker-hub"
          username: "${DOCKER_USERNAME}"
          password: "${DOCKER_PASSWORD}"
      - string:
          scope: GLOBAL
          id: "slack-token"
          secret: "${SLACK_TOKEN}"

unclassified:
  location:
    url: "http://jenkins.example.com"
    adminAddress: "admin@example.com"
    
  slackNotifier:
    teamDomain: "myteam"
    token: "${SLACK_TOKEN}"
    
  globalLibraries:
    libraries:
    - name: "shared-library"
      defaultVersion: "main"
      retriever:
        modernSCM:
          scm:
            git:
              remote: "https://github.com/myorg/jenkins-shared-library.git"

jobs:
  - script: |
      multibranchPipelineJob('my-app-pipeline') {
          branchSources {
              git {
                  remote('https://github.com/myorg/my-app.git')
                  credentialsId('github-credentials')
              }
          }
          configure { node ->
              node / sources / 'data' / 'jenkins.branch.BranchSource' / source / traits << 'jenkins.plugins.git.traits.BranchDiscoveryTrait' {
                  strategyId(1)
              }
          }
      }
```

## Best Practices

### 1. Pipeline Design
- Keep pipelines simple and readable
- Use declarative syntax when possible
- Implement proper error handling
- Use parallel stages for independent tasks

### 2. Security
```groovy
// Use credentials securely
withCredentials([usernamePassword(credentialsId: 'docker-hub', 
                                  usernameVariable: 'DOCKER_USER', 
                                  passwordVariable: 'DOCKER_PASS')]) {
    sh 'docker login -u $DOCKER_USER -p $DOCKER_PASS'
}

// Mask sensitive output
script {
    env.API_KEY = sh(script: 'vault kv get -field=api_key secret/myapp', returnStdout: true).trim()
    echo "API Key: ${env.API_KEY.take(8)}..."  // Only show first 8 chars
}
```

### 3. Performance Optimization
- Use agent labels effectively
- Implement proper caching strategies
- Clean up workspaces
- Use appropriate timeouts

### 4. Monitoring and Alerts
- Implement comprehensive logging
- Set up notifications for failures
- Monitor pipeline performance
- Track deployment metrics

## Troubleshooting

### Common Issues

#### Build Failures
```bash
# Debug workspace issues
echo "Current directory: $(pwd)"
echo "Directory contents:"
ls -la

# Check environment variables
printenv | sort

# Debug agent connectivity
echo "Agent name: ${env.NODE_NAME}"
echo "Agent labels: ${env.NODE_LABELS}"
```

#### Plugin Conflicts
```groovy
// Check plugin versions
script {
    def pluginManager = Jenkins.instance.pluginManager
    def plugins = pluginManager.getPlugins()
    
    plugins.each { plugin ->
        echo "${plugin.getShortName()}: ${plugin.getVersion()}"
    }
}
```

#### Performance Issues
```groovy
// Monitor pipeline timing
timestamps {
    milestone 1
    stage('Build') {
        timeout(time: 10, unit: 'MINUTES') {
            // Build steps
        }
    }
    milestone 2
}
```

## Integration Examples

### Jenkins + ArgoCD
```groovy
stage('GitOps Update') {
    steps {
        git credentialsId: 'github-token', url: 'https://github.com/myorg/k8s-manifests'
        
        sh """
            # Update image tag in Kustomization
            cd overlays/production
            kustomize edit set image myapp=myapp:${BUILD_NUMBER}
            
            # Commit and push
            git add .
            git commit -m "Update myapp to version ${BUILD_NUMBER}"
            git push origin main
        """
    }
}
```

### Jenkins + Terraform
```groovy
stage('Infrastructure') {
    steps {
        withCredentials([azureServicePrincipal('azure-sp')]) {
            sh '''
                terraform init
                terraform plan -out=tfplan
                terraform apply tfplan
            '''
        }
    }
}
```

This comprehensive Jenkins guide provides hands-on experience with real-world CI/CD scenarios, security practices, and enterprise-grade pipeline patterns.
