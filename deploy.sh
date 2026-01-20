#!/bin/bash

flutter build web --release --base-href /portfolio_hesu/

git checkout gh-pages
git rm -r .
cp -r build/web/* .
git commit -m "update"
git push origin gh-pages --force

git checkout main
