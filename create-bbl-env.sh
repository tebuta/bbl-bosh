GCP_PROJECT=$(gcloud config get-value project 2>/dev/null)
BBL_ENVIRONMENT=bbl-${GCP_PROJECT}
BASE_PATH=$(pwd)
BBL_STATE_PATH=${BASE_PATH}/${BBL_ENVIRONMENT}
SERVICE_ACCOUNT="bbl-service-account-user"
SERVICE_ACCOUNT_KEY_FILE="${BBL_STATE_PATH}/${SERVICE_ACCOUNT}.key.json"

export BBL_IAAS=gcp
export BBL_ENV_NAME=${BBL_ENVIRONMENT}
export BBL_GCP_REGION=$(gcloud config get-value compute/region 2>/dev/null)

if [ ! -d ${BBL_STATE_PATH} ]
then
    mkdir -p ${BBL_STATE_PATH}
fi

if [[ $(gcloud iam --project ${GCP_PROJECT} service-accounts list | grep -c "${SERVICE_ACCOUNT}") -eq 0 ]]
then
    gcloud iam --project ${GCP_PROJECT} service-accounts create ${SERVICE_ACCOUNT} \
               --display-name=${SERVICE_ACCOUNT}
fi

if [ ! -f ${SERVICE_ACCOUNT_KEY_FILE} ]
then
    gcloud iam --project ${GCP_PROJECT} service-accounts keys create --iam-account="${SERVICE_ACCOUNT}@${GCP_PROJECT}.iam.gserviceaccount.com" ${SERVICE_ACCOUNT_KEY_FILE}
fi

gcloud projects add-iam-policy-binding ${GCP_PROJECT} \
    --member=serviceAccount:${SERVICE_ACCOUNT}@${GCP_PROJECT}.iam.gserviceaccount.com \
    --role=roles/owner

export BBL_GCP_SERVICE_ACCOUNT_KEY=$(cat ${SERVICE_ACCOUNT_KEY_FILE})

bbl plan -s ${BBL_STATE_PATH} $*

# Add nat instance tf file into bbl template
cp overrides/nat-override.tf ${BBL_STATE_PATH}/terraform/

# Remove director external IP and set director tags
ENV_ID=$(grep env_id "${BBL_STATE_PATH}/vars/terraform.tfvars" | sed 's/^env_id="\(.*\)"$/\1/g')
sed -i "s/^.*bosh-director-ephemeral-ip-ops.*$/  -v  tags=[${ENV_ID}-bosh-director,no-ip]/g" "${BBL_STATE_PATH}/create-director.sh"
sed -i "s/^.*bosh-director-ephemeral-ip-ops.*$/  -v  tags=[${ENV_ID}-bosh-director,no-ip]/g" "${BBL_STATE_PATH}/delete-director.sh"

bbl up -s ${BBL_STATE_PATH} $*
