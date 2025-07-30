

## OS Support

This Feature should work on recent versions of Debian/Ubuntu, RedHat Enterprise Linux, Fedora, Alma, RockyLinux 
and Mariner distributions with the `apt`, `yum`, `dnf`, `microdnf` and `tdnf` package manager installed.


**Note:** Alpine is not supported because the rustup-init binary requires glibc to run, but Alpine Linux does not include `glibc` 
by default. Instead, it uses musl libc, which is not binary-compatible with glibc.

`bash` is required to execute the `install.sh` script.
