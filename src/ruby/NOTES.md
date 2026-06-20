

## OS Support

This Feature supports Linux images that ship one of the following package managers: `apt`, `dnf`/`yum`, `apk`, `zypper`, or `pacman`. The script detects the available package manager and installs the build dependencies that ruby-build needs.

`bash` is required to execute the `install.sh` script.

## Layout

- Ruby is installed under `/usr/local/rubies/<version>` by ruby-build.
- The default Ruby is exposed via the `/usr/local/rubies/current` symlink, which is placed on the `PATH` through `containerEnv`.
- `ruby-build` itself is cloned to `/usr/local/share/ruby-build` and symlinked into `/usr/local/bin/ruby-build` so additional versions can be installed later.
- A shared `ruby` group owns `/usr/local/rubies`; the configured non-root user is added to it so `gem install` can write into the active Ruby tree without `sudo`.
