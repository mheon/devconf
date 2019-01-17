# Initial setup
sudo cp /usr/share/doc/audit/rules/10-base-config.rules /etc/audit/rules.d/audit.rules
sudo augenrules --load > /dev/null
sudo systemctl restart auditd 2> /dev/null
sudo podman build -t buildah-ctr .
sudo mkdir /tmp/mycontainer
sudo podman kill -a
sudo podman rm -af
podman kill -a
sleep 1
podman rm -af
clear

read -p "DevConf Demos!"
echo ""

# Buildah from scratch - minimal images
read -p "Buildah from scratch - building minimal images"
echo ""

read -p "--> ctr=\$(sudo buildah from scratch)"
ctr=$(sudo buildah from scratch)
echo $ctr
echo ""

read -p "--> mnt=\$(sudo buildah mount \$ctr)"
mnt=$(sudo buildah mount $ctr)
echo $mnt
echo ""

echo "--> sudo dnf install -y --installroot=\$mnt busybox --releasever=28 --disablerepo=* --enablerepo=fedora"
sudo dnf install -y --installroot=$mnt busybox --releasever=28 --disablerepo=* --enablerepo=fedora
echo ""

read -p "--> sudo dnf clean all --installroot=\$mnt"
sudo dnf clean all --installroot=$mnt
echo ""

read -p "--> sudo buildah unmount \$ctr"
sudo buildah unmount $ctr
echo ""

read -p "--> sudo buildah commit \$ctr minimal-image"
sudo buildah commit $ctr minimal-image
echo ""

read -p "--> sudo podman run minimal-image ping"
sudo podman run minimal-image ping
echo ""

read -p "--> sudo podman run minimal-image python"
sudo podman run minimal-image python
echo ""

read -p "--> sudo podman run minimal-image busybox"
sudo podman run minimal-image busybox
echo ""

read -p "--> cleanup"
sudo buildah rm -a
sudo podman rm -a -f
echo ""

read -p "--> clear"
clear

# Buildah inside a container
read -p "Buildah inside a container"
echo ""

# Already built an image with buildah installed in it
# and made buildah the entrypoint
read -p "--> cat Dockerfile"
cat Dockerfile
echo ""
echo ""

read -p "--> sudo podman run -v \$PWD/myvol:/myvol:Z -v /var/lib/mycontainer:/var/lib/containers:Z buildah-ctr --storage-driver vfs bud -t myimage --isolation chroot /myvol"
sudo podman run --net=host -v $PWD/myvol:/myvol:Z -v /tmp/mycontainer:/var/lib/containers:Z buildah-ctr --storage-driver vfs bud -t myimage --isolation chroot /myvol
echo ""

read -p "--> sudo podman run -v /var/lib/mycontainer:/var/lib/containers:Z buildah-ctr --storage-driver vfs images"
sudo podman run --net=host -v /tmp/mycontainer:/var/lib/containers:Z buildah-ctr --storage-driver vfs images
echo ""

read -p "--> cleanup"
sudo podman rm -a -f
sudo rm -rf /tmp/mycontainer
echo ""

read -p "--> clear"
clear

# Rootless podman
read -p "Podman as rootless"
echo ""

read -p "--> podman pull alpine"
podman pull alpine
echo ""

read -p "--> podman images"
podman images
echo ""

read -p "--> sudo podman images"
sudo podman images
echo ""

read -p "--> podman run alpine ls"
podman run --net=host --rm alpine ls
echo ""

read -p "--> clear"
clear

# Podman user namespace
read -p "Podman User Namespace Support"
echo ""

read -p "--> sudo podman run --uidmap 0:100000:5000 -d fedora sleep 1000"
sudo podman run --net=host --uidmap 0:100000:5000 -d fedora sleep 1000
echo ""

read -p "--> sudo podman top --latest user huser"
sudo podman top --latest user huser
echo ""

read -p "--> ps -Alf | grep sleep"
ps -Alf | grep sleep
echo ""

read -p "--> sudo podman run --uidmap 0:200000:5000 -d fedora sleep 1000"
sudo podman run --net=host --uidmap 0:200000:5000 -d fedora sleep 1000
echo ""

read -p "--> sudo podman top --latest user huser"
sudo podman top --latest user huser
echo ""

read -p "--> ps -Alf | grep sleep"
ps -Alf | grep sleep
echo ""

read -p "--> cleanup"
sudo podman stop -t 0 -a
sudo buildah rm -a
sudo podman rm -a -f
echo ""

read -p "--> clear"
clear

# Podman Fork/Exec model
read -p "Podman Fork/Exec Model"
echo ""

read -p "--> cat /proc/self/loginuid"
cat /proc/self/loginuid
echo ""
echo ""

read -p "--> sudo podman run -ti fedora bash -c \"cat /proc/self/loginuid; echo\""
sudo podman run -ti fedora bash -c "cat /proc/self/loginuid; echo"
echo ""

read -p "--> sudo docker run -ti fedora bash -c \"cat /proc/self/loginuid; echo\""
sudo docker run -ti fedora bash -c "cat /proc/self/loginuid; echo"
echo ""

# Showing how podman keeps track of the person trying to wreak havoc on your system
read -p "--> sudo auditctl -w /etc/shadow"
sudo auditctl -w /etc/shadow 2>/dev/null
echo ""

read -p "--> sudo podman run --privileged -v /:/host fedora touch /host/etc/shadow"
sudo podman run --privileged -v /:/host fedora touch /host/etc/shadow
echo ""

read -p "--> ausearch -m path -ts recent -i | grep touch | grep --color=auto 'auid=[^ ]*'"
sudo ausearch -m path -ts recent -i | grep touch | grep --color=auto 'auid=[^ ]*'
echo ""

read -p "--> sudo docker run --privileged -v /:/host fedora touch /host/etc/shadow"
sudo docker run --privileged -v /:/host fedora touch /host/etc/shadow
echo ""

read -p "--> ausearch -m path -ts recent -i | grep touch | grep --color=auto 'auid=[^ ]*'"
sudo ausearch -m path -ts recent -i | grep touch | grep --color=auto 'auid=[^ ]*'
echo ""

read -p "--> clear"
clear

# Podman top commands
read -p "Podman top features"
echo ""

read -p "--> sudo podman run -d fedora sleep 1000"
sudo podman run -d fedora sleep 1000
echo ""

read -p "--> sudo podman top --latest label"
sudo podman top --latest label
echo ""

read -p "--> sudo podman top --latest seccomp"
sudo podman top --latest seccomp
echo ""

read -p "--> sudo podman top --latest capeff"
sudo podman top --latest capeff
echo ""

read -p "--> clear"
clear

# Skopeo inspect a remote image
read -p "Inspect a remote image using skopeo"
echo ""

read -p "--> skopeo inspect docker://docker.io/fedora"
skopeo inspect docker://docker.io/fedora
echo ""

read -p "--> clear"
clear

# CRI-O read-only mode
read -p "CRI-O read-only mode"
echo ""

read -p "--> cat /etc/crio/crio.conf | grep read_only"
cat /etc/crio/crio.conf | grep read_only
echo ""

read -p "--> sudo systemctl restart crio"
sudo systemctl restart crio
echo ""

read -p "--> POD=\$(sudo crictl runp sandbox_config.json)"
POD=$(sudo crictl runp sandbox_config.json)
echo $POD
echo ""

read -p "--> CTR=\$(sudo crictl create \$POD container_demo.json sandbox_config.json)"
CTR=$(sudo crictl create $POD container_demo.json sandbox_config.json)
echo $CTR
echo ""

read -p "--> sudo crictl start \$CTR"
sudo crictl start $CTR
echo ""

read -p "--> sudo crictl exec --sync \$CTR dnf install buildah"
sudo crictl exec --sync $CTR dnf install buildah
echo ""

read -p "--> cleanup"
sudo crictl stopp $POD
sudo crictl rmp $POD
echo ""

read -p "--> clear"
clear

# Modifying capabilities in CRI-O
read -p "Modifying capabilities in CRI-O"
echo ""

read -p "--> sudo vim /etc/crio/crio.conf"
sudo emacs -nw /etc/crio/crio.conf
echo ""

read -p "--> sudo systemctl restart crio"
sudo systemctl restart crio
echo ""

read -p "--> POD=\$(sudo crictl runp sandbox_config.json)"
POD=$(sudo crictl runp sandbox_config.json)
echo $POD
echo ""

read -p "--> CTR=\$(sudo crictl create \$POD container_demo.json sandbox_config.json)"
CTR=$(sudo crictl create $POD container_demo.json sandbox_config.json)
echo $CTR
echo ""

read -p "--> sudo crictl start \$CTR"
sudo crictl start $CTR
echo ""

read -p "--> sudo crictl exec -i -t \$CTR capsh --print"
sudo crictl exec -i -t $CTR capsh --print
echo ""

read -p "--> sudo cat /run/containers/storage/overlay-containers/\$POD/userdata/config.json | grep -A 50 'ociVersion'"
sudo cat /run/containers/storage/overlay-containers/$POD/userdata/config.json | grep -A 50 'ociVersion'
echo ""

read -p "--> cleanup"
sudo crictl stopp $POD
sudo crictl rmp $POD
echo ""

read -p "--> clear"
clear

read -p "End of Demo"
echo "Thank you!"
