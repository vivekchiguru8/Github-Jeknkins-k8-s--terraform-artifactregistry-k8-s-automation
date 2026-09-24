pipeline {
    agent any
    environment {
        PROJECT_ID = "project-10094705-9153-43d5-bb8"
        REGISTRY = "asia-south1-docker.pkg.dev/project-10094705-9153-43d5-bb8/my-app-repo/go-app"
        CLUSTER = "my-go-cluster"
        ZONE = "asia-south1-a"
        NAMESPACE = "go-app"
    }
    parameters {
        choice(name: 'ACTION', choices: ['apply', 'destroy'], description: 'Choose apply or destroy')
    }
    stages {
        stage('Setup Tools Check') {
            steps {
                sh '''
                  set -e
                  # Ensure gcloud in PATH (if installed in /tmp)
                  export PATH=/tmp/google-cloud-sdk/bin:/usr/local/bin:/tmp:$PATH
                  if ! command -v gcloud >/dev/null 2>&1; then
                    echo "Installing gcloud..."
                    curl -sSL https://sdk.cloud.google.com | bash -s -- --disable-prompts --install-dir=/tmp
                    export PATH=/tmp/google-cloud-sdk/bin:$PATH
                  fi
                  if ! command -v terraform >/dev/null 2>&1; then
                    echo "Installing terraform..."
                    wget -q https://releases.hashicorp.com/terraform/1.8.5/terraform_1.8.5_linux_amd64.zip -O /tmp/tf.zip
                    unzip -o /tmp/tf.zip -d /tmp/
                    chmod +x /tmp/terraform
                    sudo mv /tmp/terraform /usr/local/bin/ 2>/dev/null || mv /tmp/terraform /usr/local/bin/terraform 2>/dev/null || true
                    export PATH=/tmp:$PATH
                  fi
                  gcloud --version || /tmp/google-cloud-sdk/bin/gcloud --version
                  terraform version || /tmp/terraform version
                  docker --version || echo "docker not found - will use kaniko or fail"
                  kubectl version --client || gcloud components install kubectl --quiet
                '''
            }
        }

        stage('Terraform Apply Infra') {
            when { expression { params.ACTION == 'apply' } }
            steps {
                sh '''
                  export PATH=/tmp/google-cloud-sdk/bin:/tmp:$PATH
                  gcloud config set project $PROJECT_ID --quiet
                  terraform init -reconfigure
                  terraform apply -auto-approve
                '''
            }
        }

        stage('Build & Push Go App') {
            when { expression { params.ACTION == 'apply' } }
            steps {
                sh '''
                  export PATH=/tmp/google-cloud-sdk/bin:/tmp:$PATH
                  gcloud auth configure-docker asia-south1-docker.pkg.dev --quiet
                  gcloud container clusters get-credentials $CLUSTER --zone $ZONE --project $PROJECT_ID || gcloud container clusters get-credentials jenkins-cluster --zone $ZONE --project $PROJECT_ID
                  docker build -t $REGISTRY:$BUILD_NUMBER -t $REGISTRY:latest .
                  docker push $REGISTRY:$BUILD_NUMBER
                  docker push $REGISTRY:latest
                '''
            }
        }

        stage('Deploy to GKE') {
            when { expression { params.ACTION == 'apply' } }
            steps {
                sh '''
                  export PATH=/tmp/google-cloud-sdk/bin:/tmp:$PATH
                  gcloud container clusters get-credentials $CLUSTER --zone $ZONE --project $PROJECT_ID || gcloud container clusters get-credentials jenkins-cluster --zone $ZONE --project $PROJECT_ID
                  
                  kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
                  kubectl -n $NAMESPACE create deployment go-app --image=$REGISTRY:$BUILD_NUMBER --port=8080 --dry-run=client -o yaml | kubectl apply -f -
                  kubectl -n $NAMESPACE set image deployment/go-app go-app=$REGISTRY:$BUILD_NUMBER || true
                  kubectl -n $NAMESPACE set env deployment/go-app PORT=8080 || true
                  kubectl -n $NAMESPACE scale deployment go-app --replicas=2
                  kubectl -n $NAMESPACE rollout status deployment/go-app --timeout=300s
                  kubectl -n $NAMESPACE expose deployment go-app --name=go-app-service --type=LoadBalancer --port=80 --target-port=8080 --dry-run=client -o yaml | kubectl apply -f -
                  kubectl get pods,svc -n $NAMESPACE
                '''
            }
        }

        stage('Terraform Destroy Infra') {
            when { expression { params.ACTION == 'destroy' } }
            steps {
                sh '''
                  export PATH=/tmp/google-cloud-sdk/bin:/tmp:$PATH
                  gcloud container clusters get-credentials $CLUSTER --zone $ZONE --project $PROJECT_ID || true
                  kubectl delete svc go-app-service -n $NAMESPACE --ignore-not-found=true || true
                  kubectl delete deployment go-app -n $NAMESPACE --ignore-not-found=true || true
                  terraform init -reconfigure
                  terraform destroy -auto-approve
                '''
            }
        }
    }
}
