## Using Mise in your Dev Container

After installing Mise, you can manage language versions by adding a `.mise.toml` file to your project root:

```toml
[tools]
node = "20"
python = "3.11"
```

Or use the CLI to install tools:

```bash
mise install node@20
mise install python@3.11
```

For more information on using Mise, see the [official documentation](https://mise.jdx.dev/).

## OS Support

This Feature should work on recent versions of Debian/Ubuntu, RedHat Enterprise Linux, Fedora, and Alpine Linux distributions with the `apt`, `yum` or `dnf` package manager installed.

`bash` is required to execute the `install.sh` script.