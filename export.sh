#!/bin/bash -e
set -o pipefail

pushd "$(dirname $0)" > /dev/null


GIT_REF=$(git rev-parse HEAD)
GITHUB_PAGES_BRANCH="gh-pages"

echo "type 'export index.html' in pico-8"
read -s -p  "press enter afterwards"

git checkout "$GITHUB_PAGES_BRANCH"

mv src/index.html src/index.js .

git add src/index.html src/index.js
git commit -m "Export $GIT_REF"


popd > /dev/null
