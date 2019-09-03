#!/usr/bin/env bash

echo "Update NVTs"
greenbone-nvt-sync
greenbone-certdata-sync
greenbone-scapdata-sync

echo "Your OpenVAS Nvts Have Update At the latest!"