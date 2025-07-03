## Using Conda and Mamba

This Feature includes [the `conda` package manager](https://docs.conda.io/projects/conda/en/latest/index.html) and optionally [the `mamba` package manager](https://mamba.readthedocs.io/en/latest/), which provides faster dependency resolution and package installation. Additional packages will be downloaded from Anaconda, conda-forge, or another repository if you configure one.

### Configuration Options

This Feature offers several configuration options:

- **useCondaForge**: Set to `true` (default) to use conda-forge as the default channel, which offers better package compatibility and more permissive licensing.
- **installMamba**: Set to `true` (default) to install Mamba alongside Conda for faster package management.
- **useSystemPackages**: Set to `true` (default) to use the system package manager on Debian/Ubuntu systems to install Conda.
- **installFullAnaconda**: Set to `true` to install the full Anaconda distribution instead of the minimal Miniconda. Defaults to `false`.

### Using Mamba

When Mamba is installed, you can use the following commands and aliases for faster package management:

```bash
# Use mamba directly
mamba install package-name

# Use aliases that are automatically set up
conda-fast install package-name
cf install package-name
```

Mamba uses the same command syntax as conda but resolves dependencies much faster, especially for complex environments.

### Conda Channels

To reconfigure Conda in this container to access alternative repositories, please see information on [configuring Conda channels here](https://docs.conda.io/projects/conda/en/latest/user-guide/concepts/channels.html).

## Licensing Information

Access to the Anaconda repository is covered by the [Anaconda Terms of Service](https://legal.anaconda.com/policies/en/?name=terms-of-service), which may require some organizations to obtain a commercial license from Anaconda. **However**, when used with GitHub Codespaces or GitHub Actions, **all users are permitted** to use the Anaconda Repository through the service, including organizations normally required by Anaconda to obtain a paid license for commercial activities. 

If you've enabled the `useCondaForge` option (default), your container will use conda-forge as the default channel, which has more permissive licensing than the default Anaconda repository.

Note that third-party packages may be licensed by their publishers in ways that impact your intellectual property, and are used at your own risk.

## Installing a different version of Python

As covered in the [user FAQ](https://docs.anaconda.com/anaconda/user-guide/faq) for Anaconda, you can install different versions of Python than the one in this image by running the following from a terminal:

```bash
conda install python=3.7
# Or faster with mamba
mamba install python=3.7
```

## OS Support

This Feature should work on recent versions of Debian/Ubuntu-based distributions with the `apt` package manager installed. It also has limited support for RedHat-based systems, Alpine Linux, and openSUSE/SLES.

`bash` is required to execute the `install.sh` script.
