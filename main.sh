#!/bin/bash

# Define variables
AWS_PROFILE="raj-private"
AWS_REGION="us-west-2"
EKS_CLUSTER="demo-eks-cluster"
ARGOCD_NAMESPACE="argocd"
ARGOCD_REPO_URL="https://github.com/argoproj/argo-cd.git"

# Configure kubectl to use AWS profile and EKS cluster
echo "Configuring kubectl to use AWS profile $AWS_PROFILE, region $AWS_REGION, and EKS cluster $EKS_CLUSTER..."
aws eks --region $AWS_REGION --profile $AWS_PROFILE update-kubeconfig --name $EKS_CLUSTER

# Create Argo CD namespace
echo "Creating Argo CD namespace..."
kubectl create namespace $ARGOCD_NAMESPACE || echo "Namespace '$ARGOCD_NAMESPACE' already exists. Skipping creation."

# Install Argo CD
echo "Checking if Argo CD is already installed..."
if kubectl get all -n $ARGOCD_NAMESPACE > /dev/null 2>&1; then
  echo "Argo CD is already installed."
else
  echo "Installing Argo CD..."
  kubectl apply -n $ARGOCD_NAMESPACE -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
fi

# Wait for Argo CD components to be ready
echo "Waiting for Argo CD components to be ready..."
kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n $ARGOCD_NAMESPACE
kubectl wait --for=condition=available --timeout=600s deployment/argocd-repo-server -n $ARGOCD_NAMESPACE
kubectl wait --for=condition=available --timeout=600s deployment/argocd-dex-server -n $ARGOCD_NAMESPACE
kubectl wait --for=condition=available --timeout=600s deployment/argocd-application-controller -n $ARGOCD_NAMESPACE

# Set up port forwarding for Argo CD UI
echo "Setting up port forwarding for Argo CD UI on port 8081..."
kubectl port-forward svc/argocd-server -n $ARGOCD_NAMESPACE 8081:443 &

# Get Argo CD initial admin password
echo "Retrieving initial admin password..."
ARGOCD_PASSWORD=$(kubectl get secret argocd-initial-admin-secret -n $ARGOCD_NAMESPACE -o jsonpath='{.data.password}' | base64 --decode)

# Print setup information
echo "Argo CD has been installed."
echo "You can access the Argo CD UI at https://localhost:8081."
echo "Use the username 'admin' and the retrieved password to log in."
echo "Argo CD initial admin password: $ARGOCD_PASSWORD"

# Notify user of potential issues with port forwarding
echo "If you encounter issues accessing Argo CD at https://localhost:8081, consider checking for port conflicts or using alternative methods to access Argo CD."

echo "Setup complete!"
