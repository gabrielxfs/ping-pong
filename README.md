# Testing scenario for ipv6 problem in docker overlay network

## Description

This repo provide a testing scenario for the problem of enabling ipv6 inside overlay network in docker. It was first noticed in a deploy with a lot of services that communicaticate with each other using the name given by the docker network, that usually is the container name in described in a compose file.

The testing scenario could be used in a `docker stack deploy --c docker-compose.yml` fashion way, or using the portainer as well.

## Reproduce steps

- Stop docker in the system if already running:
```
sudo systemctl stop docker
```
- Edit the /etc/docker/daemon.json file to enable ipv6 in docker:
```
{
  "ipv6": true,
  "fixed-cidr-v6": "fd54:69d7:8d50::/48",
  "experimental": true,
  "ip6tables": true
}
```
- Restart docker:
```
sudo systemctl restart docker
```
- Create gwbridge before swarm init with ipv6 subnet:
```
sudo docker network create \
  --ipv6 \
  --subnet 172.20.0.0/20 \
  --gateway 172.20.0.1 \
  --gateway fd0e:448e:22a5::1 \
  --subnet fd0e:448e:22a5::/48 \
  --opt com.docker.network.bridge.name=docker_gwbridge \
  --opt com.docker.network.bridge.enable_icc=false \
  --opt com.docker.network.bridge.enable_ip_masquerade=true \
  docker_gwbridge
```
- Then init the swarm:
```
sudo docker swarm init
```
- Create the swarm_overlay_network to be used by the stacks containers:
```
sudo docker network create --ipv6 --subnet fd46:f722:3989::/48 --subnet=172.22.32.0/24 --scope=swarm -d overlay swarm_overlay_network
```

## Expected behavior

Inside the container, is expected that they use their internal docker DNS name and be able to send package to each other. But that is not what happens:
```
~# docker logs b631fa83fa93
Waiting for pong...
wait-for-it.sh: waiting for pong:80 without a timeout
~# docker logs c3e45d595181
Waiting for pang...
wait-for-it.sh: waiting for pang:80 without a timeout
~# docker exec -u root -it c3e45d595181 bash
c3e45d595181:/setup# ping pang
ping: bad address 'pang'
c3e45d595181:/setup# ping pp_pang
ping: bad address 'pp_pang'
c3e45d595181:/setup# ping pong
ping: bad address 'pong'
c3e45d595181:/setup# ping pp_pong
ping: bad address 'pp_pong'
```
If we take a look at networks we got the IPv6 address and their containers names:
![containers_in_network_pp](https://github.com/gabrielxfs/ping-pong/assets/7542274/7c07e712-6ead-4530-8600-692fc3537894)

We can evenly ping directly their address:
```
c3e45d595181:/setup# ping 172.22.32.12
PING 172.22.32.12 (172.22.32.12): 56 data bytes
64 bytes from 172.22.32.12: seq=0 ttl=64 time=0.326 ms
^C
--- 172.22.32.12 ping statistics ---
1 packets transmitted, 1 packets received, 0% packet loss
round-trip min/avg/max = 0.326/0.326/0.326 ms
c3e45d595181:/setup# ping -c 1 fd46:f722:3989::34
PING fd46:f722:3989::34 (fd46:f722:3989::34): 56 data bytes
64 bytes from fd46:f722:3989::34: seq=0 ttl=64 time=0.369 ms

--- fd46:f722:3989::34 ping statistics ---
1 packets transmitted, 1 packets received, 0% packet loss
round-trip min/avg/max = 0.369/0.369/0.369 ms
c3e45d595181:/setup# ping -c 1  172.22.32.11
PING 172.22.32.11 (172.22.32.11): 56 data bytes
64 bytes from 172.22.32.11: seq=0 ttl=64 time=0.078 ms

--- 172.22.32.11 ping statistics ---
1 packets transmitted, 1 packets received, 0% packet loss
round-trip min/avg/max = 0.078/0.078/0.078 ms
c3e45d595181:/setup# ping -c 1 fd46:f722:3989::36
PING fd46:f722:3989::36 (fd46:f722:3989::36): 56 data bytes
64 bytes from fd46:f722:3989::36: seq=0 ttl=64 time=0.255 ms

--- fd46:f722:3989::36 ping statistics ---
1 packets transmitted, 1 packets received, 0% packet loss
round-trip min/avg/max = 0.255/0.255/0.255 ms
c3e45d595181:/setup# ping -c 1 google.com
PING google.com (142.250.217.174): 56 data bytes
64 bytes from 142.250.217.174: seq=0 ttl=117 time=1.596 ms

--- google.com ping statistics ---
1 packets transmitted, 1 packets received, 0% packet loss
round-trip min/avg/max = 1.596/1.596/1.596 ms
c3e45d595181:/setup# ping -c 1 -6 google.com
PING google.com (2607:f8b0:4008:80a::200e): 56 data bytes
64 bytes from 2607:f8b0:4008:80a::200e: seq=0 ttl=116 time=1.821 ms

--- google.com ping statistics ---
1 packets transmitted, 1 packets received, 0% packet loss
round-trip min/avg/max = 1.821/1.821/1.821 ms
```
But, when we create the swarm_overlay_network without IPv6:
![containers_in_network_pp_without_ipv6](https://github.com/gabrielxfs/ping-pong/assets/7542274/70b1679f-5513-43d6-affb-63b3995459f0)

The containers are able to switch packages with each other:
```
057e835f6892:/setup# ping -c1 pang
PING pang (172.22.32.5): 56 data bytes
64 bytes from 172.22.32.5: seq=0 ttl=64 time=0.088 ms

--- pang ping statistics ---
1 packets transmitted, 1 packets received, 0% packet loss
round-trip min/avg/max = 0.088/0.088/0.088 ms
057e835f6892:/setup# ping -c 1 pong
PING pong (172.22.32.2): 56 data bytes
64 bytes from 172.22.32.2: seq=0 ttl=64 time=0.071 ms

--- pong ping statistics ---
1 packets transmitted, 1 packets received, 0% packet loss
round-trip min/avg/max = 0.071/0.071/0.071 ms
057e835f6892:/setup# ping -c 1 pp_pang
PING pp_pang (172.22.32.5): 56 data bytes
64 bytes from 172.22.32.5: seq=0 ttl=64 time=0.079 ms

--- pp_pang ping statistics ---
1 packets transmitted, 1 packets received, 0% packet loss
round-trip min/avg/max = 0.079/0.079/0.079 ms
057e835f6892:/setup# ping -c 1 pp_pong
PING pp_pong (172.22.32.2): 56 data bytes
64 bytes from 172.22.32.2: seq=0 ttl=64 time=0.111 ms

--- pp_pong ping statistics ---
1 packets transmitted, 1 packets received, 0% packet loss
round-trip min/avg/max = 0.111/0.111/0.111 ms
```

So, semmingly, the problem lies on the the missing of DNS in docker when the network has IPv6 activated.
