#!/bin/bash

# Override basic drone tags.

# Drone 5+ docker plugin will read PLUGIN_TAGS from a .env file
# Tags:
#   Feature branch: $VERSION-$COMMIT_DATE.$BRANCH.$SHA and "latest"
#   production: $VERSION and "latest"
#
# Use --include-feature-tag to add a feature branch tag on a production branch commit

function join_by { local IFS="$1"; shift; echo "$*"; }

if [ "$1" == --include-feature-tag ]; then
  INCLUDE_FEATURE_TAG="true"
fi

if [ -f "./Dockerfile" ]; then
  # from APPLICATION_VERSION in Docker file
  VERSION=$(grep 'ENV APPLICATION_VERSION' Dockerfile | awk '{print $3}')
  echo "Found version in Dockerfile file"
elif [ -f "./build/Dockerfile" ]; then
  # from APPLICATION_VERSION in Docker file
  VERSION=$(grep 'ENV APPLICATION_VERSION' ./build/Dockerfile | awk '{print $3}')
  echo "Found version in Dockerfile file"
else
  echo "ERROR: Can't figure out version"
  exit 1
fi

# Use drone or rancher-pipeline branch var
if [ "${DRONE_COMMIT_BRANCH}" ]; then
  COMMIT_BRANCH=$DRONE_COMMIT_BRANCH
fi

if [ "${CICD_GIT_BRANCH}" ]; then
  COMMIT_BRANCH=$CICD_GIT_BRANCH
fi

if [ -z "${COMMIT_BRANCH}" ]; then
  COMMIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
fi

# date is unix time stamp for commit
COMMIT_DATE=$(git --no-pager log -1 --format='%ct')
COMMIT_SHA=$(git --no-pager log -1 --format='%h')

echo "VERSION: ${VERSION}"
echo "COMMIT_DATE: ${COMMIT_DATE}"
echo "COMMIT_BRANCH: ${COMMIT_BRANCH}"
echo "COMMIT_SHA: ${COMMIT_SHA}"

if [ "${COMMIT_BRANCH}" != "production" ]; then
  INCLUDE_FEATURE_TAG="true"
fi

TAGS=()
if [ "${COMMIT_BRANCH}" == "production" ]; then
  echo "Writing production style tags"
  TAGS+=("${VERSION}")
  TAGS+=("latest")
fi

if [ "${INCLUDE_FEATURE_TAG}" == "true" ]; then
  echo "Writing feature style tag"
  NEW_BRANCH_NAME=$(echo ${COMMIT_BRANCH} | tr / .)
  TAGS+=("${VERSION}-${COMMIT_DATE}.${NEW_BRANCH_NAME}.${COMMIT_SHA}")
  TAGS+=("latest")
fi

echo "Writing tags to .tags file:"
echo "$(join_by , ${TAGS[*]})"
echo "$(join_by , ${TAGS[*]})" >> .tags
