use errors;
use rt;
use strings;

// Reads the contents of a symbolic link relative to a directory file
// descriptor. The return value is statically allocated and will be overwritten
// on the next call to [[readlink]] or [[readlinkat]].
export fn readlinkat(dirfd: int, path: str) (str | errors::error) = {
	static let buf: [rt::PATH_MAX]u8 = [0...];
	let z = match (rt::readlinkat(dirfd, path, buf[..])) {
	case let err: rt::errno =>
		switch (err) {
		case rt::EINVAL =>
			return errors::wrongtype;
		case =>
			return errors::errno(err);
		};
	case let z: size =>
		yield z;
	};
	return strings::fromutf8(buf[..z])!;
};

// Reads the contents of a symbolic link. The return value is statically
// allocated and will be overwritten on the next call to [[readlink]] or
// [[readlinkat]].
export fn readlink(path: str) (str | errors::error) = {
	return readlinkat(AT_FDCWD, path);
};
