#!/bin/bash
set -e

latest_tag=$1
release_type=$2

# Remove 'v' prefix if exists
version=${latest_tag#v}

# Split version into parts
IFS='.' read -r major minor patch <<< "$version"

# Bump version based on type
case "$release_type" in
  major)
    major=$((major+1)); minor=0; patch=0;;
  minor)
    minor=$((minor+1)); patch=0;;
  patch)
    patch=$((patch+1));;
esac

# Output new version
echo "v$major.$minor.$patch"