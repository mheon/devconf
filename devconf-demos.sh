#!/bin/sh

# devconf-demos.sh demo script.
# This script will demonstrate security features of buildah,podman,skopeo and cri-o

# Setting up some colors for helping read the demo output.
# Comment out any of the below to turn off that color.
bold=$(tput bold)
blue=$(tput setaf 4)
reset=$(tput sgr0)

read_color() {
    read -p "${bold}$1${reset}"
}

echo_color() {
    echo "${blue}$1${reset}"
}

# Initial setup
setup() {
    rpm -q podman buildah audit >/dev/null
    if [[ $? != 0 ]]; then
	echo $0 requires the podman, buildah and audit packages be installed
	exit 1
    fi
    command -v docker > /dev/null
    if [[ $? != 0 ]]; then
	echo $0 requires the docker package be installed
	exit 1
    fi
    sudo cp /usr/share/doc/audit/rules/10-base-config.rules /etc/audit/rules.d/audit.rules
    sudo augenrules --load > /dev/null
    sudo systemctl restart auditd 2> /dev/null
    sudo systemctl restart docker
    sudo podman kill -a
    sudo podman rm -af
    podman kill -a
    sleep 1
    podman rm -af
    sudo podman rmi $(sudo podman images | grep none | awk '{print $3}')
    sudo docker pull ubuntu
    clear
}

buildah_image() {
    sudo podman images  | grep -q -w buildah-ctr
    if [[ $? != 0 ]]; then
	sudo podman build -t buildah-ctr -f Dockerfile.buildah .
    fi
}

intro() {
    read_color "DevConf Demos!  Buildah, Podman, Skopeo, CRI-O Security"
    echo ""
    clear
}

buildah_minimal_image() {
  # Buildah from scratch - minimal images
  read_color "Buildah from scratch - building minimal images"
  echo ""

  read_color "--> ctr=\$(sudo buildah from scratch)"
  ctr=$(sudo buildah from scratch)
  echo_color $ctr
  echo ""

  read_color "--> mnt=\$(sudo buildah mount \$ctr)"
  mnt=$(sudo buildah mount $ctr)
  echo_color $mnt
  echo ""

  echo "${bold}$1${reset}" "--> sudo dnf install -y --installroot=\$mnt busybox --releasever=29 --disablerepo=* --enablerepo=fedora"
  sudo dnf install -y --installroot=$mnt busybox --releasever=29 --disablerepo=* --enablerepo=fedora 2> /dev/null
  echo ""

  read_color "--> sudo dnf clean all --installroot=\$mnt"
  sudo dnf clean all --installroot=$mnt 2> /dev/null
  echo ""

  read_color "--> sudo buildah unmount \$ctr"
  sudo buildah unmount $ctr
  echo ""

  read_color "--> sudo buildah commit \$ctr minimal-image"
  sudo buildah commit $ctr minimal-image
  echo ""

  read_color "--> sudo podman run minimal-image ping"
  sudo podman run minimal-image ping
  echo ""

  read_color "--> sudo podman run minimal-image python"
  sudo podman run minimal-image python
  echo ""

  read_color "--> sudo podman run minimal-image busybox"
  sudo podman run minimal-image busybox
  echo ""

  read_color "--> cleanup"
  sudo buildah rm -a
  sudo podman rm -a -f
  echo ""

  read_color "--> clear"
  clear
}

buildah_in_container() {
    # Buildah inside a container
    read_color "Buildah inside a container"
    echo ""
    sudo mkdir -p /var/lib/mycontainer
    mkdir -p $PWD/myvol
    cat >$PWD/myvol/Dockerfile <<_EOF
FROM alpine
ENV foo=bar
LABEL colour=blue
_EOF

    read_color "--> cat Dockerfile"
    cat $PWD/myvol/Dockerfile
    echo ""
    echo ""
    read_color "--> sudo podman run -v \$PWD/myvol:/myvol:Z -v /var/lib/mycontainer:/var/lib/containers:Z buildah-ctr --storage-driver vfs bud -t myimage --isolation chroot /myvol"
    sudo podman run --net=host -v $PWD/myvol:/myvol:Z -v /var/lib/mycontainer:/var/lib/containers:Z buildah-ctr --storage-driver vfs bud -t myimage --isolation chroot /myvol
    echo ""

    read_color "--> sudo podman run -v /var/lib/mycontainer:/var/lib/containers:Z buildah-ctr --storage-driver vfs images"
    sudo podman run --net=host -v /var/lib/mycontainer:/var/lib/containers:Z buildah-ctr --storage-driver vfs images
    echo ""

    read_color "--> sudo podman run -v /var/lib/mycontainer:/var/lib/containers:Z buildah-ctr --storage-driver vfs rmi --force --all"
    sudo podman run --net=host -v /var/lib/mycontainer:/var/lib/containers:Z buildah-ctr --storage-driver vfs rmi -f --all
    echo ""

    read_color "--> cleanup"
    echo "podman rm -a -f"
    sudo podman rm -a -f
    echo ""

    read_color "--> clear"
    clear
}

podman_rootless() {
    # Rootless podman
    read_color "Podman as rootless"
    echo ""

    read_color "--> podman pull alpine"
    podman pull alpine
    echo ""

    read_color "--> podman images"
    podman images
    echo ""

    echo "Show Privileged images"
    read_color "--> sudo podman images"
    sudo podman images
    echo ""

    read_color "--> podman run alpine ls"
    podman run --net=host --rm alpine ls
    echo ""

    read_color "--> clear"
    clear
}

podman_userns() {
    echo "
The demo will now unshare the usernamespace of a rootless container,
using the 'buildah unshare' command.

First outside of the continer, we will cat /etc/subuid, and you should
see your username.  This indicates the UID map that is assigned to you.
When executing buildah unshare, it will map your UID to root within the container
and then map the range of UIDS in /etc/subuid starting at UID=1 within your container.
"
    read_color "--> cat /etc/subuid"
    cat /etc/subuid
    echo ""

    echo "


Explore your home directory to see what it looks like while in a user namespace.
'cat /proc/self/uid_map' will show you the user namespace mapping.

Type 'exit' to exit the user namespace and continue running the demo.
"
    read_color "--> buildah unshare"
    buildah unshare
    echo ""

    read_color "--> clear"
    clear

    # Podman user namespace
    read_color "Podman User Namespace Support"
    echo ""

    read_color "--> sudo podman run --uidmap 0:100000:5000 -d fedora sleep 1000"
    sudo podman run --net=host --uidmap 0:100000:5000 -d fedora sleep 1000
    echo ""

    read_color "--> sudo podman top --latest user huser | grep --color=auto -B 1 100000"
    sudo podman top --latest user huser | grep --color=auto -B 1 100000
    echo ""

    read_color "--> ps -ef | grep -v grep | grep --color=auto 100000"
    ps -ef | grep -v grep | grep --color=auto 100000
    echo ""

    read_color "--> sudo podman run --uidmap 0:200000:5000 -d fedora sleep 1000"
    sudo podman run --net=host --uidmap 0:200000:5000 -d fedora sleep 1000
    echo ""

    read_color "--> sudo podman top --latest user huser | grep --color=auto -B 1 200000"
    sudo podman top --latest user huser | grep --color=auto -B 1 200000
    echo ""

    read_color "--> ps -ef | grep -v grep | grep --color=auto 200000"
    ps -ef | grep -v grep | grep --color=auto 200000
    echo ""

    read_color "--> cleanup"
    sudo podman stop -t 0 -a 2> /dev/null
    sudo buildah rm -a 2> /dev/null
    sudo podman rm -a -f 2> /dev/null
    echo ""

    read_color "--> clear"
    clear
}

podman_fork_exec() {
    # Podman Fork/Exec model
    read_color "Podman Fork/Exec Model"
    echo ""

    read_color "--> cat /proc/self/loginuid"
    cat /proc/self/loginuid
    echo ""
    echo ""

    read_color "--> sudo podman run -ti fedora bash -c \"cat /proc/self/loginuid; echo\""
    sudo podman run -ti fedora bash -c "cat /proc/self/loginuid; echo"
    echo ""

    read_color "--> sudo docker run -ti fedora bash -c \"cat /proc/self/loginuid; echo\""
    sudo docker run -ti fedora bash -c "cat /proc/self/loginuid; echo"
    echo ""

    # Showing how podman keeps track of the person trying to wreak havoc on your system
    read_color "--> sudo auditctl -w /etc/shadow"
    sudo auditctl -w /etc/shadow 2>/dev/null
    echo ""

    read_color "--> sudo podman run --privileged -v /:/host fedora touch /host/etc/shadow"
    sudo podman run --privileged -v /:/host fedora touch /host/etc/shadow
    echo ""

    read_color "--> ausearch -m path -ts recent -i | grep touch | grep --color=auto 'auid=[^ ]*'"
    sudo ausearch -m path -ts recent -i | grep touch | grep --color=auto 'auid=[^ ]*'
    echo ""

    read_color "--> sudo docker run --privileged -v /:/host fedora touch /host/etc/shadow"
    sudo docker run --privileged -v /:/host fedora touch /host/etc/shadow
    echo ""

    read_color "--> ausearch -m path -ts recent -i | grep touch | grep --color=auto 'auid=[^ ]*'"
    sudo ausearch -m path -ts recent -i | grep touch | grep --color=auto 'auid=[^ ]*'
    echo ""

    read_color "--> clear"
    clear
}

podman_top() {
    # Podman top commands
    read_color "Podman top features"
    echo ""

    read_color "--> sudo podman run -d fedora sleep 1000"
    sudo podman run -d fedora sleep 1000
    echo ""

    read_color "--> sudo podman top --latest pid hpid"
    sudo podman top --latest pid hpid
    echo ""

    read_color "--> sudo podman top --latest label"
    sudo podman top --latest label
    echo ""
    read_color "--> sudo podman top --latest seccomp"
    sudo podman top --latest seccomp
    echo ""

    read_color "--> sudo podman top --latest capeff"
    sudo podman top --latest capeff
    echo ""

    read_color "--> clear"
    clear
}

skopeo_inspect() {
    # Skopeo inspect a remote image
    read_color "Inspect a remote image using skopeo"
    echo ""

    read_color "--> skopeo inspect docker://docker.io/fedora"
    skopeo inspect docker://docker.io/fedora
    echo ""

    read_color "--> clear"
    clear
}

skopeo_cp_from_docker_to_podman() {
    # Cleanup listing podman images first
    read_color "Cleaning up podman images"
    read_color "--> sudo podman rmi $(sudo podman images | grep none | awk '{print $3}')"
    sudo podman rmi $(sudo podman images | grep none | awk '{print $3}') 2> /dev/null
    echo ""
    echo "${bold}$1${reset}" "--> clear"
    clear

    read_color "Copy images from docker storage to podman storage"
    echo ""

    read_color "--> sudo podman images"
    sudo podman images
    echo ""

    read_color "--> sudo docker images"
    sudo docker images
    echo ""

    read_color "--> sudo skopeo copy docker://docker.io/ubuntu:latest containers-storage:localhost/ubuntu:latest"
    sudo skopeo copy docker://docker.io/ubuntu:latest containers-storage:localhost/ubuntu:latest 2> /dev/null
    echo ""

    read_color "--> sudo podman images"
    sudo podman images
    echo ""

    read_color "--> cleanup"
    sudo podman rmi ubuntu:latest
    echo ""

    read_color "--> clear"
    clear
}

crio_read_only() {
    # CRI-O read-only mode
    read_color "CRI-O read-only mode"
    echo ""

    read_color "--> cat /etc/crio/crio.conf | grep read_only"
    cat /etc/crio/crio.conf | grep read_only
    echo ""

    read_color "--> sudo systemctl restart crio"
    sudo systemctl restart crio
    echo ""

    read_color "--> POD=\$(sudo crictl runp sandbox_config.json)"
    POD=$(sudo crictl runp sandbox_config.json)
    echo_color $POD
    echo ""

    read_color "--> CTR=\$(sudo crictl create \$POD container_demo.json sandbox_config.json)"
    CTR=$(sudo crictl create $POD container_demo.json sandbox_config.json)
    echo_color $CTR
    echo ""

    read_color "--> sudo crictl start \$CTR"
    sudo crictl start $CTR
    echo ""

    read_color "--> sudo crictl exec --sync \$CTR dnf install buildah"
    sudo crictl exec --sync $CTR dnf install buildah
    echo ""

    read_color "--> cleanup"
    sudo crictl stopp $POD >2 /dev/null
    sudo crictl rmp $POD >2 /dev/null
    echo ""

    read_color "--> clear"
    clear
}

crio_modify_caps() {
    # Modifying capabilities in CRI-O
    read_color "Modifying capabilities in CRI-O"
    echo ""

    read_color "--> sudo vim /etc/crio/crio.conf"
    sudo vim /etc/crio/crio.conf
    #sudo emacs -nw /etc/crio/crio.conf
    echo ""

    read_color "--> sudo systemctl restart crio"
    sudo systemctl restart crio
    echo ""

    read_color "--> POD=\$(sudo crictl runp sandbox_config.json)"
    POD=$(sudo crictl runp sandbox_config.json)
    echo_color $POD
    echo ""

    read_color "--> CTR=\$(sudo crictl create \$POD container_demo.json sandbox_config.json)"
    CTR=$(sudo crictl create $POD container_demo.json sandbox_config.json)
    echo_color $CTR
    echo ""

    read_color "--> sudo crictl start \$CTR"
    sudo crictl start $CTR
    echo ""

    read_color "--> sudo crictl exec -i -t \$CTR capsh --print"
    sudo crictl exec -i -t $CTR capsh --print
    echo ""

    read_color "--> sudo cat /run/containers/storage/overlay-containers/\$POD/userdata/config.json | grep -A 50 'ociVersion'"
    sudo cat /run/containers/storage/overlay-containers/$POD/userdata/config.json | grep -A 50 'ociVersion'
    echo ""

    read_color "--> cleanup"
    sudo crictl stopp $POD
    sudo crictl rmp $POD
    echo ""

    read_color "--> clear"
    clear
}

setup
buildah_image
intro
buildah_minimal_image
buildah_in_container
podman_rootless
podman_userns
podman_fork_exec
podman_top
skopeo_inspect
skopeo_cp_from_docker_to_podman
crio_read_only
crio_modify_caps

read_color "End of Demo"
echo_color "Thank you!"
