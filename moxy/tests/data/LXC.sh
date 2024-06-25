#!/usr/bin/env bash

export LXC_CLI_RESPONSE='[
    {"tags": "db;storage","maxmem": 2147483648,"diskread": 843419648,"status": "running","netout": 152786800,"cpu": 0.00610331685300357,"netin": 525274836,"type": "lxc","maxdisk": 17179869184,"vmid": 510,"id": "lxc/510","node": "pve","mem": 525721600,"maxcpu": 2,"uptime": 53472,"template": 0,"diskwrite": 0,"disk": 5446041600,"name": "maria"},
    {"type": "lxc","maxdisk": 8589934592,"cpu": 0.0000586203519135293,"netin": 872431370,"vmid": 512,"id": "lxc/512","tags": "db;storage","diskread": 51707904,"netout": 858955,"status": "running","maxmem": 2147483648,"disk": 3174039552,"name": "postgres","maxcpu": 2,"uptime": 240388,"node": "kickstand","mem": 39223296,"diskwrite": 0,"template": 0},
    {"maxmem": 536870912,"netout": 0,"diskread": 0,"status": "stopped","id": "lxc/900","vmid": 900,"netin": 0,"cpu": 0,"maxdisk": 4294967296,"type": "lxc","template": 1,"diskwrite": 0,"mem": 0,"node": "kickstand","uptime": 0,"maxcpu": 8,"name": "nixos-template-23-11","disk": 0}
]'

export LXC_API_RESPONSE=''
