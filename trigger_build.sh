#!/usr/bin/env bash

set -e

# this script expects 3 inputs:
# 1. SDK environment variable should be set
# 2. first argument: repo_slug (repository to trigger a travis build on)
# 3. second argument: branch (branch of the above repo)

repo_slug=$1
branch="${2:-master}"

# why travis creates two builds for every commit push:
# https://stackoverflow.com/questions/34974925/travis-ci-creates-two-builds-for-each-github-commit-push
#
# one build is event type "push", the other is event type "pull request" we can only use the latter type
if [ "$TRAVIS_EVENT_TYPE" == "push" ]; then
  echo "INFO: TRAVIS_EVENT_TYPE=push so TRAVIS_PULL_REQUEST_SHA and TRAVIS_PULL_REQUEST_SLUG are empty."
  echo "INFO: without these values, this is going to be a noop (build wont be triggered)"
  exit 0
elif [ "$TRAVIS_EVENT_TYPE" == "pull_request" ]; then
  echo "INFO: TRAVIS_EVENT_TYPE=pull_request. Triggering build..."
else
  echo "ERROR: i do not understand TRAVIS_EVENT_TYPE=$TRAVIS_EVENT_TYPE"
  exit 2
fi

body=$(cat <<EOF
{
  "request": {
    "message": "Override the commit message: this is an api request",
    "branch": "${branch}",
    "config": {
      "sudo": "required",
      "language": "generic",
      "merge_mode": "deep_merge",
      "env": {
        "global": {
          "UPSTREAM_SHA": "${TRAVIS_PULL_REQUEST_SHA}",
          "UPSTREAM_REPO": "${TRAVIS_PULL_REQUEST_SLUG}",
          "RUN_ALL": false,
          "run_SDK": "${SDK}",
          "SDK_BRANCH": "${TRAVIS_PULL_REQUEST_BRANCH}"
        }
      },
      "after_success": "STATE=success ci/update_build_status.sh",
      "after_failure": "STATE=failure ci/update_build_status.sh"
    }
  }
}
EOF
)

REPO="https://api.travis-ci.com/repo/$repo_slug/requests"
echo $body
output=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Travis-API-Version: 3" \
  -H "Authorization: token $TRAVIS_COM_TOKEN" \
  -d "$body" \
  $REPO
)

if [[ "$output" == *"error"* ]]; then
  echo "ERROR: curl did not succeed: $output"
  echo "Things to check:"
  echo "is TRAVIS_COM_TOKEN defined?"
  echo "is this valid json?"
  echo "$body"
  exit 1
fi
