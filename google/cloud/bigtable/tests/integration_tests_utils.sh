#!/usr/bin/env bash
# Copyright 2018 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This file defines common routines and variables to run the integration tests.

readonly CBT_CMD="${CBT:-${GOPATH}/bin/cbt}"
readonly CBT_EMULATOR_CMD="${CBT_EMULATOR:-${GOPATH}/bin/emulator}"
readonly CBT_INSTANCE_ADMIN_EMULATOR_CMD="./instance_admin_emulator"

# Run all the integration tests against the emulator or production.
#
# This function allows us to keep a single place where all the integration tests
# are listed. Unfortunately there are some significant differences on how we
# run the integration tests against production vs. how we run them against the
# Cloud Bigtable Emulator.  This function hides those details.
function run_all_integration_tests() {
  local project_id=$1
  shift

  # Declare the variable, but do not set it at first. For production the
  # variable is set and we need to delete all the tables before each test, with
  # the emulator we use a different instance on each test.
  local instance_id=
  if [ "$#" -gt 0 ]; then
    instance_id=$1
  fi

  echo
  echo "Running bigtable::InstanceAdmin integration test."
  if [ -z "${BIGTABLE_INSTANCE_ADMIN_EMULATOR_HOST:-}" ]; then
    ./instance_admin_integration_test "${project_id}";
  else
    env "BIGTABLE_EMULATOR_HOST=${BIGTABLE_INSTANCE_ADMIN_EMULATOR_HOST:-}" \
       ./instance_admin_integration_test "${project_id}";
  fi

  echo
  echo "Running bigtable::TableAdmin integration test."
  ./admin_integration_test "${project_id}" "${instance_id:-admin-test}"

  echo
  echo "Running bigtable::Table integration test."
  ./data_integration_test "${project_id}" "${instance_id:-data-test}"

  echo
  echo "Running bigtable::Filters integration tests."
  ./filters_integration_test "${project_id}" "${instance_id:-filters-test}"

  echo
  echo "Running Mutation (e.g. DeleteFromColumn, SetCell) integration tests."
  ./mutations_integration_test "${project_id}" "${instance_id:-mutations-test}"
}
