#Fantom Pod Manager v0.0.0.3
---
[![Written in: Fantom](http://img.shields.io/badge/written%20in-Fantom-lightgray.svg)](http://fantom.org/)
[![pod: v0.0.0.3](http://img.shields.io/badge/pod-v0.0.0.3-yellow.svg)](http://www.fantomfactory.org/pods/afFpm)
![Licence: MIT](http://img.shields.io/badge/licence-MIT-blue.svg)

## Overview

Fantom Pod Manager (FPM) provides a targetted environment for compiling, testing, and running Fantom pods.

It is one of those boring system libraries that you quickly find you can't do without.

A typical Fantom installation only allows one version of any given pod. This works fine if you're just developing and running the one application. But if you're developing multiple applications, each requiring different versions of the same pod; then you either need multiple Fantom environments, one for each application, ... or you need FPM.

FPM maintains a local [fanr file repository](http://fantom.org/doc/docFanr/FileRepos.html) of Fantom pods, where multiple versions of the same pod are kept. When a Fantom application is built, test, or run via FPM; then FPM cherry picks the pod versions required.

## Install

Install `Fantom Pod Manager` with the Fantom Repository Manager ( [fanr](http://fantom.org/doc/docFanr/Tool.html#install) ):

    C:\> fanr install -r http://pods.fantomfactory.org/fanr/ afFpm

To use in a [Fantom](http://fantom.org/) project, add a dependency to `build.fan`:

    depends = ["sys 1.0", ..., "afFpm 0.0"]

## Documentation

Full API & fandocs are available on the [Fantom Pod Repository](http://pods.fantomfactory.org/pods/afFpm/).

## Quick Start

Once you've installed FPM via `fanr`, run the setup command:

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
       default = C:\Apps\fantom-1.0.68\fpmRepo

    Fanr Repos :
 fantomFactory = http://pods.fantomfactory.org/fanr/
     status302 = http://repo.status302.com/fanr/
        fantom = http://fantom.org/fanr/
```

As you can see, the `setup` command creates an `fpm.bat` file, an `fpm.config` file, and publishes any non-core pods to a local repository.

You can then use `fpm` from the command line to run Fantom.

Behind the scenes: set `FAN_ENV`

set DEBUG to on

## FPM Commands

Following is a list of FPM commands:

### setup

FANDOC: afFpm::SetupCmd

### build

FANDOC: afFpm::BuildCmd

### test

FANDOC: afFpm::TestCmd

### run

FANDOC: afFpm::RunCmd

### install

FANDOC: afFpm::InstallCmd

### uninstall

FANDOC: afFpm::UninstallCmd

### update

FANDOC: afFpm::UpdateCmd

### help

FANDOC: afFpm::HelpCmd

## FPM Config

Config files are *not* addative. Config found in a higher priority files *replaces* the value of the lower.

## FPM Runtime Env

To run a fantom application, script, or build, FPM needs to know which pod it should resolve dependencies for. This is known as the *target pod*.

In most common cases FPM is able to infer the target pod from what is being run. In other cases you should set the environment variable `FPM_TARGET`.

In Windows:

    C:\> set FPM_TARGET=myApp

In Linux:

    $ export FPM_TARGET=myApp

FPM will always use the `FPM_TARGET` environment variable if it is set.

If FPM fails to resolve a target pod then it falls back to providing the latest versions of all pods.

### Run a Fantom Application

Where it can FPM uses [Env.mainMethod()](http://fantom.org/doc/sys/Env.html#mainMethod) to determine the target pod. For example, all the following commands would all resolve `myApp` as the target pod.

    C:\> fan myApp
    
    C:\> fan myApp::Example
    
    C:\> fan myApp::Example.main

If using a library to kick start an app, such as BedSheet, like below:

    C:\> fan afBedSheet myApp

Then FPM would resolve `afBedSheet` as the target pod, not `myApp`, so you would need to use the `FPM_TARGET` environement variable.

### Run a Fantom Script

When running a file as Fantom script, such as:

    C:\> fan myScript.fan

Then FPM has no knowledge of the script's dependencies, so it defaults to providing the latest pod versions, or using `FPM_TARGET` if defined.

### Build a Fantom Pod

FPM can detect when a `build.fan` script is being run, but it doesn't know which one! So it assumes it is the `build.fan` file in the *current* directory. It then loads the build script and parses the dependencies from it.

In general, running a standard build script, as shown below, will work as expected:

    C:\> fan build.fan

But running a build script in a different directory or with a different name will yield unexpected results:

    Will not work:
    
    C:\> fan some\other\dir\build.fan
    
    C:\> fan customBuild.fan

### Run Fantom Tests

When running Fantom tests using the `fant` runner, there is no `main` method per-se, so FPM can't infer the target pod. When running tests the `FPM_TARGET` environment variable should be used instead.

    C:\> set FPM_TARGET=myApp
    C:\> fant myApp

### Fantom 1.0.67

FPM makes heavy use of the `Env.mainMethod()` method which was only introduced in Fantom 1.0.68. If using a Fantom version prior to 1.0.68 then the `FPM_TARGET` environement variable would need to be set in all cirsumstances.

If `FPM_TARGET` is not set then FPM falls back to its default of providing just the latest pod versions.

## FPM Cmds

    C:\> fan afFpm <cmd> -p <pod> -r <repo>
    
    fan afFpm on its own should just dump fpm config

### Setup

### Install

### Uninstall

### Publish

delete - use install instead

### Update

