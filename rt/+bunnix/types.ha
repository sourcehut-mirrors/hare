export def STDIN_FILENO: int = 0;
export def STDOUT_FILENO: int = 1;
export def STDERR_FILENO: int = 2;

export type iovec = struct {
	iov_base: *opaque,
	iov_len: size
};
