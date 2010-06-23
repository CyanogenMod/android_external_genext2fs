# $(1): src directory
# $(2): output file
# $(3): label (if any)
# $(4): if true, add journal
# $(5): num_block
# $(6): block_size
define build-userimage-ext2-target
	@mkdir -p $(dir $(2))
	$(hide) if [ $(6) -gt 1023 ]; then block_size=$(6); else block_size=1024; fi; \
	num_blocks=`du -sk $(1) | tail -n1 | awk '{print $$1;}'`;\
	if [ $$num_blocks -lt 20480 ]; then extra_blocks=12288; \
	else extra_blocks=20480; fi ; \
	num_blocks=`expr \( $$num_blocks + $$extra_blocks \) \* 1024 / $$block_size` ; \
	num_inodes=`find $(1) | wc -l` ; num_inodes=`expr $$num_inodes + 500`; \
	if [ $(5) ]; then num_blocks=$(5); fi; \
	echo "Generating "$(2)" - block_size="$$block_size", num_blocks="$$num_blocks;\
	$(MKEXT2IMG) -a -t -d $(1) -b $$num_blocks -s $$block_size -N $$num_inodes -m 0 $(2)
	$(if $(strip $(3)),\
		$(hide) $(TUNE2FS) -L $(strip $(3)) $(2))
	$(if $(strip $(4)),\
		$(hide) $(TUNE2FS) -j $(2))
	$(TUNE2FS) -C 1 $(2)
	$(E2FSCK) -fy $(2) ; [ $$? -lt 4 ]
endef
