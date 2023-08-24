#!/bin/bash

user=tech_lead_test
pass=${PASSWORD:-use_environment_variable_to_pass_password}

last_timestamp="$(cat ./tmp/last_timestamp)"
if [ -z "$last_timestamp" ]; then
  last_timestamp="2023-08-01T00:00:00.000Z"
fi
last_timestamp=$(TZ=GMT date -j -f "%Y-%m-%dT%H:%M:%S%z" "${last_timestamp%.*}+0000" +%Y-%m-%dT%T%z    )
echo ":TIME: $last_timestamp"

# Step 1: Start a scroll search to retrieve the first batch of results
response=$(curl -u $user:$pass -X GET "https://botson-reporting-v2.es.us-central1.gcp.cloud.es.io/events-testing-botson-reporting/_search?scroll=60m" -H "Content-Type: application/json" -d '{
  "size": 1000,   // Adjust batch size as needed
  "query": {
    "range": {
      "TIMESTAMP": {
        "gte": "'$last_timestamp'",
        "lte": "now"
      }
    }
  },
  "sort": [{
    "TIMESTAMP": {
      "order": "asc"
    }
  }]
}')


echo $response > ./tmp/fetch_generic.json

# Get the initial scroll ID and total number of hits
scrollId=$(echo $response | jq -r ._scroll_id)
total_hits=$(echo $response | jq -r .hits.total.value)

echo "SCROLL: $scrollId\n"

if [ ! -f "./tmp/fetch_generic.json" ]; then
  touch ./tmp/fetch_generic.json
fi

# Step 2: Loop through the scroll search results to retrieve all documents
while [ $(echo $response | jq -r '.hits.hits | length') -gt 0 ]; do
  # Process current batch of hits

  echo $response > ./tmp/fetch_generic.json

  for row in $(echo "${response}" | jq -r '.hits.hits[] | @base64'); do
    _jq() {
      echo "${row}" | base64 --decode | jq -r "${1}"
    }
      id=$(_jq '._id')
      timestamp=$(_jq '._source.TIMESTAMP')
      timestamp_seconds=$(TZ=GMT date -j -f "%Y-%m-%dT%H:%M:%S%z" "${timestamp%.*}+0000" +%Y-%m-%dT%H:%M:%S    )
      echo $timestamp > "./tmp/last_timestamp"
      DIR="./tmp/hits/${timestamp_seconds}"
      FILE="${DIR}/${id}.json";
      if [ -f "$FILE" ]; then
        echo "Skipping $id"
        continue;
      fi
      data=$(_jq '._source')
      echo "ID: $id"

      # Save data to corresponding file
      if [ ! -d "$DIR" ]; then
        mkdir -p $DIR
      fi
      echo $data > $FILE
  done

  # Get the next batch of results using the scroll ID
  response=$(curl -u $user:$pass -X GET "https://botson-reporting-v2.es.us-central1.gcp.cloud.es.io/_search/scroll" -H "Content-Type: application/json" -d '{
    "scroll_id": "'$scrollId'"
  }')
done


# Clear the scroll context
curl -u $user:$pass -X DELETE "https://botson-reporting-v2.es.us-central1.gcp.cloud.es.io/_search/scroll" -H "Content-Type: application/json" -d '{
"scroll_id": ["'$scrollId'"]
}'
