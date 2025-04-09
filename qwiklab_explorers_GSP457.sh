# Welcome message

echo "INITIATING EXECUTION..."

read -p "Enter the location:"

export LOCATION=$LOCATION
export PROJECT_ID=$(gcloud config list --format 'value(core.project)')
export PROJECT_NUMBER=$(gcloud projects list --filter=projectId:$PROJECT_ID \
  --format="value(projectNumber)")
export DATASET_ID=dataset1
export FHIR_STORE_ID=fhirstore1
export TOPIC=fhir-topic
export HL7_STORE_ID=hl7v2store1 # Note: This variable isn't used later, maybe remove if not needed?

gcloud services enable healthcare.googleapis.com --project=$PROJECT_ID
# Adding a small sleep just in case enablement needs a moment, though often not strictly required
sleep 10

gcloud pubsub topics create $TOPIC --project=$PROJECT_ID

bq --location=$LOCATION mk --dataset --description "HCAPI dataset" $PROJECT_ID:$DATASET_ID

bq --location=$LOCATION mk --dataset --description "HCAPI dataset de-id" $PROJECT_ID:de_id

gcloud healthcare datasets create $DATASET_ID \
  --location=$LOCATION \
  --project=$PROJECT_ID

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:service-$PROJECT_NUMBER@gcp-sa-healthcare.iam.gserviceaccount.com" \
  --role="roles/bigquery.dataEditor"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:service-$PROJECT_NUMBER@gcp-sa-healthcare.iam.gserviceaccount.com" \
  --role="roles/bigquery.jobUser"
# --- END OF MOVED SECTION ---

gcloud healthcare fhir-stores create $FHIR_STORE_ID \
  --dataset=$DATASET_ID \
  --location=$LOCATION \
  --version=R4 \
  --project=$PROJECT_ID

gcloud healthcare fhir-stores update $FHIR_STORE_ID \
  --dataset=$DATASET_ID \
  --location=$LOCATION \
  --pubsub-topic=projects/$PROJECT_ID/topics/$TOPIC \
  --project=$PROJECT_ID

gcloud healthcare fhir-stores create de_id \
  --dataset=$DATASET_ID \
  --location=$LOCATION \
  --version=R4 \
  --project=$PROJECT_ID
  
gcloud healthcare fhir-stores import gcs $FHIR_STORE_ID \
  --dataset=$DATASET_ID \
  --location=$LOCATION \
  --gcs-uri=gs://spls/gsp457/fhir_devdays_gcp/fhir1/* \
  --content-structure=BUNDLE_PRETTY \
  --project=$PROJECT_ID

gcloud healthcare fhir-stores export bq $FHIR_STORE_ID \
  --dataset=$DATASET_ID \
  --location=$LOCATION \
  --bq-dataset=bq://$PROJECT_ID.$DATASET_ID \
  --schema-type=analytics \
  --project=$PROJECT_ID

echo "NOW FOLLOW NEXT STEPS CAREFULLY FROM THE VIDEO..."

echo "OPEN THIS LINK: https://console.cloud.google.com/healthcare/browser?project="

echo "Have you completed the video steps? (Y/N):"
read -r answer
if [[ $answer == "y" || $answer == "Y" ]]; then
    echo "Great! Proceeding with the next steps..."
else
    echo "Please complete the task from the video before proceeding..."

fi
echo

echo "Exporting data from FHIR store de_id to BigQuery dataset de_id..."
gcloud healthcare fhir-stores export bq de_id \
  --dataset=$DATASET_ID \
  --location=$LOCATION \
  --bq-dataset=bq://$PROJECT_ID.de_id \
  --schema-type=analytics \
  --project=$PROJECT_ID

echo "OPEN THIS LINK: https://console.cloud.google.com/bigquery?project="

# Completion Message
# echo
# echo "LAB COMPLETED SUCCESSFULLY!"

echo 
echo -e "Subscribe my Channel (QwikLab Explorers):  https://www.youtube.com/@qwiklabexplorers"

