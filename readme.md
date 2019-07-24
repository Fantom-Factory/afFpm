# FPM (Fantom Pod Manager) v2.0.2
---

[![Written in: Fantom](http://img.shields.io/badge/written%20in-Fantom-lightgray.svg)](http://fantom-lang.org/)
[![pod: v2.0.2](http://img.shields.io/badge/pod-v2.0.2-yellow.svg)](http://eggbox.fantomfactory.org/pods/afFpm)
[![Licence: ISC](http://img.shields.io/badge/licence-ISC-blue.svg)](https://choosealicense.com/licenses/isc/)

## Overview

Fantom Pod Manager (FPM) provides a targeted environment for building, testing, and running Fantom applications.

It provides tools to:

- query repositories for pods
- install / delete pods to / from repositories
- update dependencies for pods and Fantom projects

It is one of those boring system libraries you can't do without!

A typical Fantom installation only allows one version of any given pod. This works fine when developing or running just one application. But when developing multiple projects, each requiring different versions of the same pod; then you either need multiple Fantom environments (one for each application) ... or you need FPM.

FPM maintains a local [fanr file repository](http://fantom.org/doc/docFanr/FileRepos.html) of Fantom pods, where it can keep multiple versions of the same pod. When a Fantom application is built, test, or run via FPM; then from that repository, FPM cherry picks just the pod versions you need.

## Install

Install `FPM (Fantom Pod Manager)` with the Fantom Pod Manager ( [FPM](http://eggbox.fantomfactory.org/pods/afFpm) ):

    C:\> fpm install afFpm

Or install `FPM (Fantom Pod Manager)` with [fanr](http://fantom.org/doc/docFanr/Tool.html#install):

    C:\> fanr install -r http://eggbox.fantomfactory.org/fanr/ afFpm

To use in a [Fantom](http://fantom-lang.org/) project, add a dependency to `build.fan`:

    depends = ["sys 1.0", ..., "afFpm 2.0"]

## Documentation

Full API & fandocs are available on the [Eggbox](http://eggbox.fantomfactory.org/pods/afFpm/) - the Fantom Pod Repository.

## Quick Start

Install FPM via `fanr`, then run the setup command:

```
C:\> fan afFpm setup
```

The `setup` command creates an `fpm.bat` file and a default `fpm.props` file. You can now use `fpm` from the command line to download, install, and run Fantom apps:

To install a library and all its dependencies:

    C:\> fpm install afIoc

To run an application:

    C:\> fpm run myApp

To update dependencies:

    C:\> fpm update myApp

The `update` command in particular is very helpful. If no pod or app is given, it looks for a `build.fan` in the current directory and parses it for dependencies.

If you've just cloned a code repository from BitBucket or GitHub, then a quick `fpm update` from the project directory is all you need to download all the required dependencies!

## FPM How To...

These assume you have a remote fanr repository configured in `fpm.props`. Note that [Eggbox](http://eggbox.fantomfactory.org/) is configured by default.

Note that in any command below, `update` may be used as an alias for `install`.

### ...download a new library

Use the `install` command:

    C:\> fpm install podName

If the pod doesn't exist locally, it will be downloaded along with any (transient) dependencies it needs.

### ...update a library

Use the `install` command:

    C:\> fpm install podName

If a newer version exists online, it will be downloaded along with any (transient) dependencies it needs.

### ...update dependencies for a library

Use the `install` command with a specific version:

    C:\> fpm install podName@2.0.0

If newer dependencies exists online, they will be downloaded.

### ...update dependencies for a project

Use the `install` command, on its own or specify a build file:

    C:\> fpm install
    C:\> fpm install build.fan

The build file will be parsed for project dependencies, which are queried and downloaded should newer versions exist online.

### ...copy dependencies in to a directory

Use the `install` command, specifying the directory as the target repository:

    C:\> fpm install podName -r /lib/fan/

`podName.pod` and all its dependencies will be copied into the target directory.

### ...install a directory of library files

Use the `install` command, specifying the directory the source:

    C:\> fpm install /lib/fan/

All the pods found in `/lib/fan/` will be installed for future use.

This is handy for absorbing a new installation of SkySpark to develop against.

## FPM Environment

FPM needs to know where it can find different pod versions. This is the *FPM Environment* and is highly configurable to suit many needs.

Pods may be found in:

- **Directory Repositories** - arbitrary directories that contain pods. Work directories and the Fantom Home directories are added to this list.

  By default the relative paths `lib/` and `lib/fan/` are used, which are relative to the current working directory.


- **Fanr Repositories** - named local or remote fanr repositories.

To see how the FPM environment is configured on your system, type `fpm` on it's own:

```
C:\> fpm

Fantom Pod Manager
==================

FPM Environment:
      Home Dir : C:\Apps\fantom-1.0.70
     Work Dirs : C:\Repositories\Fantom
                 C:\Apps\fantom-1.0.70
      Pod Dirs : (none)
              ...
              ...
              ...
```

## FPM Config

FPM gathers config for its environment from a series of `fpm.props` files. These files are looked for in the following locations:

- `<FAN_HOME>/etc/afFpm/fpm.props`
- `<WORK_DIR>/etc/afFpm/fpm.props`
- `<currentDir>/fpm.props`

Note that the config files are additive but the values are not. If all 3 files exist, then all 3 files are merged together, with config values from a more specific file *replacing* (or overriding) values found in less specific one.

`<WORK_DIR>` may be specified with the `FPM_ENV_PATH` environment variable. This means that **ALL** the config for FPM may live *outside* of the Fantom installation. The only FPM file that needs to live in the Fantom installation is the `afFpm.pod` file itself.

Have a read of your `fpm.props` file, it contains lots of useful comments and instructions!

**Note:** To get the most out of FPM, you should edit `fpm.props` and add a local fanr repository for `default`:

    fanrRepo.default  = ${fanHome}repo-default

## FPM Commands

To build, test, or run a fantom application (or script), FPM needs to know which pod or application it should provide dependencies for. This is known as the *target pod*.

It is possible to use environment variables to set this up (See [Behind the scenes](#behindTheScenes)), but it is far easier to launch your application using `fpm` itself. See `build`, `test`, and `run` commands for details. Note these commands spawn extra processes that launch your Fantom build / program / test.

So there are two types of commands:

- those that execute Fantom code: `build`, `test`, `run`
- those that manage repositories: `query`, `install`, `delete`

### setup

Sets up FPM in the current Fantom environment.

    C:\> fan afFpm setup

Setup performs the following operations:

1. Creates `fpm.bat` in the `bin/` directory of the current Fantom installation. Or creates an `fpm` executable script on nix systems.
2. Creates a default `fpm.props` config file in the Fantom `etc/afFpm/` directory.

After setup you should be able to run FPM from the command prompt with the `fpm` command.

Example:

    fpm setup
    fpm help setup

### build

Builds a Fantom application.

Runs build tasks from `build.fan` within an FPM environment.

The targeted environment is derived from the `depends` pod list defined in `build.fan`.

`build.fan` should be in the current directory.

If (and only if) a repository is specified, then any pod built is installed into it.

Examples:

    C:\> fpm build
    C:\> fpm build compileTask -r release

### test

Tests a Fantom application.

Executes tests via `fant` within an FPM environment.

The target environment is taken to be the containing pod of the executed test. It may be explicitly overridden using the `-target` option.

Examples:

    C:\> fpm test myPod
    C:\> fpm test -js -target myPod myPod::TestClass

### run

Runs a Fantom application.

Executes a pod / method, within an FPM environment.

The target environment is taken to be the containing pod of the executed method. It may be explicitly overridden using the `-target` option.

Examples:

    C:\> fpm run myPod
    C:\> fpm run -js -target myPod2 myPod::MyClass

### query

Queries repositories for pods.

The whole FPM environment is queried, including all local file and remote fanr repositories.

Examples:

    C:\> fpm query myPod
    C:\> fpm query myPod@2.0+
    C:\> fpm query "myPod 2.0+"

### install

Installs pods to a repository.

The pod may be:

- a file location       (e.g. `lib/myGame.pod` or `C:\lib\myGame.pod`)
- a simple search query (e.g. `afIoc@3.0` or `"afIoc 3.0"`)
- a directory of pods   (e.g. `lib/` or `C:\lib\`)
- a build file          (e.g. `build.fan` - use to update dependencies)

The repository may be:

- a named repository    (e.g. `eggbox`)
- a local directory     (e.g. `lib/` or `C:\lib\`)
- a remote fanr URL     (e.g. `http://eggbox.fantomfactory.org/fanr/`)

All the above makes the `install` command very versatile.

To download and install the latest pod from a remote repository:

    C:\> fpm install myPod

To download and install a specific pod version to a local repository:

    C:\> fpm install -r release "myPod 2.0.10"

To upload and publish a pod to the eggbox repository:

    C:\> fpm install -r eggbox lib/myPod.pod

### delete

Deletes a pod from a local repository. (Remote fanr repositories don't support pod deletion.)

The repository may be:

- a named local repository (e.g. `default`)
- the location of directory (e.g. `C:\lib-release\`)

Examples:

    C:\> fpm delete myPod
    C:\> fpm delete myPod@2.0.10 -r release

## Javascript Environments

FPM lets you run Fantom applications and tests in a Javascript environment; which for quick tests, is easier than sparking up a web server and browser! Use the `-js` option available in the `run` and `test` commands:

    C:\> fpm run -js myPod
    
    C:\> fpm test -js myPod

Note the Javascript environment requires NodeJS to be installed on your system.

## Behind the Scenes

For FPM to do its thing, Fantom programs need have `afFpm::FpmEnv` as their current environment. This can only be configured at boot time via the `FPM_ENV` environment variable.

    C:\> set FAN_ENV=afFpm::FpmEnv

To build, test, or run a Fantom application, FPM needs to know which pod it should resolve dependencies for. This is known as the *target pod*.

In most common cases FPM is able to infer the target pod from what is being run, usually from inspecting [Env.mainMethod()](http://fantom.org/doc/sys/Env.html#mainMethod). In other cases you can set the `FPM_TARGET` environment variable.

    C:\> set FPM_TARGET=myPod

FPM will always use the `FPM_TARGET` environment variable if it is set.

You can then run your Fantom program as normal.

    C:\> fan myPod

If FPM fails to resolve a target pod then it falls back to providing the latest versions of all pods.

Continually setting up environment variables can be tiresome. That is why FPM comes bundled with the helper commands `build`, `test`, and `run`. These commands don't need env vars to be set up, because they parse and inspect the command line, and spawn a new Fantom process with all the required env vars pre-set.

## Debugging

Providing a targeted environment is a tricky business and sometimes doesn't herald the results you expect - especially if you have a couple of `fpm.props` files and / or multiple local repositories. To combat this, you can turn on FPM debugging for any command by using the `debug` or `-d` option:

    C:\> fpm build -debug

Then when invoked, FPM dumps a full trace of the resolved environment. The resolved pods section is great for seeing where pod versions are loaded from.

```
C:\Projects>fpm run -d flux

FPM running flux
[debug] [afFpm]
[debug] [afFpm] Fantom Pod Manager (FPM) v0.2.0
[debug] [afFpm] -------------------------------
[debug] [afFpm]
[debug] [afFpm] Resolving pods for flux 0+
[debug] [afFpm] Found 6 versions of 6 different pods
[debug] [afFpm] Calculated   1 dependency pod permutation
[debug] [afFpm] Collapsed to 1 dependency group permutation
[debug] [afFpm] Stated problem space in 35ms
[debug] [afFpm] Solving...
[debug] [afFpm]           ...Done
[debug] [afFpm] Cached 0 bad dependency groups
[debug] [afFpm] Found 1 solution in 3ms
[debug] [afFpm]

FPM (0.2.0) Environment:

    Target Pod : flux 0+
      Base Dir : C:\
  Fan Home Dir : C:\Apps\fantom-1.0.70
     Work Dirs : C:\Repositories-Fantom\workDir
                 C:\Apps\fantom-1.0.70
      Temp Dir : C:\Repositories-Fantom\workDir\temp
  Config Files : C:\Repositories-Fantom\workDir\etc\afFpm\fpm.props

     Dir Repos :
       workDir = C:\Repositories-Fantom\workDir\lib\fan
       fanHome = C:\Apps\fantom-1.0.70\lib\fan

    Fanr Repos :
       default = file:/C:/Repositories-Fantom/repo-default/
        eggbox = http://eggbox.fantomfactory.org/fanr/

Resolved 6 pods:
    compiler 1.0.70 - C:\Apps\fantom-1.0.70\lib\fan\compiler.pod
  concurrent 1.0.70 - C:\Apps\fantom-1.0.70\lib\fan\concurrent.pod
        flux 1.0.70 - C:\Apps\fantom-1.0.70\lib\fan\flux.pod
         fwt 1.0.70 - C:\Apps\fantom-1.0.70\lib\fan\fwt.pod
         gfx 1.0.70 - C:\Apps\fantom-1.0.70\lib\fan\gfx.pod
         sys 1.0.70 - C:\Apps\fantom-1.0.70\lib\fan\sys.pod
```

Debug may also be enabled by setting the `FPM_DEBUG` environment variable to `true`:

    C:\> set FPM_DEBUG = true

Debug can also be turned on by adding this line to `%FAN_HOME%/etc/sys/log.props`:

    afFpm=debug

### Environment Variables

A list of environment variables used by FPM:

`FAN_ENV_PODS` - a list of pod files (their OS path locations) that should always be resolved and trump all other versions. This var is provided by F4 when launching Runtimes.

`FPM_ALL_PODS` - set to `true` to force the environement to resolve (the latest versions of) all known pods, after resolving the target.

`FPM_CONFIG_FILENAME` - filename of the config files to look for, should be prefixed with the FPM version. Used for developing new versions of FPM, whilst still using an older one.

`FPM_DEBUG` - set to `true` to enable FPM debugging. It's often easier to set this than alter the logging config.

`FPM_RESOLVE_TIMEOUT_1` - if resolving takes longer than this, and at least one solution has been found, then resolving stops and a potentially sub-optimal solution is returned. Defaults to `5sec`.

`FPM_RESOLVE_TIMEOUT_2` - if resolving takes longer than this, then resolving stops and reports no solution could be found. Defaults to `10sec`.

`FPM_TARGET` - the target pod to resolve an environment for.

`FPM_TRACE` - set to `true` to have the resolver save a file detailing the problem space that can subsequently be used in testing / debugging. The file defaults to `fpm-trace-deps.txt` in the current directory.

Examples:

    FPM_ALL_PODS          = true
    FPM_CONFIG_FILENAME   = 0.2.0/fpm2.props
    FPM_DEBUG             = true
    FPM_RESOLVE_TIMEOUT_1 = 5sec
    FPM_RESOLVE_TIMEOUT_2 = 10sec
    FPM_TARGET            = afIoc@3.0.6
    FPM_TRACE             = true

Note an cmd line argument of `-fpmTarget` can be used to set the target pod in place of the `FPM_TARGET` environment variable.

## F4 IDE Plugin

What use is a pod manager if you can't use it in your favourite IDE?

See the [Alien-Factory F4 Features](https://bitbucket.org/AlienFactory/f4-features) to install an FPM plugin for F4, enabling F4 to resolve pods from FPM repositories.

