#!/bin/bash

flutter build web --release --base-href /portfolio_hesu/

git checkout gh-pages
git rm -r .
git add build/web -f
git commit -m "update"
git push origin gh-pages --force

git checkout main
