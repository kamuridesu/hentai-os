.PHONY: test test_normal test_panic test_double_fault test_page_fault test_run

test: test_normal test_panic test_double_fault test_page_fault
	@echo "=== ALL TESTS PASSED ==="

test_normal:
	@$(MAKE) EXTRA_FLAGS='-define:TEST_NORMAL=true' build link test_run

test_panic:
	@$(MAKE) EXTRA_FLAGS='-define:TEST_PANIC=true' build link test_run

test_double_fault:
	@$(MAKE) EXTRA_FLAGS='-define:TEST_DOUBLE_FAULT=true' build link test_run

test_page_fault:
	@$(MAKE) EXTRA_FLAGS='-define:TEST_PAGE_FAULT=true' build link test_run

test_run:
	$(QEMU) -kernel $(KERNEL_ELF) $(QEMU_FLAGS) || [ $$? -eq 33 ]
