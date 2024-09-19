CONFIG=debug
ifeq ($(CONFIG), "release")
FLAGS=--release
endif

all: rust.iso

esp/efi/boot/bootx64.efi:
	cargo build --target=x86_64-unknown-uefi $(FLAGS)
	cp target/x86_64-unknown-uefi/$(CONFIG)/osdev.efi esp/efi/boot/bootx64.efi

esp/efi/boot/bootx32.efi:
	cargo build --target=i686-unknown-uefi $(FLAGS)
	cp target/i686-unknown-uefi/$(CONFIG)/osdev.efi esp/efi/boot/bootx32.efi

esp/efi/boot/bootaa64.efi:
	cargo build --target=aarch64-unknown-uefi $(FLAGS)
	cp target/aarch64-unknown-uefi/$(CONFIG)/osdev.efi esp/efi/boot/bootaa64.efi

rust.iso: esp/efi/boot/bootx64.efi esp/efi/boot/bootx32.efi esp/efi/boot/bootaa64.efi
	dd if=/dev/zero of=rust.iso count=1 bs=1M
	mkfs.vfat ./rust.iso
	mmd -i rust.iso ::efi
	mmd -i rust.iso ::efi/boot
	mcopy -i rust.iso esp/efi/boot/bootx64.efi ::/efi/boot/bootx64.efi
	mcopy -i rust.iso esp/efi/boot/bootx32.efi ::/efi/boot/bootx32.efi
	mcopy -i rust.iso esp/efi/boot/bootaa64.efi ::/efi/boot/bootaa64.efi

run: rust.iso
	/usr/libexec/qemu-kvm -cpu host -machine type=q35,accel=kvm \
	-display gtk \
	-drive if=pflash,format=raw,readonly=on,file=OVMF_CODE.secboot.fd \
	-drive if=pflash,format=raw,readonly=on,file=OVMF_VARS.secboot.fd \
	-drive format=raw,file=rust.iso

clean:
	rm rust.iso
	rm esp/efi/boot/boot*
	cargo clean