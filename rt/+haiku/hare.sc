SECTIONS {
	.hare_init_array : {
		PROVIDE(__hare_init_array_start	= .);
		KEEP(*(.hare_init_array*))
		PROVIDE(__hare_init_array_end	= .);
	}
} INSERT AFTER .bss; /* .bss was choosen arbitrarily. */
