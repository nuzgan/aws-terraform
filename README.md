# aws-terraform


## Getting started

First, go to the vpc_ec2 folder and run the following commands:

```
terraform init
terraform plan
terraform apply -auto-approve
```

Once the first step is complete, add the obtained vpc and subnet IDs to the main.tf file in the eks folder and repeat the above commands

After completing the second step, run the following command to access the EKS cluster from your local area
> [!NOTE]  
> aws cli must be downloaded for this.

```
aws eks update-kubeconfig --region {your_region} --name {cluster_name}
```
After the cluster connection is completed, we can deploy and test the nginx container using the following commands:
> [!NOTE]  
> kubectl must be downloaded for this.

```
kubectl create deployment nginx-project --image=nginx
kubectl create service nodeport nginx-project --tcp=80:80
```

You can also destroy the whole terraform-managed resources after testing with:
```
terraform destroy
```
