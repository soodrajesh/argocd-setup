#!/bin/bash

# Set variables
ARGOCD_NAMESPACE="argocd"
ARGOCD_INSTALL_URL="https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
AWS_PROFILE="raj-private"
AWS_REGION="us-west-2"  # Replace with your AWS region
EKS_CLUSTER_NAME="demo-eks-cluster"  # Replace with your EKS cluster name

# Function to print error and exit
error_exit() {
    echo "$1" 1>&2
    exit 1
}

# Set AWS profile environment variable
export AWS_PROFILE=$AWS_PROFILE

# Authenticate kubectl with AWS profile, region, and EKS cluster
echo "Configuring kubectl to use AWS profile $AWS_PROFILE, region $AWS_REGION, and EKS cluster $EKS_CLUSTER_NAME..."
aws eks update-kubeconfig --name $EKS_CLUSTER_NAME --region $AWS_REGION --profile $AWS_PROFILE || error_exit "Failed to configure kubectl."

# Delete Argo CD resources if they exist
echo "Deleting Argo CD resources..."
kubectl delete -n $ARGOCD_NAMESPACE -f $ARGOCD_INSTALL_URL || error_exit "Failed to delete Argo CD resources."

# Optionally, delete the Argo CD namespace
echo "Deleting Argo CD namespace..."
kubectl delete namespace $ARGOCD_NAMESPACE || error_exit "Failed to delete namespace."

echo "Cleanup complete!"
