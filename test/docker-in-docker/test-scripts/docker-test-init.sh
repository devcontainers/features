#!/bin/sh
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------

retry_count=0
docker_ok="false"

until [ "${docker_ok}" = "true"  ] || [ "${retry_count}" -eq "5" ];
do
    if [ "${retry_count}" -eq "3" ]; then
        echo "Starting docker after 3 retries..."
        /usr/local/share/docker-init.sh
    fi

    sleep 5s

    set +e
        docker info > /dev/null 2>&1 && docker_ok="true"

        if [ "${docker_ok}" != "true" ]; then
            echo "(*) Failed to start docker, retrying... Retry count: ${retry_count}"
            retry_count=`expr $retry_count + 1`
        fi
    set -e
done