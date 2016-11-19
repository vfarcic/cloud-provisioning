# Binary

```bash
~ $ curl -sSL https://dl.bintray.com/emccode/rexray/install | sh -s stable
sudo: unable to execute /usr/bin/rexray: No such file or directory

rexray has been installed to /usr/bin/rexray

sh: /usr/bin/rexray: not found
```

# Container

```bash
~ $ sudo docker run \
>   -d --name rexray \
>   -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY \
>   -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_KEY \
>   -v /run/docker/plugins:/run/docker/plugins \
>   -v /var/lib/rexray:/var/lib/rexray:shared \
>   -v /var/run/rexray:/var/run/rexray \
>   -v /var/log/rexray:/var/log/rexray \
>   -v /dev:/dev \
>   basi/rexray
Unable to find image 'basi/rexray:latest' locally
latest: Pulling from basi/rexray
8ad8b3f87b37: Pull complete
d66207d05cbb: Pull complete
fc1f8906394f: Pull complete
Digest: sha256:d5961337a42c3d26181142dbdf8b02423c81d1b64602f35e76fcfd0a240a30da
Status: Downloaded newer image for basi/rexray:latest
5640ec82025dd1785d6202f9e4724c60c5bad30edf419f4b1f58c50196746b56
docker: Error response from daemon: linux mounts: Path /var/lib/rexray is mounted on /var but it is not a shared mount..
```

# Container without shared

```bash
~ $ sudo docker run \
>   -d --name rexray \
>   -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY \
>   -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_KEY \
>   -v /run/docker/plugins:/run/docker/plugins \
>   -v /var/lib/rexray:/var/lib/rexray \
>   -v /var/run/rexray:/var/run/rexray \
>   -v /var/log/rexray:/var/log/rexray \
>   -v /dev:/dev \
>   basi/rexray
cd7299ea508df020bf415d5953046317e12ff997bd6a9e33ef5bb95bc79bff43
~ $ docker ps -a
CONTAINER ID        IMAGE                                              COMMAND                  CREATED             STATUS                      PORTS                         NAMES
cd7299ea508d        basi/rexray                                        "/bin/sh -c /entry..."   3 seconds ago       Up 3 seconds                                              rexray
b9e26dc77e80        docker4x/l4controller-aws:aws-v1.13.0-rc1-beta11   "loadbalancer run ..."   13 minutes ago      Up 13 minutes                                             editions_controller
502e3e0704e9        docker4x/shell-aws:aws-v1.13.0-rc1-beta11          "/entry.sh /usr/sb..."   13 minutes ago      Up 13 minutes               0.0.0.0:22->22/tcp            shell-aws
a876af096363        docker4x/guide-aws:aws-v1.13.0-rc1-beta11          "/entry.sh"              13 minutes ago      Up 13 minutes                                             guide-aws
e2a74b1daaa0        docker4x/init-aws:aws-v1.13.0-rc1-beta11           "/entry.sh"              13 minutes ago      Exited (0) 13 minutes ago                                 fervent_mccarthy
8a30db519d3d        docker4x/meta-aws:aws-v1.13.0-rc1-beta11           "metaserver -flavo..."   14 minutes ago      Up 14 minutes               172.31.5.147:9024->8080/tcp   meta-aws
~ $ sudo docker exec -it rexray rexray volume get
- name: ""
  volumeid: vol-63fe28f2
  availabilityzone: us-east-1d
  status: in-use
  volumetype: standard
  iops: 0
  size: "20"
  networkname: ""
  attachments:
  - volumeid: vol-63fe28f2
    instanceid: i-b0725f23
    devicename: /dev/xvdb
    status: attached
- name: ""
  volumeid: vol-80fd2b11
  availabilityzone: us-east-1d
  status: in-use
  volumetype: standard
  iops: 0
  size: "20"
  networkname: ""
  attachments:
  - volumeid: vol-80fd2b11
    instanceid: i-0d4c619e
    devicename: /dev/xvdb
    status: attached
- name: ""
  volumeid: vol-b2c62321
  availabilityzone: us-east-1b
  status: in-use
  volumetype: standard
  iops: 0
  size: "20"
  networkname: ""
  attachments:
  - volumeid: vol-b2c62321
    instanceid: i-d5a6eadb
    devicename: /dev/xvdb
    status: attached
- name: ""
  volumeid: vol-ecc6237f
  availabilityzone: us-east-1b
  status: in-use
  volumetype: standard
  iops: 0
  size: "20"
  networkname: ""
  attachments:
  - volumeid: vol-ecc6237f
    instanceid: i-d6a6ead8
    devicename: /dev/xvdb
    status: attached
~ $ sudo docker run -ti --rm -v test1:/test busybox touch /test/viktor1
Unable to find image 'busybox:latest' locally
latest: Pulling from library/busybox
56bec22e3559: Pull complete
Digest: sha256:29f5d56d12684887bdfa50dcd29fc31eea4aaf4ad3bec43daf19026a7ce69912
Status: Downloaded newer image for busybox:latest
```
