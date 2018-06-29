
# mco_rpc

#### Table of Contents

1. [Description](#description)
1. [Requirements](#requirements)
1. [Setup - The basics of getting started with mco_rpc](#setup)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Limitations - OS compatibility, etc.](#limitations)

## Description

The `mco_rpc` module contains a task to run installed rpc agents through Puppet
Tasks with either bolt or the Puppet Orchestrator.

## Requirements

This module is compatible with Puppet Enterprise and Puppet Bolt.

* To run tasks with Puppet Enterprise, PE 2017.3 or later must be installed on the machine from which you are running task commands. Machines receiving task requests must be Puppet agents.

* To run tasks with Puppet Bolt, Bolt 0.5 or later must be installed on the machine from which you are running task commands. Machines receiving task requests must have SSH or WinRM services enabled.

## Setup

The Puppet agent package and any rpc agents that are going to be run must be
installed on all target nodes. The MCO server does not have to be running and
there is no need for MCO middleware or messaging services.

## Usage

To run the package task with `bolt`

```
bolt task run mco_rpc --modulepath $MODULEPATH --nodes $TARGETNODES agent=package action=install args='package=nano'
```

To run the package task with `puppet task`

```
puppet-task run mco_rpc $TARGETS agent=package action=install arguments='package=nano'
```

## Reference

### Parameters

`agent String[1]`:
  The MCO RPC agent to run.

`action String[1]`:
  The action of the agent to run.

`data Optional[Hash]`:
  The options to pass to to the action. These vary per action.

`arguments Optional[String]`:
  A single string or arguments to the action as might be passed to the mco CLI
  ie. 'package=nano verson=2.8.7' This parameter and data are mutually
  exclusive.

## Limitations

This is a pre `1.0.0` release and future versions may have breaking changes.
This relies on the Puppet agent packaged ruby and the MCO gem to run.
