use arch;

// Returns the bulk data included in an IPC request.
export fn recv_bulk(serv: *server) []u8 = {
	const ipcbuf = ipcbuf as *[PAGESIZE]u8;
	const amt = (serv.call_flags & call_flag::BUFSIZE_MASK): size;
	return ipcbuf[..amt];
};

// Note: if updating [[sys::server]], the constant in artemis-genproto's
// generated assembly needs to be updated as well.

// Supertype for all IPC servers.
export type server = struct {
	// Flags provided by callers during recv operations.
	call_flags: call_flag,
	// Flags to use for replies.
	reply_flags: reply_flag,
	// Badge, if applicable
	badge: u32,
	// Jump buffer for internal use.
	jmp: arch::jmp_buf,
};

export type call_params = struct {
	ep: caddr,
	flags: call_flag,
	reply_flags: reply_flag,
};

// Replies to the latest call to this task, using the reply capability in the
// task's reply slot. The caller must ensure that the variadic parameters fit
// into the maximum number of reply registers for the target ABI.
export fn reply(serv: *server, ...) (u64, u64);

// Replies to a stored reply capability.
export fn reply_to(serv: *server, addr: caddr, ...) (u64, u64);

// Returns from [[recv]] without replying to the caller.
export fn skip_reply(serv: *server) never = {
	arch::longjmp(&serv.jmp, 1);
};

// Receives a capability from the caller.
export fn recv_cap(
	dest: caddr,
	flags: recv_cap_flag,
	reply: caddr = ~0,
) (void | errno) = {
	// TODO: should this sanity check server.call_flags for the user?
	check_void(sys_recv_cap(dest, flags, reply))?;
};
