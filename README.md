# Mediathek WRR

## System setup
OS: Ubuntu 16.04

apt install nginx-extras
apt install lua-nginx-redis
apt install redis-server

## NGINX configuration
lua_package_path "/usr/share/lua/5.1/nginx/?.lua;;";
lua_socket_pool_size 100;
lua_socket_connect_timeout 10ms;
lua_socket_read_timeout 10ms;

server {
        ...
        location /mvlb {
                access_by_lua_file /var/www/srv1/mvlb.lua;
        }
        ...
}

## Redis commands

### Add new server
Add server URL
hset mdthk:vlb:servers srv5 "http://verteiler5.mediathekview.de/Filmliste-akt.xz"
NOTE: srv5 is the key and must be unique

Set server weight
zadd mdthk:vlb:weights 4 srv5

## Show all servers
URLs:
hgetall mdthk:vlb:servers
127.0.0.1:6379> hgetall mdthk:vlb:servers
 1) "srv1"
 2) "http://verteiler1.mediathekview.de/Filmliste-akt.xz"
 3) "srv2"
 4) "http://verteiler2.mediathekview.de/Filmliste-akt.xz"
 5) "srv3"
 6) "http://verteiler3.mediathekview.de/Filmliste-akt.xz"
 7) "srv4"
 8) "http://verteiler4.mediathekview.de/Filmliste-akt.xz"
 9) "srv5"
10) "http://verteiler5.mediathekview.de/Filmliste-akt.xz"

Weights:
zrange mdthk:vlb:weights 0 -1 withscores
127.0.0.1:6379> zrange mdthk:vlb:weights 0 -1 withscores
 1) "srv2"
 2) "2"
 3) "srv3"
 4) "2"
 5) "srv1"
 6) "4"
 7) "srv4"
 8) "4"
 9) "srv5"
10) "4"
