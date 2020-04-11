#!/usr/bin/env bash
docker build -f Dockerfile-build-ovn -t image-ovn .
docker create --name container-ovn image-ovn
docker cp container-ovn:/root/ovn/rpm/rpmbuild/RPMS/x86_64 rpms/
docker rm container-ovn

