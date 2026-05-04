
BUILD_DIR=build
KERNEL_DIR=src/kernel
ASMFLAGS =-f bin -I src/boot -I src/kernel
SIZE_FILE =$(BUILD_DIR)/.sizes.mk
BOOT_DIR=src/boot
KERNEL_SRCS =$(wildcard $(KERNEL_DIR)/*.asm)
KERNEL_BINS =$(patsubst $(KERNEL_DIR)/%.asm, $(BUILD_DIR)/%.bin, $(KERNEL_SRCS))

.PHONY: all
all:  $(KERNEL_BINS) $(BUILD_DIR)/boot.bin $(BUILD_DIR)/loader.bin $(SIZE_FILE)


$(BUILD_DIR):
	mkdir -p $@


$(SIZE_FILE): $(wildcard src/kernel/*.asm) src/boot/loader.asm | $(BUILD_DIR)
	@echo "计算各模块的大小..."
	@rm -f $@
	@for asm in $^; do \
		bin=$(BUILD_DIR)/$$(basename $$asm .asm).tmp.bin;\
		nasm $(ASMFLAGS) $$asm -o $$bin; \
		size=$$(wc -c <$$bin);\
		name=$$(basename $$asm .asm | tr a-z A-Z)_SIZE;\
		echo "$$name =$$size" >>$@;\
		rm -f $$bin;\
	done

$(BUILD_DIR)/%.bin: $(KERNEL_DIR)/%.asm | $(BUILD_DIR)
	nasm $(ASMFLAGS) $< -o $@


$(BUILD_DIR)/boot.bin: $(BOOT_DIR)/boot.asm | $(BUILD_DIR)
	nasm $(ASMFLAGS) $< -o $@


$(BUILD_DIR)/loader.bin: $(BOOT_DIR)/loader.asm | $(BUILD_DIR)
	nasm $(ASMFLAGS) $< -o $@
