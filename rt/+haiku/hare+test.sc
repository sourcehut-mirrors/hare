SECTIONS {
	.data.hare_init_array : {
		PROVIDE(__hare_init_array_start	= .);
		KEEP(*(.data.hare_init_array))
		PROVIDE(__hare_init_array_end	= .);
	}
	.data.hare_fini_array : {
		PROVIDE(__hare_fini_array_start	= .);
		KEEP(*(.data.hare_fini_array))
		PROVIDE(__hare_fini_array_end	= .);
	}
	.test_array : {
		PROVIDE(__test_array_start	= .);
		KEEP(*(.test_array*))
		PROVIDE(__test_array_end	= .);
	}
} INSERT BEFORE .data;
