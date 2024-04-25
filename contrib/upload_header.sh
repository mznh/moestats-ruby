#!/bin/bash
cd $(dirname $0)
set -x

source <(../contrib/set_env.sh )

gsutil cp ../resource/header.csv gs://${BUCKET_NAME}/${GCS_HEADER_PATH}
