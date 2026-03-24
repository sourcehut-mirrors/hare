hare-version(1)

# NAME

hare version - print information about the Hare toolchain and environment

# SYNOPSIS

*hare version* [-hv]

# DESCRIPTION

If no flags are provided, *hare version* prints version information for the
*hare* program. With *-h*, it prints help text.

If *-v* is supplied, additional information (such as build parameters) is also
printed. Note that the format of this output is not considered stable, and
shouldn't be relied upon in scripts.

If *-vv* is supplied, detailed information about the version and build
parameters is printed as shell environment variables, in a format which is
consistent between versions and suitable for machine reading.

# SEE ALSO

*hare*(1)
