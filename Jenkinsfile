pipeline {
    agent any
    environment {
        PROJECT_ID = "project-10094705-9153-43d5-bb8"
        REGISTRY = "asia-south1-docker.pkg.dev/project-10094705-9153-43d5-bb8/my-app-repo/go-app"
        CLUSTER = "my-go-cluster"
        ZONE = "asia-south1-a"
    }
    parameters {
        choice(name: 'ACTION', choices: ['apply', 'destroy'], description: 'Choose apply or destroy')
    }
    stages {
        // No Checkout stage needed - SCM does it

        stage('Terraform Apply Infra') {
            when { expression { params.ACTION == 'apply' } }
            steps {
                sh '''
                  gcloud config set project $PROJECT_ID --quiet
                  terraform init
                  terraform apply -auto-approve
                '''
            }
        }

        stage('Build & Push Go App') {
            when { expression { params.ACTION == 'apply' } }
            steps {
                sh '''
                  gcloud auth configure-docker asia-south1-docker.pkg.dev --quiet
                  gcloud container clusters get-credentials $CLUSTER --zone $ZONE --project $PROJECT_ID
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
                  gcloud container clusters get-credentials $CLUSTER --zone $ZONE --project $PROJECT_ID
                  kubectl create deployment go-app --image=$REGISTRY:$BUILD_NUMBER --port=8080 --dry-run=client -o yaml | kubectl apply -f -
                  kubectl set image deployment/go-app go-app=$REGISTRY:$BUILD_NUMBER
                  kubectl set env deployment/go-app PORT=8080
                  kubectl scale deployment go-app --replicas=2
                  kubectl rollout status deployment/go-app --timeout=180s
                  kubectl expose deployment go-app --name=go-app-service --type=LoadBalancer --port=80 --target-port=8080 --dry-run=client -o yaml | kubectl apply -f -
                  kubectl get pods
                  kubectl get svc go-app-service
                '''
            }
        }

        stage('Terraform Destroy Infra') {
            when { expression { params.ACTION == 'destroy' } }
            steps {
                sh '''
                  gcloud container clusters get-credentials $CLUSTER --zone $ZONE --project $PROJECT_ID || true
                  kubectl delete svc go-app-service --ignore-not-found=true || true
                  kubectl delete deployment go-app --ignore-not-found=true || true
                  terraform init
                  terraform destroy -auto-approve
                '''
            }
        }
    }
}
