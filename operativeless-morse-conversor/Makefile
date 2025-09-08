# Makefile para configurar kernel.vhd con particiones EFI
# Detecta automáticamente el loop device disponible

DISK_IMAGE = kernel.vhd
DISK_SIZE = 512M
MOUNT_POINT = /mnt/efi
KERNEL_SOURCE = ./src/kernel.asm
KERNEL_OBJ = ./src/kernel.obj
KERNEL_EFI = ./src/kernel.efi
OVMF_VARS = ./OVMF_VARS.fd
OVMF_CODE = /usr/share/OVMF/OVMF_CODE_4M.fd

.PHONY: all setup-disk create-partitions format-partitions mount-efi remount compile execute cleanup clean help

# Target principal
all: setup-disk create-partitions format-partitions mount-efi

# Crear el archivo de imagen del disco
setup-disk:
	@echo "Creando imagen de disco $(DISK_IMAGE) de $(DISK_SIZE)..."
	fallocate -l $(DISK_SIZE) $(DISK_IMAGE)
	@echo "Configurando loop device..."
	sudo losetup -fP $(DISK_IMAGE)
	@echo "Loop devices disponibles:"
	losetup -a

# Crear las particiones GPT
create-partitions:
	@echo "Detectando loop device para $(DISK_IMAGE)..."
	$(eval LOOP_DEVICE := $(shell losetup -j $(DISK_IMAGE) | cut -d: -f1))
	@if [ -z "$(LOOP_DEVICE)" ]; then \
		echo "Error: No se pudo encontrar el loop device para $(DISK_IMAGE)"; \
		exit 1; \
	fi
	@echo "Usando loop device: $(LOOP_DEVICE)"
	@echo "Creando tabla de particiones GPT..."
	sudo parted $(LOOP_DEVICE) --script mklabel gpt
	@echo "Creando partición EFI (1MiB - 101MiB)..."
	sudo parted $(LOOP_DEVICE) --script mkpart EFI fat32 1MiB 101MiB
	@echo "Configurando flag ESP en partición 1..."
	sudo parted $(LOOP_DEVICE) --script set 1 esp on
	@echo "Creando partición primaria (101MiB - 100%)..."
	sudo parted $(LOOP_DEVICE) --script mkpart primary fat32 101MiB 100%

# Formatear las particiones
format-partitions:
	@echo "Detectando loop device para formateo..."
	$(eval LOOP_DEVICE := $(shell losetup -j $(DISK_IMAGE) | cut -d: -f1))
	@if [ -z "$(LOOP_DEVICE)" ]; then \
		echo "Error: No se pudo encontrar el loop device para $(DISK_IMAGE)"; \
		exit 1; \
	fi
	@echo "Formateando partición EFI ($(LOOP_DEVICE)p1)..."
	sudo mkfs.vfat -F32 $(LOOP_DEVICE)p1
	@echo "Formateando partición primaria ($(LOOP_DEVICE)p2)..."
	sudo mkfs.vfat -F32 $(LOOP_DEVICE)p2

# Montar la partición EFI y crear directorios
mount-efi:
	@echo "Detectando loop device para montaje..."
	$(eval LOOP_DEVICE := $(shell losetup -j $(DISK_IMAGE) | cut -d: -f1))
	@if [ -z "$(LOOP_DEVICE)" ]; then \
		echo "Error: No se pudo encontrar el loop device para $(DISK_IMAGE)"; \
		exit 1; \
	fi
	@echo "Creando punto de montaje $(MOUNT_POINT)..."
	sudo mkdir -p $(MOUNT_POINT)
	@echo "Montando partición EFI ($(LOOP_DEVICE)p1) en $(MOUNT_POINT)..."
	sudo mount $(LOOP_DEVICE)p1 $(MOUNT_POINT)
	@echo "Creando estructura de directorios EFI..."
	sudo mkdir -p $(MOUNT_POINT)/EFI
	sudo mkdir -p $(MOUNT_POINT)/EFI/BOOT
	@echo "Setup completado. Partición EFI montada en $(MOUNT_POINT)"

# Remontar la partición EFI (útil si ya existe el loop device)
remount:
	@echo "Detectando loop device existente para $(DISK_IMAGE)..."
	$(eval LOOP_DEVICE := $(shell losetup -j $(DISK_IMAGE) | cut -d: -f1))
	@if [ -z "$(LOOP_DEVICE)" ]; then \
		echo "No se encontró loop device para $(DISK_IMAGE). Configurando..."; \
		sudo losetup -fP $(DISK_IMAGE); \
		LOOP_DEVICE=$$(losetup -j $(DISK_IMAGE) | cut -d: -f1); \
	fi
	@echo "Usando loop device: $(LOOP_DEVICE)"
	@echo "Verificando si $(MOUNT_POINT) ya está montado..."
	@if mountpoint -q $(MOUNT_POINT); then \
		echo "$(MOUNT_POINT) ya está montado. Desmontando primero..."; \
		sudo umount $(MOUNT_POINT); \
	fi
	@echo "Creando punto de montaje $(MOUNT_POINT)..."
	sudo mkdir -p $(MOUNT_POINT)
	@echo "Montando partición EFI ($(LOOP_DEVICE)p1) en $(MOUNT_POINT)..."
	sudo mount $(LOOP_DEVICE)p1 $(MOUNT_POINT)
	@echo "Partición EFI remontada exitosamente en $(MOUNT_POINT)"

# Compilar el kernel y copiarlo a la partición EFI
compile:
	@echo "Compilando kernel desde $(KERNEL_SOURCE)..."
	nasm -f win64 $(KERNEL_SOURCE) -o $(KERNEL_OBJ)
	@echo "Enlazando kernel EFI..."
	lld-link -subsystem:efi_application -entry:_start -out:$(KERNEL_EFI) $(KERNEL_OBJ)
	@echo "Verificando que la partición EFI esté montada..."
	@if ! mountpoint -q $(MOUNT_POINT); then \
		echo "Error: La partición EFI no está montada en $(MOUNT_POINT)"; \
		echo "Ejecuta 'make mount-efi' primero"; \
		exit 1; \
	fi
	@echo "Copiando $(KERNEL_EFI) a la partición EFI..."
	sudo cp $(KERNEL_EFI) $(MOUNT_POINT)/EFI/BOOT/BOOTX64.EFI
	@echo "Kernel compilado y copiado exitosamente a $(MOUNT_POINT)/EFI/BOOT/BOOTX64.EFI"

# Ejecutar el kernel en QEMU
execute:
	@echo "Preparando para ejecutar kernel en QEMU..."
	@echo "Desmontando partición EFI..."
	-sudo umount $(MOUNT_POINT) 2>/dev/null || true
	@echo "Detectando y desconectando loop device..."
	$(eval LOOP_DEVICE := $(shell losetup -j $(DISK_IMAGE) | cut -d: -f1))
	@if [ -n "$(LOOP_DEVICE)" ]; then \
		echo "Desconectando loop device $(LOOP_DEVICE)..."; \
		sudo losetup -d $(LOOP_DEVICE); \
	fi
	@echo "Verificando archivos OVMF..."
	@if [ ! -f "$(OVMF_CODE)" ]; then \
		echo "Error: No se encontró $(OVMF_CODE)"; \
		echo "Instala el paquete ovmf: sudo apt install ovmf"; \
		exit 1; \
	fi
	@if [ ! -f "$(OVMF_VARS)" ]; then \
		echo "Creando archivo de variables OVMF..."; \
		cp /usr/share/OVMF/OVMF_VARS_4M.fd $(OVMF_VARS); \
	fi
	@echo "Iniciando QEMU con kernel EFI..."
	qemu-system-x86_64 \
		-cpu qemu64 \
		-drive if=pflash,format=raw,readonly,file=$(OVMF_CODE) \
		-drive if=pflash,format=raw,file=$(OVMF_VARS) \
		-drive file=$(DISK_IMAGE),format=raw

# Desmontar y limpiar
cleanup:
	@echo "Desmontando partición EFI..."
	-sudo umount $(MOUNT_POINT) 2>/dev/null || true
	@echo "Detectando loop device para limpieza..."
	$(eval LOOP_DEVICE := $(shell losetup -j $(DISK_IMAGE) | cut -d: -f1))
	@if [ -n "$(LOOP_DEVICE)" ]; then \
		echo "Desconectando loop device $(LOOP_DEVICE)..."; \
		sudo losetup -d $(LOOP_DEVICE); \
	fi

# Limpiar completamente (incluye eliminar el archivo de imagen)
clean: cleanup
	@echo "Eliminando archivo de imagen $(DISK_IMAGE)..."
	rm -f $(DISK_IMAGE)
	@echo "Eliminando archivos de compilación..."
	rm -f $(KERNEL_OBJ) $(KERNEL_EFI)
	@echo "Eliminando archivo de variables OVMF..."
	rm -f $(OVMF_VARS)

# Mostrar información del setup actual
info:
	@echo "=== Información del setup ==="
	@echo "Archivo de imagen: $(DISK_IMAGE)"
	@if [ -f "$(DISK_IMAGE)" ]; then \
		echo "Estado del archivo: Existe ($$(du -h $(DISK_IMAGE) | cut -f1))"; \
		LOOP_DEV=$$(losetup -j $(DISK_IMAGE) | cut -d: -f1); \
		if [ -n "$$LOOP_DEV" ]; then \
			echo "Loop device: $$LOOP_DEV"; \
			echo "Particiones:"; \
			sudo fdisk -l $$LOOP_DEV 2>/dev/null | grep "^$$LOOP_DEV" || true; \
			echo "Montajes:"; \
			mount | grep $$LOOP_DEV || echo "  Ninguna partición montada"; \
		else \
			echo "Loop device: No configurado"; \
		fi; \
	else \
		echo "Estado del archivo: No existe"; \
	fi
	@echo "Archivos compilados:"
	@echo "  $(KERNEL_SOURCE): $$([ -f "$(KERNEL_SOURCE)" ] && echo "Existe" || echo "No existe")"
	@echo "  $(KERNEL_OBJ): $$([ -f "$(KERNEL_OBJ)" ] && echo "Existe" || echo "No existe")"
	@echo "  $(KERNEL_EFI): $$([ -f "$(KERNEL_EFI)" ] && echo "Existe" || echo "No existe")"
	@echo "  $(OVMF_VARS): $$([ -f "$(OVMF_VARS)" ] && echo "Existe" || echo "No existe")"

# Mostrar ayuda
help:
	@echo "=== Makefile para configuración de kernel.vhd ==="
	@echo ""
	@echo "Targets disponibles:"
	@echo "  all           - Ejecutar todo el proceso de setup (default)"
	@echo "  setup-disk    - Crear imagen de disco y configurar loop device"
	@echo "  create-partitions - Crear particiones GPT"
	@echo "  format-partitions - Formatear particiones con FAT32"
	@echo "  mount-efi     - Montar partición EFI y crear directorios"
	@echo "  remount       - Remontar partición EFI (si ya existe el archivo)"
	@echo "  compile       - Compilar kernel y copiarlo a la partición EFI"
	@echo "  execute       - Ejecutar kernel en QEMU (desmonta y ejecuta)"
	@echo "  cleanup       - Desmontar y desconectar loop device"
	@echo "  clean         - Limpiar todo (incluye eliminar archivos)"
	@echo "  info          - Mostrar información del setup actual"
	@echo "  help          - Mostrar esta ayuda"
	@echo ""
	@echo "Variables configurables:"
	@echo "  DISK_IMAGE=$(DISK_IMAGE)    - Nombre del archivo de imagen"
	@echo "  DISK_SIZE=$(DISK_SIZE)       - Tamaño de la imagen"
	@echo "  MOUNT_POINT=$(MOUNT_POINT)   - Punto de montaje para EFI"
	@echo "  KERNEL_SOURCE=$(KERNEL_SOURCE) - Archivo fuente del kernel"
	@echo "  OVMF_CODE=$(OVMF_CODE) - Archivo OVMF CODE"
	@echo "  OVMF_VARS=$(OVMF_VARS) - Archivo OVMF VARS"
	@echo ""
	@echo "Ejemplos de uso:"
	@echo "  make                    # Ejecutar todo el proceso"
	@echo "  make compile            # Solo compilar y copiar kernel"
	@echo "  make execute            # Ejecutar kernel en QEMU"
	@echo "  make remount            # Solo remontar la partición EFI"
	@echo "  make clean              # Limpiar todo"
	@echo "  make info               # Ver estado actual"
	@echo ""
	@echo "Flujo típico:"
	@echo "  make all                # Setup inicial"
	@echo "  make compile            # Compilar kernel"
	@echo "  make execute            # Ejecutar en QEMU"