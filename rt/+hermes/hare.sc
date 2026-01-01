PHDRS {
	text PT_LOAD;
	data PT_LOAD;
	tls PT_NULL;
	manifest PT_NULL;
}
ENTRY(_start);
SECTIONS {
	. = 0x8000000;

	.text : {
		KEEP (*(.text))
		*(.text.*)
	} :text

	. = ALIGN(4K);

	.data.hare_init_array : {
		PROVIDE_HIDDEN (__hare_init_array_start = .);
		KEEP (*(.data.hare_init_array))
		PROVIDE_HIDDEN (__hare_init_array_end = .);
	} :data

	.data.hare_fini_array : {
		PROVIDE_HIDDEN (__hare_fini_array_start = .);
		KEEP (*(.data.hare_fini_array))
		PROVIDE_HIDDEN (__hare_fini_array_end = .);
	} :data

	.data.hare_test_array : {
		PROVIDE_HIDDEN (__hare_test_array_start = .);
		KEEP (*(.data.hare_test_array))
		PROVIDE_HIDDEN (__hare_test_array_end = .);
	} :data

	.data : {
		KEEP (*(.data))
		*(.data.*)
	} :data

        . = ALIGN(4K);

	.bss : {
		KEEP (*(.bss))
		*(.bss.*)
	} :data

        . = ALIGN(4K);

	.tdata : {
		KEEP (*(.tdata))
		*(.tdata)
	} :tls

	.tbss : {
		KEEP (*(.tbss))
		*(.tbss)
	} :tls

	.manifest : {
		KEEP (*(.manifest))
		*(.manifest)
	} :manifest
}
