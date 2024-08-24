# Linux VM Introduce

## KVM

- kvm是开源软件，全称是kernel-based virtual machine（基于内核的虚拟机，是*Linux的一个内核驱动模块*）。
- 是x86架构且硬件支持/辅助虚拟化技术（如 intel VT 或 AMD-V）的linux [全虚拟化] 解决方案。
- 它包含一个为处理器提供底层虚拟化 可加载的核心模块kvm.ko（kvm-intel.ko 或 kvm-AMD.ko）。
- kvm还需要一个经过修改的QEMU软件（qemu-kvm），作为虚拟机上层控制和界面。
- kvm能在不改变linux或windows镜像的情况下同时运行多个虚拟机，（ps：它的意思是多个虚拟机使用同一镜像）并为每一个虚拟机配置个性化硬件环境（网卡、磁盘、图形适配器……）。
- 在主流的linux内核，如2.6.20以上的内核均包含了kvm核心。

## Qemu

- 全称Quick Emulator(仿真器)，本身并不包含或依赖KVM模块。
- 是独立虚拟软件，能独立运行虚拟机（根本不需要kvm）。kqemu是该软件的加速软件（利用kvm进行加速提升性能）。
- kvm并不需要qemu进行虚拟处理，只是需要它的上层管理界面进行虚拟机控制。
- 虚拟机依旧是由kvm驱动。
- qemu-kvm：qemu-kvm是qemu将kvm整合进来，通过ioctl调用kvm的接口，将cpu的指令交给内核来做。kvm负责cpu和内存，而io和网络，磁盘等由qemu负责。

## libvirt

为什么需要Libvirt？

- Hypervisor 比如 qemu-kvm 的命令行虚拟机管理工具参数众多，难以使用
- Hypervisor 种类众多，没有统一的编程接口来管理它们，这对云环境来说非常重要
- 没有统一的方式来方便地定义虚拟机相关的各种可管理对象

Libvirt提供了什么？

- 它提供统一、稳定、开放的源代码的应用程序接口（API）、守护进程（libvirtd）和一个默认命令行管理工具（virsh）。
- 它提供了对虚拟化客户机和它的虚拟化设备、网络和存储的管理。
- 它提供了一套较为稳定的C语言应用程序接口。目前，在其他一些流行的编程语言中也提供了对libvirt的绑定，在Python、Perl、Java、Ruby、PHP、OCaml等高级编程语言中已经有libvirt的程序库可以直接使用。
- 它对多种不同的 Hypervisor的支持是通过一种基于驱动程序的架构来实现的。libvirt 对不同的 Hypervisor 提供了不同的驱动，包括 Xen 的驱动，对 QEMU/KVM 有 QEMU 驱动，VMware 驱动等。在 libvirt 源代码中，可以很容易找到qemu_driver.c、xen_driver.c、xenapi_driver.c、vmware_driver.c、vbox_driver.c 这样的驱动程序源代码文件。
- 它作为中间适配层，让底层 Hypervisor 对上层用户空间的管理工具可以做到完全透明，因为 libvirt 屏蔽了底层各种 Hypervisor 的细节，为上层管理工具提供了一个统一的、较稳定的接口（API）。
- 它使用 XML 来定义各种虚拟机相关的受管理对象。

目前，libvirt 已经成为使用最为广泛的对各种虚拟机进行管理的工具和应用程序接口（API），而且一些常用的虚拟机管理工具（如virsh、virt-install、virt-manager等）和云计算框架平台（如OpenStack、OpenNebula、Eucalyptus等）都在底层使用libvirt的应用程序接口。

![img](Linux%20VM%20Introduce.assets/288c828b9fb723479d08e3d677531264-17245077062107.jpeg)

![img](Linux%20VM%20Introduce.assets/50e60740b200c505dcb7b11193beee80-17245076879685.jpeg)

![img](Linux%20VM%20Introduce.assets/1153533-20180731105741983-680241012.jpg)
