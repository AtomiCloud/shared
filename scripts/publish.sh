#!/usr/bin/env bash

# check for necessary env vars
[ "${DOMAIN}" = '' ] && echo "❌ 'DOMAIN' env var not set" && exit 1
[ "${GITHUB_REPO_REF}" = '' ] && echo "❌ 'GITHUB_REPO_REF' env var not set" && exit 1

[ "${CYAN_TOKEN}" = '' ] && echo "❌ 'CYAN_TOKEN' env var not set" && exit 1

image_version="$1"
[ "${image_version}" = '' ] && echo "❌ 'image_version' not set" && exit 1

set -eou pipefail

echo "🏷️ Generating Image IDs..."
TEMPLATE_IMAGE_ID="${DOMAIN}/${GITHUB_REPO_REF}/template"
TEMPLATE_IMAGE_ID=$(echo "${TEMPLATE_IMAGE_ID}" | tr '[:upper:]' '[:lower:]')

BLOB_IMAGE_ID="${DOMAIN}/${GITHUB_REPO_REF}/blob"
BLOB_IMAGE_ID=$(echo "${BLOB_IMAGE_ID}" | tr '[:upper:]' '[:lower:]')
echo "✅ Generated Image IDs!"

echo "🔨 Pushing to Cyanprint..."
cyanprint push template "${BLOB_IMAGE_ID}" "${image_version}" "${TEMPLATE_IMAGE_ID}" "${image_version}"
echo "✅ Pushed to Cyanprint!"
