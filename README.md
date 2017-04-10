# Build system common (core) stuff

## About

This project holds common buildystem stuff, mainly debian packaging support. It is intended to be plugged into other projects via git submodule machinery.

## Usage

## Basic layout of project that uses `buildsys-*` machinery

Your project is expected to have following directory structure. Component is anything you want to build. There can be one or more components. It is recommended that one component has name similar to project name, e.g. project `vts-tools` can have component named `tools`.
 
```
externals/                                   # all submodules of this project
externals/buildsys/                          # build system parts (submodules)
externals/buildsys/common                    # this project as a submodule
component/                                   # root directory of a component named "component"
component/buildsys -> ../externals/buildsys  # symlink to build system
component/Makefile -> buildsys/X/X.mk        # main makefile, symlink to module's desired buildsystem
component/src/                               # all sources belong here
component/debian/                            # native debian packaging (optional)
```

### Setup submodule

Inside your project root add `buildsys-common` repository (this) as a submodule into `externals/buildsystem/common`.

```
git submodule add ../buildsys-common externals/buildsys/common
```

### Link `buildsys` to your project component

Move to your `component` root under the project root and create a `buildsys` symlink:

```
cd component
ln -s ../externals/buildsys
```

### Use `buildsys-common` as a main build system (optional)

If a component uses `buildsys-common` as desired build system symlink provided `common.mk` file into component:

```
cd component
ln -s buildsys/common/common.mk Makefile
```

## Debian packaging support

This core build system part adds support for debian packaging. Component can provide either proper `debian/` directory or any number of directories in any of these formats: `debian.CUSTOMER`, `debian.RELEASE` and `debian.CUSTOMER.RELEASE` where
 * CUSTOMER is a name of custom build specified by DEB_CUSTOMER make variable (defaults to `internal`)
 * RELEASE is a name of Debian release determined by `Codename` obtained from `lsb_release -c` command output.
 
NB: Multiple `debian.*` directories are supported by creating `debian` symlink pointing to proper `debian.*` directory at all debian-related targets. Therefore `DEB_CUSTOMER` variable set to the same value must be used during subsequent calls to `make dch`, `make deb` and `make dput`, e.g. `make dch DEB_CUSTOMER=abc`.
 
## Supported make targets

### make deb

Makes a debian package. Runs `dpkg-buildpackage`.

### make debclean

Cleans after debian packaging.

### make dput

Pushes latest package to remote package tree. Default configuration is set to suit Melown Technologies needs but one can change path to `dput.cf` and distribution to use via make or environment variables `DPUT_CONFIG` and `DPUT_DISTRIBUTION`. It is recommended to export these variable in user's profile (e.g. `~/.bashrc`).

### make dversion

Shows latest debian package version (head of appripriate `debian*/changelog` file).

### make dch

Runs `debchange` to edit appropriate `debian*/changelog` file.

### make debsign

Runs `debsign` to (re)sign package.
