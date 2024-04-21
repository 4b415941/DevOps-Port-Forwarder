#!/bin/bash

# Author: Kadircan Kaya
# LinkedIn: [Kadircan Kaya](https://www.linkedin.com/in/kadircan-kaya/)
# Description: This script forwards a specific port on Docker Machine.
# It automates common tasks in development and testing environments, allowing users to quickly forward or stop forwarding a port.

readonly SCRIPT_NAME=$(basename "$0")
readonly usage="Usage: $SCRIPT_NAME [options] <port>

Options:
  -h, --help              Display this help message and exit.
  -s, --stop              Stop port forwarding.
  -f, --foreground        Run ssh forwarding process in the foreground.
  -e, --environment <env> Specify the docker-machine environment.
  -q, --quiet             Quiet mode.

Examples:
  $SCRIPT_NAME 8080                  # Forward port 8080 to the same port on localhost.
  $SCRIPT_NAME -e mymachine 8080    # Forward port 8080 to the same port on localhost in 'mymachine' environment.
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
    local result=$(lsof -n -i4TCP:"$port" | grep LISTEN)

    if [ -z "$result" ]; then
        if [ "$quiet" = false ]; then
            echo "Warning: Port $port is not being forwarded, cannot stop."
        fi
        exit 1
    fi 

    local process=$(echo "$result" | awk '{ print $1 }')
    if [ "$process" != "ssh" ]; then
        if [ "$quiet" = false ]; then
            echo "Warning: Port $port is bound by process $process and not by docker-machine, won't stop."
        fi
        exit 1
    fi

    local pid=$(echo "$result" | awk '{ print $2 }')
    kill "$pid" &&
    echo "Stopped port forwarding for port $port."
    exit 0
}

check_existing_forwarding() {
    local port=$1
    local existing=$(lsof -n -i4TCP:"$port" | grep LISTEN)

    if [ -n "$existing" ]; then
        local existing_process=$(echo "$existing" | awk '{ print $1 }')
        if [ "$existing_process" = "ssh" ]; then
            local existing_pid=$(echo "$existing" | awk '{ print $2 }')
            kill "$existing_pid" &&
            echo "Stopped previous port forwarding for port $port."
        fi
    fi
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
            -f|--foreground)
                foreground=true
                ;;
            -e|--environment)
                if [ -n "$2" ]; then
                    environment="$2"
                    shift
                else
                    print_error "You need to specify a value for the -e option." 1
                fi
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
                else
                    print_error "You specified multiple ports. Specify only one port." 3
                fi
                ;;
        esac
        shift
    done

    if [ -z "$port" ]; then
        print_error "You need to specify the port to forward." 4
    fi
}

forward_port() {
    local port="$1"
    local hostport="$2"
    local environment="$3"

    # Start port forwarding
    if [[ $port == *":"* ]]; then
        IFS=':' read -ra ports <<< "$port"
        if [[ ${#ports[@]} != 2 ]]; then
            print_error "Port forwarding should be defined as hostport:targetport, for example: 8090:8080" 5
        fi
        hostport=${ports[0]}
        port=${ports[1]}
    fi

    if [ -z "$hostport" ] || [ -z "$port" ]; then
        print_error "Both hostport and port must be specified for port forwarding." 6
    fi

    docker-machine ssh "$environment" $(if [[ "$foreground" = true ]]; then echo "-f -N"; fi) -L "$hostport":localhost:"$port" &&
    if [[ "$quiet" = false ]] && [[ "$foreground" = false ]]; then
        echo "Forwarding port $port to host port $hostport in docker-machine environment $environment."
    fi
}

main() {
    local stop=false
    local foreground=false
    local quiet=false
    local environment=""
    local port=""

    if [ $# -eq 0 ]; then
        display_help
    fi

    parse_command_line_arguments "$@"

    if [ "$stop" = true ]; then
        stop_port_forwarding "$port"
    fi

    check_existing_forwarding "$port"

    forward_port "$port" "$hostport" "$environment"
}

main "$@"
