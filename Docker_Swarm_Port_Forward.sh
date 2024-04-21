#!/bin/bash

# Author: Kadircan Kaya
# LinkedIn: [Kadircan Kaya](https://www.linkedin.com/in/kadircan-kaya/)
# Description: This script forwards a specific port on Docker Swarm.
# It automates common tasks in development and testing environments, allowing users to quickly forward or stop forwarding a port.

readonly SCRIPT_NAME=$(basename "$0")
readonly usage="Usage: $SCRIPT_NAME [options] <port>

Options:
  -h, --help              Display this help message and exit.
  -s, --stop              Stop port forwarding.
  -q, --quiet             Quiet mode.

Examples:
  $SCRIPT_NAME 8080                  # Forward port 8080 to the same port on localhost.
  $SCRIPT_NAME -s 8080               # Stop port forwarding on port 8080.

"

display_help() {
    echo "$usage"
    exit 0
}

print_error() {
    echo "Error: $1" >&2
    exit "${2:-1}"
}

stop_port_forwarding() {
    local port=$1
    local existing=$(docker service ls | grep "0.0.0.0:$port->")

    if [ -z "$existing" ]; then
        if [ "$quiet" = false ]; then
            echo "Warning: Port $port is not being forwarded, cannot stop."
        fi
        exit 1
    fi 

    local service_id=$(echo "$existing" | awk '{ print $1 }')
    docker service rm "$service_id" &&
    echo "Stopped port forwarding for port $port."
    exit 0
}

parse_command_line_arguments() {
    local port=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                display_help
                ;;
            -s|--stop)
                stop=true
                ;;
            -q|--quiet)
                quiet=true
                ;;
            --)
                break
                ;;
            -*)
                print_error "Invalid option '$1'. Use --help to see the valid options." 2
                ;;
            *)
                if [ -z "$port" ]; then
                    port="$1"
                    if ! [[ "$port" =~ ^[0-9]+$ ]]; then
                        print_error "Port must be a valid number." 3
                    fi
                else
                    print_error "You specified multiple ports. Specify only one port." 4
                fi
                ;;
        esac
        shift
    done

    if [ -z "$port" ]; then
        print_error "You need to specify the port to forward." 5
    fi
}

forward_port() {
    local port="$1"

    # Check if the port is already in use
    local used=$(netstat -tuln | grep ":$port ")
    if [ -n "$used" ]; then
        print_error "Port $port is already in use. Please choose another port." 6
    fi

    # Start port forwarding
    docker service create --name port-forward --publish published="$port",target="$port" --mode global alpine sleep 1000000 &&
    if [[ "$quiet" = false ]]; then
        echo "Forwarding port $port to localhost in Docker Swarm."
    fi
}

main() {
    local stop=false
    local quiet=false
    local port=""

    if [ $# -eq 0 ]; then
        display_help
    fi

    parse_command_line_arguments "$@"

    if [ "$stop" = true ]; then
        stop_port_forwarding "$port"
    fi

    forward_port "$port"
}

main "$@"
