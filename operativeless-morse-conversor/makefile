# rutas de proyecto
SRC_DIR      := src
OUT_DIR      := build
IMG_DIR      := img
MNT_DIR      := mnt

# imagen "USB"
DISK_IMAGE   := $(abspath $(IMG_DIR)/morser.vhd)
DISK_SIZE    := 512M

# nombre estandar en la ESP
EFI_NAME     := BOOTX64.EFI

# fuentes/artefactos
ASM_SRC      := $(SRC_DIR)/morser.asm
OBJ_FILE     := $(OUT_DIR)/morser.obj
EFI_FILE     := $(OUT_DIR)/$(EFI_NAME)
OVMF_VARS    := $(OUT_DIR)/OVMF_VARS.fd

# herramientas
NASM := nasm
LINK := lld-link
QEMU := qemu-system-x86_64

# audio QEMU
AUDIO_BACKEND ?= pa
AUDIO_ID      := ad0
QEMU_AUDIO    := -audiodev $(AUDIO_BACKEND),id=$(AUDIO_ID)
QEMU_PCSPK    := -machine pcspk-audiodev=$(AUDIO_ID)

# flags
NASMFLAGS    := -f win64
LDFLAGS      := -subsystem:efi_application -entry:_start

# OVMF: se autodetecta, pero se puede sobreescribir por linea de comando
OVMF_CODE    ?= $(shell find /usr/share -name "OVMF_CODE*.fd"  | head -n 1)
OVMF_VARS_SRC?= $(shell find /usr/share -name "OVMF_VARS*.fd"  | head -n 1)

# destino: image (default) o usb
TARGET ?= image

ifeq ($(TARGET),usb)
DISK_IMAGE ?= /dev/sdX   # ⚠️ cambia a tu USB real
endif

.PHONY: all setup-disk create-partitions format-partitions mount-efi \
        compile execute cleanup clean info help

# flujo inicial completo
all: setup-disk create-partitions format-partitions mount-efi compile
	@echo "==> listo. Ahora haz 'make execute' para probar en QEMU (solo image)."

# crear archivo de disco + asociar loop
setup-disk:
ifeq ($(TARGET),image)
	@mkdir -p "$(IMG_DIR)"
	fallocate -l "$(DISK_SIZE)" "$(DISK_IMAGE)"
	sudo losetup -fP "$(DISK_IMAGE)"
	@losetup -a | grep "$(DISK_IMAGE)" || true
else ifeq ($(TARGET),usb)
	sudo sync
	@if [ -z "$(DISK_IMAGE)" ]; then echo "Debes pasar DISK_IMAGE=/dev/sdX"; exit 1; fi
	@echo "==> Usando USB real en $(DISK_IMAGE)"
endif

# particiones GPT: p1=ESP (FAT32 100MiB), p2=FAT32 resto
create-partitions:
ifeq ($(TARGET),image)
	$(eval LOOP := $(shell losetup -j "$(DISK_IMAGE)" | head -n1 | cut -d: -f1))
	@if [ -z "$(LOOP)" ]; then echo "No hay loop para $(DISK_IMAGE)"; exit 1; fi
	sudo parted "$(LOOP)" --script mklabel gpt
	sudo parted "$(LOOP)" --script mkpart EFI fat32 1MiB 101MiB
	sudo parted "$(LOOP)" --script set 1 esp on
	sudo parted "$(LOOP)" --script mkpart primary fat32 101MiB 100%
else ifeq ($(TARGET),usb)
	@if [ -z "$(DISK_IMAGE)" ]; then echo "Debes pasar DISK_IMAGE=/dev/sdX"; exit 1; fi
	@echo "==> Desmontando particiones existentes en $(DISK_IMAGE)"
	-sudo umount $(DISK_IMAGE)1 2>/dev/null || true
	-sudo umount $(DISK_IMAGE)2 2>/dev/null || true
	sudo parted "$(DISK_IMAGE)" --script mklabel gpt
	sudo parted "$(DISK_IMAGE)" --script mkpart EFI fat32 1MiB 101MiB
	sudo parted "$(DISK_IMAGE)" --script set 1 esp on
	sudo parted "$(DISK_IMAGE)" --script mkpart primary fat32 101MiB 100%
endif

# formatear p1 y p2
format-partitions:
ifeq ($(TARGET),image)
	$(eval LOOP := $(shell losetup -j "$(DISK_IMAGE)" | head -n1 | cut -d: -f1))
	@if [ -z "$(LOOP)" ]; then echo "No hay loop para $(DISK_IMAGE)"; exit 1; fi
	sudo mkfs.vfat -F32 "$(LOOP)p1"
	sudo mkfs.vfat -F32 "$(LOOP)p2"
else ifeq ($(TARGET),usb)
	@if [ -z "$(DISK_IMAGE)" ]; then echo "Debes pasar DISK_IMAGE=/dev/sdX"; exit 1; fi
	sudo mkfs.vfat -F32 "$(DISK_IMAGE)1"
	sudo mkfs.vfat -F32 "$(DISK_IMAGE)2"
endif

# montar la ESP en mnt y crear \EFI\BOOT
mount-efi:
ifeq ($(TARGET),image)
	$(eval LOOP := $(shell losetup -j "$(DISK_IMAGE)" | head -n1 | cut -d: -f1))
	@if [ -z "$(LOOP)" ]; then echo "No hay loop para $(DISK_IMAGE)"; exit 1; fi
	sudo mkdir -p "$(MNT_DIR)"
	sudo mount "$(LOOP)p1" "$(MNT_DIR)"
	sudo mkdir -p "$(MNT_DIR)/EFI/BOOT"
else ifeq ($(TARGET),usb)
	@if [ -z "$(DISK_IMAGE)" ]; then echo "Debes pasar DISK_IMAGE=/dev/sdX"; exit 1; fi
	sudo mkdir -p "$(MNT_DIR)"
	sudo mount "$(DISK_IMAGE)1" "$(MNT_DIR)"
	sudo mkdir -p "$(MNT_DIR)/EFI/BOOT"
endif

# compilar y copiar a \EFI\BOOT\BOOTX64.EFI
compile: $(EFI_FILE)
	@if ! mountpoint -q "$(MNT_DIR)"; then \
	  echo "La ESP no está montada en $(MNT_DIR)."; \
	  exit 1; \
	fi
	sudo cp "$(EFI_FILE)" "$(MNT_DIR)/EFI/BOOT/$(EFI_NAME)"

# reglas de build
$(EFI_FILE): $(OBJ_FILE)
	@mkdir -p "$(OUT_DIR)"
	$(LINK) $(LDFLAGS) -out:"$@" "$(OBJ_FILE)"

$(OBJ_FILE): $(ASM_SRC)
	@mkdir -p "$(OUT_DIR)"
	$(NASM) $(NASMFLAGS) "$<" -o "$@"

# arrancar en QEMU (solo para imagen)
execute:
ifeq ($(TARGET),image)
	- sudo umount "$(MNT_DIR)" 2>/dev/null || true
	$(eval LOOP := $(shell losetup -j "$(DISK_IMAGE)" | head -n1 | cut -d: -f1))
	@if [ -n "$(LOOP)" ]; then sudo losetup -d "$(LOOP)"; fi
	@if [ -z "$(OVMF_CODE)" ] || [ ! -f "$(OVMF_CODE)" ]; then \
	  echo "No encontré OVMF_CODE. Instala 'ovmf' o pásalo por línea de comando."; \
	  exit 1; \
	fi
	@if [ ! -f "$(OVMF_VARS)" ]; then mkdir -p "$(OUT_DIR)"; cp "$(OVMF_VARS_SRC)" "$(OVMF_VARS)"; fi
	$(QEMU) -m 512M -cpu qemu64 \
	  $(QEMU_AUDIO) $(QEMU_PCSPK) \
	  -drive if=pflash,format=raw,readonly=on,file="$(OVMF_CODE)" \
	  -drive if=pflash,format=raw,file="$(OVMF_VARS)" \
	  -drive file="$(DISK_IMAGE)",format=raw
else
	@echo "==> 'make execute' solo está disponible en modo imagen."
endif


# compilar y copiar a la USB (modo rapido)
install: $(EFI_FILE)
	@if [ "$(TARGET)" != "usb" ]; then \
	  echo "Este target es solo para TARGET=usb"; exit 1; \
	fi
	@if [ -z "$(DISK_IMAGE)" ]; then echo "Debes pasar DISK_IMAGE=/dev/sdX"; exit 1; fi
	sudo mkdir -p "$(MNT_DIR)"
	sudo mount "$(DISK_IMAGE)1" "$(MNT_DIR)"
	sudo mkdir -p "$(MNT_DIR)/EFI/BOOT"
	sudo cp "$(EFI_FILE)" "$(MNT_DIR)/EFI/BOOT/$(EFI_NAME)"
	sudo umount "$(MNT_DIR)"
	@echo "==> Instalado en la USB: $(DISK_IMAGE)"

# desmontar/soltar loop
cleanup:
	- sudo umount "$(MNT_DIR)" 2>/dev/null || true
ifeq ($(TARGET),image)
	$(eval LOOP := $(shell losetup -j "$(DISK_IMAGE)" | head -n1 | cut -d: -f1))
	@if [ -n "$(LOOP)" ]; then sudo losetup -d "$(LOOP)"; fi
endif

# limpieza completa (incluye imagen)
clean: cleanup
ifeq ($(TARGET),image)
	rm -rf "$(OUT_DIR)" "$(IMG_DIR)"
endif
	rm -rf "$(MNT_DIR)"
	@echo "Limpio"

# info de estado util
info:
	@echo "TARGET: $(TARGET)"
	@echo "DISK_IMAGE: $(DISK_IMAGE)"
ifeq ($(TARGET),image)
	@losetup -j "$(DISK_IMAGE)" || echo "sin loop"
	@if [ -f "$(DISK_IMAGE)" ]; then sudo fdisk -l "$(DISK_IMAGE)" 2>/dev/null || true; fi
endif
	@echo "ESP montada?: " && (mountpoint -q "$(MNT_DIR)" && echo "sí" || echo "no")
	@echo "EFI_FILE: $(EFI_FILE)  [$$( [ -f "$(EFI_FILE)" ] && echo OK || echo MISSING )]"
	@echo "OVMF_CODE: $(OVMF_CODE)"
	@echo "OVMF_VARS_SRC: $(OVMF_VARS_SRC)"

help:
	@echo "Targets:"
	@echo "  all                -> crea imagen/usb + particiona + formatea + monta"
	@echo "  compile            -> build + copia a \\EFI\\BOOT\\$(EFI_NAME)"
	@echo "  execute            -> arranca QEMU con OVMF (solo imagen)"
	@echo "  cleanup / clean    -> desmonta / borra artefactos"
	@echo "Tips:"
	@echo "  make all TARGET=usb DISK_IMAGE=/dev/sdX"
	@echo "  make all TARGET=image"
