# Follwing Docs learning: https://docs.microsoft.com/en-us/learn/modules/deploy-kubernetes/3-set-up-environment

az account list-locations \
  --query "[].{Name: name, DisplayName: displayName}" \
  --output table

az configure --defaults location=eastus

# Create Bash variables

# generate a random number. This will make it easier to create globally unique names for certain services in the next step.
resourceSuffix=$RANDOM

# Create globally unique names for your Azure Container Registry and Azure Kubernetes Service instance. Note that these commands use double quotes, which instructs Bash to interpolate the variables using the inline syntax.
registryName="tailspinspacegame$resourceSuffix"
aksName="tailspinspacegame$resourceSuffix"

# Create another Bash variable to store the name of your resource group.
rgName='tailspin-space-game-rg'

#Create a variable to hold the latest AKS version available in your default region.
aksVersion=$(az aks get-versions \
  --query 'orchestrators[-1].orchestratorVersion' \
  --output tsv)

  # Create the Azure resources

# create a resource group using the name defined earlier
az group create --name $rgName

# create an Azure Container Registry using the name defined earlier
az acr create \
  --name $registryName \
  --resource-group $rgName \
  --sku Standard

# create an AKS instance using the name defined earlier
az aks create \
  --name $aksName \
  --resource-group $rgName \
  --enable-addons monitoring \
  --kubernetes-version $aksVersion \
  --generate-ssh-keys

# Create a variable to store the ID of the service principal configured for the AKS instance
clientId=$(az aks show \
  --resource-group $rgName \
  --name $aksName \
  --query "identityProfile.kubeletidentity.clientId" \
  --output tsv)

# Create a variable to store the ID of the Azure Container Registry
acrId=$(az acr show \
  --name $registryName \
  --resource-group $rgName \
  --query "id" \
  --output tsv)

# print the login server for your ACR instance
# Note the login server for your container registry. You'll need this when configuring the pipeline and environment in some upcoming steps
az acr list \
 --resource-group $rgName \
 --query "[].{loginServer: loginServer}" \
 --output table

# Example Output below:
# LoginServer
# ---------------------------------
# tailspinspacegame13956.azurecr.io

# create a role assignment to authorize the AKS cluster to connect to the Azure Container Registry
az role assignment create \
  --assignee $clientId \
  --role AcrPull \
  --scope $acrId

#