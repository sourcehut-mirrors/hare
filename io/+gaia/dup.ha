use rt::sys;
use rt;

// Duplicates a file descriptor.
export fn dup(old: file) (file | error) = {
	return sys::process_ref(rt::self, old): file;
};

// Duplicates a file descriptor and stores the new file at a specific file
// descriptor number. If the file indicated by "new" already refers to an open
// file, this file will be closed before the file descriptor is reused.
export fn dup2(old: file, new: file) (file | error) = {
	// Note: this works fine even if there is not already a file here
	sys::process_unref(rt::self, new);
	return sys::process_refat(rt::self, old, new: uint): file;
};
