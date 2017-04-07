# Build system common (core) stuff

## About

This project holds common buildystem stuff, mainly debian packaging support. It is intended to be plugged into other
projects via git submodule machinery.

## Usage

## Basic layout of project that uses `buildsys-*`

Your project is expected to have following directory structure:

```
externals/                                # all submodules this project
externals/buildsys/                       # build system parts
module/                                   # root directory of a module
module/buildsys -> ../externals/buildsys  # symlink to build system
module/Makefile -> buildsys/X/X.mk        # main makefile, symlink to module's desired buildsystem
module/src/                               # all sources belong here
module/debian/                            # native debian packaging
```

### Setup submodule

Inside project root add `buildsys-common` repository (this) as a submodule into `externals/buildsystem/common`.

```
git submodule add ../buildsys-common externals/buildsys/common
```

### Link `buildsys` to your project module

Move to your `module` under project root and `buildsys` symlink:

```
cd module
ln -s ../externals/buildsys
```

### Use as a main build system (optional)

If a module uses `buildsys-common` as desired build system symlink provided `common.mk` file into module:

```
ln -s buildsys/common/common.mk Makefile
```

## Debian packaging support

This core build system component adds support for debian packaging. Module can provide either proper `debian/`
directory or any number of directories in any of these formats: `debian.CUSTOMER`, `debian.RELEASE`
and `debian.CUSTOMER.RELEASE` where
 * CUSTOMER is name of custom build specified by DEB_CUSTOMER make variable (defaults to `internal`)
 * RELEASE is name of Debian release determined by `Codename` obtained from `lsb_release -c` command output.
 
## Supported make targets

### deb

Makes a debian package. Runs `dpkg-buildpackage`.

### debclean

Cleans after debian packaging.

### dput

Pushes latest package to remote package tree.

### dversion

Show latest debian package version.

### dch

Runs `debchange` with proper options.

### debsign

Runs `debsign`.
