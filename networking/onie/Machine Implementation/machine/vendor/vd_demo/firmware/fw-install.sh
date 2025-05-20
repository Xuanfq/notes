#!/bin/sh

PACK_CPLD_FILE="all-in-one-sbv0-bbv1-cv2.vme"
PACK_CPLD_VERSION="V0"

PACK_FPGA_FILE="fpga-v1.bin"
PACK_FPGA_VERSION="0x00000001"

PACK_BIOS_FILE="bios-v1.bin"
PACK_BIOS_VERSION="1"

PACK_BMC_FILE="bmc-v1.ima"
PACK_BMC_MAJOR_VERSION=0
PACK_BMC_MINOR_VERSION=1

echo "================ Prepare ================" 

cp bios/* /bin/
cp bmc/* /bin/
cp cpld/* /bin/
cp fpga/* /bin/

cp -r libs/* /lib/

echo "================ CPLD ================"

current_cpld_version = `cat /sys/class/firmware/cpld/version`
if [ "$current_cpld_version" != "$PACK_CPLD_VERSION" ]; then
    cp tools/reboot-cmd /tmp  # for Power Cycle after update

    echo "CPLD version mismatch. Expected: $PACK_CPLD_VERSION, Current: $current_cpld_version"
    echo "Updating CPLD..."
    # Update CPLD logic here
    /bin/vmetool /bin/$PACK_CPLD_FILE || {
        echo "CPLD update failed."
        exit 1
    }
else
    echo "CPLD version is up to date."
fi


echo "================ FPGA ================"

# ...

echo "================ BIOS ================"

# ...

echo "================ BMC ================="

# ...


# No errors detected
echo "Update complete.  No errors detected."
exit 0
