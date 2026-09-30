# onie

The full name of onie is `Open Network Install Environment`

ONIE is a small operating system, pre-installed on bare metal network switches, that provides an environment for automated provisioning.

## Source Code

[GitHub](https://github.com/opencomputeproject/onie)

## Documentation

[Documentation](https://opencomputeproject.github.io/onie)

## Building

The recommended way to set up an ONIE build environment is to use a Docker image, as described in the ONIE Documentation under [Preparing An ONIE Build Environment](https://opencomputeproject.github.io/onie/developers/building.html#preparing-an-onie-build-environment).

```sh
# enter due env
due -r xxx
# build
cd build-config
make -j4 MACHINEROOT=../machine/<vendor> MACHINE=<vendor>_<model> all
# make -j4 MACHINEROOT=../machine/<vendor> MACHINE=<vendor>_<model> all firmware-update (With firmware-update Need)
```

### ONIE FW Updater

```sh
cd build-config
make -j4 MACHINEROOT=../machine/<vendor> MACHINE=<vendor>_<model> tree-stamp        # if not build all first
make -j4 MACHINEROOT=../machine/<vendor> MACHINE=<vendor>_<model> firmware-update
```

### Modify and Rebuild

- No kernel modify
```sh
make -j4 MACHINEROOT=../machine/<vendor> MACHINE=<vendor>_<model> image-clean firmware-update-clean
make -j4 MACHINEROOT=../machine/<vendor> MACHINE=<vendor>_<model> all
make -j4 MACHINEROOT=../machine/<vendor> MACHINE=<vendor>_<model> firmware-update
# make -j4 MACHINEROOT=../machine/<vendor> MACHINE=<vendor>_<model> all firmware-update (With firmware-update Need)
```

## Release

[Github](https://github.com/opencomputeproject/onie/releases)

[Documentation News](https://opencomputeproject.github.io/onie/news/index.html)
