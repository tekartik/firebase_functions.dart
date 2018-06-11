#!/usr/bin/env bash

set -xe

pushd firebase_functions_node
pub get
popd

pushd firebase_functions_io
pub get
popd

pub run grinder:grinder test