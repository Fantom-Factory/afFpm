#Fantom Pod Manager v0.0.4
---
[![Written in: Fantom](http://img.shields.io/badge/written%20in-Fantom-lightgray.svg)](http://fantom.org/)
[![pod: v0.0.4](http://img.shields.io/badge/pod-v0.0.4-yellow.svg)](http://www.fantomfactory.org/pods/afFpm)
![Licence: MIT](http://img.shields.io/badge/licence-MIT-blue.svg)

## Overview

*Fantom Pod Manager is a support library that aids Alien-Factory in the development of other libraries, frameworks and applications. Though you are welcome to use it, you may find features are missing and the documentation incomplete.*

Fantom Pod Manager (FPM) provides a targeted environment for compiling, testing, and running Fantom applications.

It is one of those boring system libraries you quickly find you can't do without!

A typical Fantom installation only allows one version of any given pod. This works fine if you're just developing and running the one application. But if you're developing multiple applications, each requiring different versions of the same pod; then you either need multiple Fantom environments, one for each application, ... or you need FPM.

FPM maintains a local [fanr file repository](http://fantom.org/doc/docFanr/FileRepos.html) of Fantom pods, where it keeps multiple versions of the same pod. When a Fantom application is built, test, or run via FPM; then from that repository, FPM cherry picks just the pod versions you need.

## Install

Install `Fantom Pod Manager` with the Fantom Repository Manager ( [fanr](http://fantom.org/doc/docFanr/Tool.html#install) ):

    C:\> fanr install -r http://pods.fantomfactory.org/fanr/ afFpm

To use in a [Fantom](http://fantom.org/) project, add a dependency to `build.fan`:

    depends = ["sys 1.0", ..., "afFpm 0.0"]

## Documentation

Full API & fandocs are available on the [Fantom Pod Repository](http://pods.fantomfactory.org/pods/afFpm/).

## Quick Start

Install FPM via `fanr`, then run the setup command:

```
C:\> fan afFpm setup

Fantom Pod Manager 0.0.2
========================

Setting up FPM...
  Creating: C:\Apps\fantom-1.0.68\bin\fpm.bat

  Creating: C:\Apps\fantom-1.0.68\etc\afFpm\fpm.props

  Publishing pods from C:\Apps\fantom-1.0.68\lib\fan into repo 'default'...
    Publishing afBedSheet 1.5.0 to default
    Publishing afBeanUtils 1.0.8 to default
    Publishing afIoc 3.0.0 to default
    ...

Current Configuration
      Home Dir : C:\Apps\fantom-1.0.68
     Work Dirs : C:\Apps\fantom-1.0.68
      Pod Dirs : (none)
      Temp Dir : C:\Apps\fantom-1.0.68\temp
  Config Files : C:\Apps\fantom-1.0.68\etc\afFpm\fpm.props

    File Repos :
       default = C:\Apps\fantom-1.0.68\fpmRepo-default

    Fanr Repos :
 fantomFactory = http://pods.fantomfactory.org/fanr/
     status302 = http://repo.status302.com/fanr/
        fantom = http://fantom.org/fanr/

FPM setup complete.

Have fun! :)
```

The `setup` command creates an `fpm.bat` file, an `fpm.props` file, and publishes any non-core pods to a local repository.

You can now use `fpm` from the command line to download, install, and run Fantom apps:

To install a library:

    C:\> fpm install afIoc

To run an app:

    C:\> fpm run myApp

To update dependencies for an app:

    C:\> fpm update myApp

## FPM Environment

To build, test, or run a fantom application (or script), FPM needs to know which pod it should provide dependencies for. This is known as the *target pod*.

It is possible to use environment variables to set this up, but it is far easier to just launch your application using `fpm` itself. See `build`, `test`, and `run` commands for details.

## FPM Commands

From the command line, type `fpm` on it's own to see the current FPM environment:

```
C:\> fpm

Fantom Pod Manager
==================

FPM Environment:
      Home Dir : C:\Apps\fantom-1.0.68
     Work Dirs : C:\Repositories\Fantom
                 C:\Apps\fantom-1.0.68
      Pod Dirs : (none)
              ...
              ...
              ...
```

Otherwise follow `fpm` with one of the following commands:

### setup

Sets up FPM in the current Fantom environment.

    C:\> fan afFpm setup

`setup` performs the following operations:

1. Creates `fpm.bat` in the `bin/` directory of the current Fantom installation. Or creates an `fpm` executable script on nix systems.
2. Creates a default `fpm.props` config file in the `etc/afFpm/` directory.
3. Publishes all non-core pods found in any Fantom work or home directory. Note, this oprertation is non-destructive; pod files are left intact and are just *copied* to the local default repository.

### build

Builds a Fantom application.

Runs build tasks from `build.fan` within an FPM environment.

The targeted environment is derived from the `depends` pod list defined in `build.fan`.

`build.fan` should be in the current directory.

If (and only if) a repository is specified, then any pod built is installed into it.

Examples:

    C:\> fpm build
    C:\> fpm build -repo default compile

### test

Tests a Fantom application.

Executes tests via `fant` within an FPM environment.

If the `target` option is not specified, then the targeted environment is derived from the containing pod of the first test.

Examples:

    C:\> fpm test myPod
    C:\> fpm test -js -target myPod myPod::TestClass

### run

Runs a Fantom application.

Executes a pod / method, within an FPM environment.

If the `target` option is not specified, then the targeted environment is derived from the containing pod.

Examples:

    C:\> fpm run myPod
    C:\> fpm run -js -target myPod myPod::MyClass

### install

Installs a pod to a repository.

The repository may be:

- a named local repository (e.g. `default`)
- a named remote repository (e.g. `fantomFactory`)
- the directory of a local repository (e.g. `C:\repo-release\`)
- the URL of a remote repository (e.g. `http://pods.fantomfactory.org/fanr/`)

The pod may be:

- a file location, absolute or relative. Example, `lib/myAweseomeGame.pod`
- a simple search query. Example, `"afIoc 3.0"` or `afIoc@3.0`

All the above makes the `install` command very versatile. Some examples:

To download and install the latest pod from a remote repository:

    C:\> fpm install myPod

To download and install a specific pod version to a local repository:

    C:\> fpm install -r release myPod 2.0.10

To upload and publish a pod to the Fantom-Factory repository:

    C:\> fpm install -r fantomFactory lib/myGame.pod

### uninstall

Un-installs a pod from a local repository.

The repository may be:

- a named local repository (e.g. `default`)
- the directory of a local repository (e.g. `C:\repo-release\`)

Examples:

    C:\> fpm uninstall myPod
    C:\> fpm uninstall -r default myPod 2.0.10

### update

Updates and installs dependencies for a named pod / build file.

Queries remote repositories looking for newer pod versions that match the targeted FPM environment.

Examples:

    C:\> fpm update
    C:\> fpm update -r default build.fan
    C:\> fpm update -r release myPod 2.0.10

### help

Prints help on a given command.

## FPM Config

FPM gathers its config from a series of `fpm.props` files. These files are looked for in the following locations:

- `./fpm.props`
- `<WORK_DIR>/etc/afFpm/fpm.props`
- `<FAN_HOME>/etc/afFpm/fpm.props`

Note that the config files are additive but the values are not. If all 3 files exist, then all 3 files are merged together, with config values from a more specific file *replacing* (or overriding) values found in less specific one.

`<WORK_DIR>` may be specified with the `FPM_ENV_PATH` environment variable.

## Javascipt Environments

FPM lets you easily run Fantom applications and tests in a Javascript environment; which for quick tests, may be easier that sparking up a web server and browser. Use the `-js` option available in the `run` and `test` commands:

    C:\> fpm run -js myPod
    
    C:\> fpm test -js myPod

## Behind the Scenes

To build, test, or run a Fantom application, FPM needs to know which pod it should resolve dependencies for. This is known as the *target pod*.

In most common cases FPM is able to infer the target pod from what is being run, usually from inspecting [Env.mainMethod()](http://fantom.org/doc/sys/Env.html#mainMethod). In other cases you can set the `FPM_TARGET` environment variable, along with `FAN_ENV`:

    C:\> set FAN_ENV=afFpm::FpmEnv
    
    C:\> set FPM_TARGET=myPod
    
    C:\> fan myPod

FPM will always use the `FPM_TARGET` environment variable if it is set.

If FPM fails to resolve a target pod then it falls back to providing the latest versions of all pods.

## Debugging

Providing a targeted environment is a tricky business and sometimes doesn't herald the results you expect - especially if you have a couple of `fpm.props` files and / or multiple local repositories. To combat this, you can turn FPM debugging for any command by using the `debug` or `-d` option:

    C:\> fpm build -debug

Then when invoked, FPM dumps a full trace of the resolved environment. The resolved pods section is great for seeing where pod versions are loaded from.

```
C:\Projects>fpm run flux

Fantom Pod Manager 0.0.2
========================

Running flux
[debug] [afFpm] Fantom Pod Manager 0.0.2
[debug] [afFpm] ========================
[debug] [afFpm] Resolving pods for flux 0+
[debug] [afFpm] Found 16 versions of 6 different pods
[debug] [afFpm] Calculated  10 dependency pod permutation
[debug] [afFpm] Collapsed to 1 dependency group permutation
[debug] [afFpm] Stated problem space in 126ms
[debug] [afFpm] Solving...
[debug] [afFpm]           ...Done
[debug] [afFpm] Cached 0 bad dependency groups
[debug] [afFpm] Found 1 solution in 9ms
[debug] [afFpm]

FPM Environment:

   Target Pod : flux 0+
      Home Dir : C:\Apps\fantom-1.0.68
     Work Dirs : C:\Repositories\Fantom
                 C:\Apps\fantom-1.0.68
      Pod Dirs : (none)
      Temp Dir : C:\Repositories\Fantom\temp
  Config Files : C:\Repositories\Fantom\etc\afFpm\fpm.props

    File Repos :
       default = C:\Repositories\Fantom\repo-default
       release = C:\Repositories\Fantom\repo-release

    Fanr Repos :
 fantomFactory = http://pods.fantomfactory.org/fanr/
     status302 = http://repo.status302.com/fanr/
        fantom = http://fantom.org/fanr/

Resolved 6 pods:
    compiler 1.0.67 - C:\Apps\fantom-1.0.68\lib\fan\compiler.pod
  concurrent 1.0.68 - C:\Apps\fantom-1.0.68\lib\fan\concurrent.pod
        flux 1.0.67 - C:\Apps\fantom-1.0.68\lib\fan\flux.pod
         fwt 1.0.68 - C:\Apps\fantom-1.0.68\lib\fan\fwt.pod
         gfx 1.0.68 - C:\Apps\fantom-1.0.68\lib\fan\gfx.pod
         sys 1.0.68 - C:\Apps\fantom-1.0.68\lib\fan\sys.pod
```

Debug may also be turned on all the time by adding this line to `%FAN_HOME%/etc/sys/log.props`:

    afFpm=debug

