#!/usr/bin/env bash
LOADBALANCER_IP=changeit
MANAGER_INTERNAL_IP=
TOKEN=
WORKERS=(worker1 worker2)
KEY=/home/user/.ssh/id_rsa_azure
REMOTE_USER=swarmadmin

echo "########################################"
echo "########################################"
echo "## SETUP DOCKER SWARM MODE #############"
echo "########################################"

echo "########################################"
echo "## PARAMETERS ##########################"
echo "# LOADBALANCER_IP=$LOADBALANCER_IP"
echo "# WORKERS=$WORKERS"
echo "# KEY=$KEY"
echo "# REMOTE_USER=$REMOTE_USER"
echo "########################################"

echo "########################################"
echo "## COPY FILES & SCRIPTS ################"
echo "########################################"
echo "## @Manager"
scp -P 2200 -o StrictHostKeyChecking=no $KEY $REMOTE_USER@$LOADBALANCER_IP:/home/$REMOTE_USER/.ssh/id_rsa
scp -P 2200 -o StrictHostKeyChecking=no get-internal-ip.sh $REMOTE_USER@$LOADBALANCER_IP:/home/$REMOTE_USER
scp -P 2200 -o StrictHostKeyChecking=no init-swarm-mode.sh $REMOTE_USER@$LOADBALANCER_IP:/home/$REMOTE_USER
scp -P 2200 -o StrictHostKeyChecking=no -r ../../resources/azure-storage-driver/ $REMOTE_USER@$LOADBALANCER_IP:/home/$REMOTE_USER
echo "## @WORKERs"
for WORKER in ${WORKERS[@]}; do
    echo "# $WORKER"
    ssh -p 2200 -o StrictHostKeyChecking=no $REMOTE_USER@$LOADBALANCER_IP scp -o StrictHostKeyChecking=no -r /home/$REMOTE_USER/azure-storage-driver/ $WORKER:/home/$REMOTE_USER
done
echo "########################################"

echo "########################################"
echo "## INSTALL DOCKER CLOUDSTOR PLUGIN #####"
echo "## @Manager"
ssh -p 2200 -o StrictHostKeyChecking=no $REMOTE_USER@$LOADBALANCER_IP 'docker plugin install docker4x/cloudstor:azure-v17.03.0-ce --grant-all-permissions'
ssh -p 2200 -o StrictHostKeyChecking=no $REMOTE_USER@$LOADBALANCER_IP 'docker plugin ls'
echo "## @WORKERs"
for WORKER in ${WORKERS[@]}; do
    echo "# $WORKER"
    ssh -p 2200 -o StrictHostKeyChecking=no $REMOTE_USER@$LOADBALANCER_IP ssh -o StrictHostKeyChecking=no $WORKER docker plugin install docker4x/cloudstor:azure-v17.03.0-ce --grant-all-permissions
done
echo "########################################"

echo "########################################"
echo "## INSTALL DOCKER AZURE FILE PLUGIN ####"
echo "## @Manager"
ssh -p 2200 -o StrictHostKeyChecking=no $REMOTE_USER@$LOADBALANCER_IP 'cd azure-storage-driver && sudo ./install.sh'
ssh -p 2200 -o StrictHostKeyChecking=no $REMOTE_USER@$LOADBALANCER_IP 'docker plugin ls'
echo "## @WORKER"
for WORKER in ${WORKERS[@]}; do
    echo "# $WORKER"
    ssh -p 2200 -o StrictHostKeyChecking=no $REMOTE_USER@$LOADBALANCER_IP ssh -o StrictHostKeyChecking=no $WORKER << EOF
          cd azure-storage-driver
          ls -lath;
          sudo ./install.sh
          echo $HOSTNAME
EOF
    ssh -p 2200 -o StrictHostKeyChecking=no $REMOTE_USER@$LOADBALANCER_IP ssh -o StrictHostKeyChecking=no $WORKER docker plugin ls
done
echo "########################################"

echo "########################################"
echo "## INIT SWARM MODE ON MANAGER VM #######"
ssh -p 2200 $REMOTE_USER@$LOADBALANCER_IP './init-swarm-mode.sh'
echo "########################################"

echo "########################################"
echo "## RETRIEVE WORKER TOKEN ###############"
TOKEN=$(ssh -p 2200 -o StrictHostKeyChecking=no ${REMOTE_USER}@${LOADBALANCER_IP} docker swarm join-token -q worker)
echo "## Worker Token=$TOKEN"
MANAGER_INTERNAL_IP=$(ssh -p 2200 -o StrictHostKeyChecking=no ${REMOTE_USER}@${LOADBALANCER_IP} './get-internal-ip.sh')
echo "## MANAGER_INTERNAL_IP=$MANAGER_INTERNAL_IP"
echo "########################################"

echo "########################################"
echo "## WORKER JOIN SWARM CLUSTER ###########"
for WORKER in ${WORKERS[@]}; do
    echo "# $WORKER"
    ssh -p 2200 -o StrictHostKeyChecking=no $REMOTE_USER@$LOADBALANCER_IP ssh $WORKER docker swarm join --token ${TOKEN} ${MANAGER_INTERNAL_IP}:2377
done
echo "########################################"

echo "########################################"
echo "## CHECK NODES ON MANAGER ##############"
ssh -p 2200 -o StrictHostKeyChecking=no $REMOTE_USER@$LOADBALANCER_IP 'docker node ls'
echo "########################################"

