#!/bin/bash
rm -fr build
rm -fr dist
mkdir build
mkdir dist
raco exe -o build/git-cdflow src/git-cdflow.rkt
raco exe -o build/git-cdflow-parent src/git-cdflow-parent.rkt
raco exe -o build/git-cdflow-release src/git-cdflow-release.rkt
raco exe -o build/git-cdflow-feature src/git-cdflow-feature.rkt
raco distribute dist/git-cdflow build/git-cdflow build/git-cdflow-parent build/git-cdflow-release build/git-cdflow-feature 

