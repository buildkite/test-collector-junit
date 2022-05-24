#!/bin/bash

set -e

function echo-debug {
  if [[ "$BUILDKITE_ANALYTICS_DEBUG_ENABLED" == "true" ]]; then
    echo $1
  fi
}

function echo-error {
  echo $1
}

# Check to see if we've got jq installed already
if command -v jq >/dev/null; then
  JQ_PATH=$(which jq)

  echo-debug "using system jq"
else
  # Figure out where we're going to put the binary after we download it
  JQ_FOLDER="$HOME/.bk-collector-junit"
  JQ_PATH="$JQ_FOLDER/jq"

  # Have we already download jq? If we have, we can skip this whole bit.
  if [[ ! -f "$JQ_PATH" ]]; then
    # Figure out which binary to download
    SYSTEM=$(uname -s | awk '{print tolower($0)}')
    if [[ ($SYSTEM == *"mac os x"*) || ($SYSTEM == *darwin*) ]]; then
      JQ_PLATFORM="osx-amd64"
    else
      MACHINE=$(uname -m | awk '{print tolower($0)}')
      if [[ ($MACHINE == *"64"*) ]]; then
        JQ_PLATFORM="linux64"
      else
        JQ_PLATFORM="linux32"
      fi
    fi

    JQ_BINARY_DOWNLOAD_URL="https://github.com/stedolan/jq/releases/download/jq-1.6/jq-$JQ_PLATFORM"
    JQ_DOWNLOAD_OUTPUT_TMP_FILE="/tmp/bk-collector-junit-jq-download-$$.txt"
    JQ_DOWNLOAD_EXIT_STATUS

    # Make sure the folder actually exists
    mkdir -p "$JQ_FOLDER"

    # Download jq
    if command -v wget >/dev/null; then
      wget "$JQ_BINARY_DOWNLOAD_URL" -O "$JQ_PATH" 2> $JQ_DOWNLOAD_OUTPUT_TMP_FILE || JQ_DOWNLOAD_EXIT_STATUS=$?
    else
      curl -L -o "$JQ_PATH" "$JQ_BINARY_DOWNLOAD_URL" 2> $JQ_DOWNLOAD_OUTPUT_TMP_FILE || JQ_DOWNLOAD_EXIT_STATUS=$?
    fi

    if [[ $JQ_DOWNLOAD_EXIT_STATUS -ne 0 ]]; then
      echo "Failed to download file: $JQ_BINARY_DOWNLOAD_URL"
      cat $BUILDKITE_DOWNLOAD_TMP_FILE
      exit $BUILDKITE_DOWNLOAD_EXIT_STATUS
    fi

    # Ensure we can run the file
    chmod +x $JQ_PATH
  else
    echo-debug "Skipping jq download as it already exists at \"$JQ_PATH\""
  fi
fi

COLLECTOR_CI="buildkite"
COLLECTOR_KEY="$$"
COLLECTOR_NUMBER=""
COLLECTOR_JOB_ID=""
COLLECTOR_BRANCH=""
COLLECTOR_COMMIT_SHA=""
COLLECTOR_MESSAGE=""
COLLECTOR_URL=""

# todo: detect and set the below
# COLLECTOR_CI="buildkite"
# COLLECTOR_KEY=$BUILDKITE_BUILD_ID
# COLLECTOR_NUMBER=$BUILDKITE_BUILD_NUMBER
# COLLECTOR_JOB_ID=$BUILDKITE_JOB_ID
# COLLECTOR_BRANCH=$BUILDKITE_BRANCH
# COLLECTOR_COMMIT_SHA=$BUILDKITE_COMMIT
# COLLECTOR_MESSAGE=$BUILDKITE_MESSAGE
# COLLECTOR_URL=$BUILDKITE_BUILD_URL

COLLECTOR_JUNIT_DATA=$(cat ${1--})

JSON_BODY=$($JQ_PATH --null-input \
  --arg ci "$COLLECTOR_CI" \
  --arg key "$COLLECTOR_KEY" \
  --arg number "$COLLECTOR_NUMBER" \
  --arg job_id "$COLLECTOR_JOB_ID" \
  --arg branch "$COLLECTOR_BRANCH" \
  --arg commit_sha "$COLLECTOR_COMMIT_SHA" \
  --arg message "$COLLECTOR_MESSAGE" \
  --arg url "$COLLECTOR_URL" \
  --arg data "$COLLECTOR_JUNIT_DATA" \
  '
    {
      "format": "junit",
      "run_env": {
        "CI": $ci,
        "key": $key,
        "number": $number,
        "job_id": $job_id,
        "branch": $branch,
        "commit_sha": $commit_sha,
        "message": $message,
        "url": $url
      },
      "data": $data
    }
  ')

echo-debug "$JSON_BODY"

TEST_ANALYTICS_HTTP_URL="https://analytics-api.buildkite.com/v1/uploads"
TEST_ANALYTICS_HTTP_AUTH='Authorization: Token token="'$TEST_ANALYTICS_TOKEN'";'

UPLOAD_RESPONSE="/tmp/bk-collector-junit-upload-response-$$.txt"
UPLOAD_COMMAND_OUTPUT_TMP_FILE="/tmp/bk-collector-junit-upload-cmd-output-$$.txt"

if command -v curl >/dev/null; then
  curl --output "$UPLOAD_RESPONSE" \
    --request POST \
    --url "$TEST_ANALYTICS_HTTP_URL" \
    --header "$TEST_ANALYTICS_HTTP_AUTH" \
    --header 'Content-Type: application/json' \
    --data "$JSON_BODY" 2> "$UPLOAD_COMMAND_OUTPUT_TMP_FILE"
  UPLOAD_EXIT_STATUS=$?
else
  echo 'todo'
fi

echo "$UPLOAD_EXIT_STATUS"

cat $UPLOAD_RESPONSE

if [[ $UPLOAD_EXIT_STATUS -ne 0 ]]; then
  echo "blah"
  cat "$UPLOAD_COMMAND_OUTPUT_TMP_FILE"
  echo "output"
  cat "$UPLOAD_RESPONSE"
  # echo-error "blah"
fi
