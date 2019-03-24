#!/usr/bin/env bash

set -xe

pushd firebase_functions
dartanalyzer --fatal-warnings lib test
pub get
pub run test
popd

pushd firebase_functions_node
pub get
pub run test
popd

pushd firebase_functions_io
pub get
dartanalyzer --fatal-warnings lib test
pub run test
popd

pub run grinder:grinder test