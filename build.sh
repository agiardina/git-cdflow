#!/bin/bash

rm -fr build
rm -fr dist
mkdir build
mkdir dist

raco demod -o build/git-cdflow_rkt_merged.zo src/git-cdflow.rkt
raco demod -o build/git-cdflow-parent_rkt_merged.zo src/git-cdflow-parent.rkt 
raco demod -o build/git-cdflow-release_rkt_merged.zo src/git-cdflow-release.rkt 
raco demod -o build/git-cdflow-feature_rkt_merged.zo src/git-cdflow-feature.rkt
raco demod -o build/git-cdflow-issue_rkt_merged.zo src/git-cdflow-issue.rkt
raco demod -o build/git-cdflow-tree_rkt_merged.zo src/git-cdflow-tree.rkt

raco exe -o build/git-cdflow build/git-cdflow_rkt_merged.zo
raco exe -o build/git-cdflow-parent build/git-cdflow-parent_rkt_merged.zo
raco exe -o build/git-cdflow-release build/git-cdflow-release_rkt_merged.zo
raco exe -o build/git-cdflow-feature build/git-cdflow-feature_rkt_merged.zo
raco exe -o build/git-cdflow-issue build/git-cdflow-issue_rkt_merged.zo
raco exe -o build/git-cdflow-tree build/git-cdflow-tree_rkt_merged.zo

raco distribute dist/git-cdflow build/git-cdflow build/git-cdflow-parent build/git-cdflow-release build/git-cdflow-feature build/git-cdflow-issue build/git-cdflow-tree

echo "Build done. Enjoy!"
