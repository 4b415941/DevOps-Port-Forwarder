# Port Forwarding Scripts

This repository contains Bash scripts for forwarding a specific port on different platforms (Kubernetes, Docker Swarm, Docker Machine).

## Contents

- [Installation](#installation)
- [Usage](#usage)
- [Examples](#examples)
- [Options](#options)

## Installation

To use these scripts, Bash and the relevant platform must be installed. No special installation is required to use the scripts.

## Usage

Each script can be used to forward or stop forwarding a specific port. For more information on usage and options, please refer to the content and comments of the respective script.

## Examples

- Forward port 8080 to the same port on localhost:
  ```bash
  ./kubernetes_port_forward.sh 8080

  ```bash
  ./kubernetes_port_forward.sh -s 8080

  ## Options

The available options for each script are as follows:

- `-h, --help`: Displays the help message.
- `-s, --stop`: Stops port forwarding.
- `-q, --quiet`: Runs in quiet mode.
- `-f, --foreground`: Runs the SSH forwarding process in the foreground.
- `-e, --environment <env>`: Specifies the Docker Machine environment.
