#!/bin/bash
###################### Config MON ####################
# Copy ceph.pub to authorized key in monitor node
for mons in `sed -n '/ceph_mons/,/ceph_osds/{/ceph_mons/!{/ceph_osds/!p;};}' inventory` ; do  ssh-copy-id -f -i /etc/ceph/ceph.pub root@$mons;  done
## Add nodes to the cluster ##
for mons in `sed -n '/ceph_mons/,/ceph_osds/{/ceph_mons/!{/ceph_osds/!p;};}' inventory` ; do sudo ceph orch host add $mons;  done
##Label the nodes with mon ##
manager=$(tail -1 ~/inventory)
sudo ceph orch host label add $manager mon
for mons in `sed -n '/ceph_mons/,/ceph_osds/{/ceph_mons/!{/ceph_osds/!p;};}' inventory` ; do sudo ceph orch host label add  $mons mon;  done
sleep 30
## Apply configs##
for mons in `sed -n '/ceph_mons/,/ceph_osds/{/ceph_mons/!{/ceph_osds/!p;};}' inventory` ; do sudo ceph orch apply mon  $mons;  done
##################### Host list ######################
sudo ceph orch host ls
sleep 120
sudo docker ps
###################### Config OSD ####################

# Copy ceph.pub to authorized key in monitor node
for osds in `sed -n '/ceph_osds/,/manager/{/ceph_osds/!{/manager/!p;};}' inventory` ; do  ssh-copy-id -f -i /etc/ceph/ceph.pub root@$osds;  done
## Add hosts to cluster ##
for osds in `sed -n '/ceph_osds/,/manager/{/ceph_osds/!{/manager/!p;};}' inventory` ; do sudo ceph orch host add $osds;  done
##Give new nodes labels ##
for osds in `sed -n '/ceph_osds/,/manager/{/ceph_osds/!{/manager/!p;};}' inventory` ; do sudo ceph orch host label add  $osds osd ;  done
sleep 30
sudo ceph orch device ls
sudo ceph orch device ls | awk  'NR>1 ' > disks.txt
while read line;do
  name=$(echo $line|awk '{print $1}')
  disk=$(echo $line|awk '{print $2}')
  sudo ceph orch daemon add osd $name:$disk
done <disks.txt
