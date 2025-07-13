# Boot2Docker (modernized)


**Boot2Docker — no longer deprecated** — this is a **modernized revival** of the lightweight Linux distribution made to run [Docker](https://www.docker.com/) containers. It now focuses on:

- Updated Linux Kernel with Tiny Core Linux 16.x
- Full **cgroup v2** support
- Compatibility with **FreeBSD**, including support for VirtualBox and bhyve
- Removal of outdated or unmaintained VM backends

---

## Overview

Boot2Docker is a minimal Linux distribution that runs Docker containers out of the box. It runs entirely from RAM, boots in seconds, and is ideal for lightweight or temporary container environments.

## Features

- ⚙️ Modern (6.12) Linux kernel (aligned with Docker compatibility)
- 🐧 Based on [Tiny Core Linux 16.x](http://tinycorelinux.net/)
- 🧠 Runs from RAM (~75MB ISO)
- 📦 Docker preinstalled
- 📂 Persistent storage via disk automount
- 🔐 SSH key and Docker data persistence
- 🧠 **cgroup v2** support (for modern container runtimes)
- 🧊 Focus on **FreeBSD**: VirtualBox and bhyve VM drivers supported

> This project emphasizes support for FreeBSD users by maintaining clean, minimal integration with bhyve and VirtualBox. Other VM drivers and Docker Toolbox are no longer supported.

---

## Installation

### ISO download

Releases are published here:  
👉 [GitHub Releases](https://github.com/atagtm/boot2docker/releases)


### Usage with Docker Machine

You can use the ISO with [Docker Machine](https://docs.docker.com/machine/overview/) and a compatible driver:

```console
docker-machine create \
  --driver virtualbox \
  --virtualbox-boot2docker-url=https://github.com/atagtm/boot2docker/releases/download/v28.3.2/boot2docker.iso \
  default
```

For FreeBSD, use a bhyve-compatible driver like docker-machine-driver-bhyve (updating is in progress).

## Configuration and Debugging

### Customizing Docker daemon

You can configure the Docker daemon by editing.
For example, to enable core dumps:
```console
# vi /var/lib/boot2docker/profile
EXTRA_ARGS="--default-ulimit core=-1"
```
or to enable containerd image store:
```console
# vi /etc/docker/daemon.json
{
  "features": {
    "containerd-snapshotter": true
  }
}
```
Then restart the VM or the daemon.

### SSH into VM

```console
$ docker-machine ssh default
```

Docker Machine auto logs in using the generated SSH key, but if you want to SSH
into the machine manually (or you're not using a Docker Machine managed VM), the
credentials are:

```
user: docker
pass: tcuser
```

#### Persist data

Boot2docker uses [Tiny Core Linux](http://tinycorelinux.net), which runs from
RAM and so does not persist filesystem changes by default.

When you run `docker-machine`, the tool auto-creates a disk that
will be automounted and used to persist your docker data in `/var/lib/docker`
and `/var/lib/boot2docker`.  This virtual disk will be removed when you run
`docker-machine delete default`.  It will also persist the SSH keys of the machine.
Changes outside of these directories will be lost after powering down or
restarting the VM.

If you are not using the Docker Machine management tool, you can create an `ext4`
formatted partition with the label `boot2docker-data` (`mkfs.ext4 -L
boot2docker-data /dev/sdX5`) to your VM or host, and Boot2Docker will automount
it on `/mnt/sdX` and then softlink `/mnt/sdX/var/lib/docker` to
`/var/lib/docker`.

### Contributing

This is a community-driven continuation of the original Boot2Docker project.
Patches welcome — especially if you're improving support for FreeBSD or helping slim the image even more.

### License

MIT / Apache 2.0
Originally by the Docker team; continued by community.
