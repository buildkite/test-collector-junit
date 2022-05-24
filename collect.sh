#!/bin/bash

set -e

COLLECTOR_NAME="collector-junit"
COLLECTOR_VERSION="0.1"

echo -e "\033[33m     _ _   _       _ _      ____      _ _           _
    | | | | |_ __ (_| |_   / ___|___ | | | ___  ___| |_ ___  _ __
 _  | | | | | '_ \| | __| | |   / _ \| | |/ _ \/ __| __/ _ \| '__|
| |_| | |_| | | | | | |_  | |__| (_) | | |  __| (__| || (_) | |
 \___/ \___/|_| |_|_|\__|  \____\___/|_|_|\___|\___|\__\___/|_|

Buildkite Test Analytics: JUnit Collector
Version: $COLLECTOR_VERSION
\033[0m"

# Check to see if we've got jq installed already
if command -v jq >/dev/null; then
  JQ_PATH=$(which jq)

  echo "Detected jq installed in \$PATH"
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
      cat $JQ_DOWNLOAD_OUTPUT_TMP_FILE
      exit $JQ_DOWNLOAD_EXIT_STATUS
    fi

    # Ensure we can run the file
    chmod +x $JQ_PATH
  else
    echo "Skipping jq download as it already exists at \"$JQ_PATH\""
  fi
fi

# Based on the rules defined here:
# https://github.com/buildkite/rspec-buildkite-analytics/blob/main/lib/buildkite/collector/ci.rb

if [[ -n $BUILDKITE_BUILD_ID ]]; then
  echo "Deteted Buildkite CI environment"

  COLLECTOR_CI="buildkite"
  COLLECTOR_KEY=$BUILDKITE_BUILD_ID
  COLLECTOR_NUMBER=$BUILDKITE_BUILD_NUMBER
  COLLECTOR_JOB_ID=$BUILDKITE_JOB_ID
  COLLECTOR_BRANCH=$BUILDKITE_BRANCH
  COLLECTOR_COMMIT_SHA=$BUILDKITE_COMMIT
  COLLECTOR_MESSAGE=$BUILDKITE_MESSAGE
  COLLECTOR_URL=$BUILDKITE_BUILD_URL
elif [[ -n $GITHUB_RUN_NUMBER ]]; then
  echo "Deteted GitHub Actions CI environment"

  COLLECTOR_CI="github_actions"
  COLLECTOR_KEY="$GITHUB_ACTION-$GITHUB_RUN_NUMBER-$GITHUB_RUN_ATTEMPT"
  COLLECTOR_NUMBER=$GITHUB_RUN_NUMBER
  COLLECTOR_BRANCH=$GITHUB_REF
  COLLECTOR_COMMIT_SHA=$GITHUB_SHA
  COLLECTOR_URL="https://github.com/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID"
elif [[ -n $CIRCLE_BUILD_NUM ]]; then
  echo "Deteted CircleCI environment"

  COLLECTOR_CI="circleci"
  COLLECTOR_KEY="$CIRCLE_WORKFLOW_ID-$CIRCLE_BUILD_NUM"
  COLLECTOR_NUMBER=$CIRCLE_BUILD_NUM
  COLLECTOR_BRANCH=$CIRCLE_BRANCH
  COLLECTOR_COMMIT_SHA=$CIRCLE_SHA1
  COLLECTOR_URL=$CIRCLE_BUILD_URL
elif [[ -n $CI ]]; then
  echo "Deteted generic CI environment"

  COLLECTOR_CI="generic"
  COLLECTOR_KEY="$$"
else
  echo "No CI environment detected"

  COLLECTOR_KEY="$$"
fi

JUNIT_DATA_PATH="/tmp/bk-collector-junit-data-$$.xml"
cat ${1--} > $JUNIT_DATA_PATH

JSON_PATH="/tmp/bk-collector-junit-upload-data-$$.json"

$JQ_PATH --null-input \
  --arg ci "$COLLECTOR_CI" \
  --arg key "$COLLECTOR_KEY" \
  --arg number "$COLLECTOR_NUMBER" \
  --arg job_id "$COLLECTOR_JOB_ID" \
  --arg branch "$COLLECTOR_BRANCH" \
  --arg commit_sha "$COLLECTOR_COMMIT_SHA" \
  --arg message "$COLLECTOR_MESSAGE" \
  --arg url "$COLLECTOR_URL" \
  --arg debug "$BUILDKITE_ANALYTICS_DEBUG_ENABLED" \
  --arg collector_name "$COLLECTOR_NAME" \
  --arg collector_version "$COLLECTOR_VERSION" \
  --rawfile data "$JUNIT_DATA_PATH" \
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
        "url": $url,
        "debug": $debug,
        "collector": $collector_name,
        "version": $collector_version
      },
      "data": $data
    }
  ' > $JSON_PATH

TEST_ANALYTICS_HTTP_URL="https://analytics-api.buildkite.com/v1/uploads"
TEST_ANALYTICS_HTTP_AUTH='Authorization: Token token="'$TEST_ANALYTICS_TOKEN'";'

UPLOAD_RESPONSE="/tmp/bk-collector-junit-upload-response-$$.txt"
UPLOAD_COMMAND_OUTPUT_TMP_FILE="/tmp/bk-collector-junit-upload-cmd-output-$$.txt"

echo ""
echo "Uploading results to Buildkite Test Analytics. One moment please..."
echo ""

if command -v curl >/dev/null; then
  curl --output "$UPLOAD_RESPONSE" \
    --request POST \
    --url "$TEST_ANALYTICS_HTTP_URL" \
    --header "$TEST_ANALYTICS_HTTP_AUTH" \
    --header 'Content-Type: application/json' \
    --data "@$JSON_PATH"
  UPLOAD_EXIT_STATUS=$?
else
  echo "wget support hasn't been added for uploads yet"
  exit 1
fi

echo ""
cat "$UPLOAD_RESPONSE"
echo ""

if [[ $UPLOAD_EXIT_STATUS -ne 0 ]]; then
  echo "❌ Something went wrong..."
else
  echo "✅ Uploaded!"
fi
