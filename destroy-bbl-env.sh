GCP_PROJECT=$(gcloud config get-value project 2>/dev/null)
BBL_ENVIRONMENT=bbl-${GCP_PROJECT}
BASE_PATH=$(pwd)
BBL_STATE_PATH=${BASE_PATH}/${BBL_ENVIRONMENT}
SERVICE_ACCOUNT="bbl-service-account-user"
SERVICE_ACCOUNT_KEY_FILE="${BBL_STATE_PATH}/${SERVICE_ACCOUNT}.key.json"

export BBL_IAAS=gcp
export BBL_ENV_NAME=${BBL_ENVIRONMENT}
export BBL_GCP_REGION=$(gcloud config get-value compute/region 2>/dev/null)
export BBL_GCP_SERVICE_ACCOUNT_KEY=$(cat ${SERVICE_ACCOUNT_KEY_FILE})

if [ ! -d ${BBL_STATE_PATH} ]
then
   exit 1
else
    bbl destroy -s ${BBL_STATE_PATH} $*
fi
