# Management Script for Minecraft Servers

## Content

The main purpose of this repository is to develop a minecraft server management script.
Its driving goals are minimalism, versatility (spigot/papermc/cuberite/...) and feature completeness.

The script depends on `tmux` to fork the server into the background and communicate with it.
All the communication namely querying for online users and issuing commands in the console of the server is done using `tmux`.
While the server is offline, the script can listen on the minecraft port for incoming connections and start up the server as soon as a user connects.

## Installation

### Dependencies

* bash
* awk
* sed
* sudo -- privilege separation
* tmux -- communication with server

* netcat -- listen on the minecraft port for incoming connections while the server is down (optional)
* tar -- take world backups (optional)

### Build

```
make
```

### Installation

```
make install
```

### Build and Install for a different Flavor of Minecraft

```
make GAME=spigot \
  INAME=spigot \
  SERVER_ROOT=/srv/craftbukkit \
  BACKUP_PATHS="world world_nether world_the_end" \
  GAME_USER=craftbukkit \
  MAIN_EXECUTABLE=spigot.jar \
  SERVER_START_CMD="java -Xms512M -Xmx1024M -jar ./spigot.jar nogui"
```

```
make install \
  GAME=spigot \
  INAME=spigot
```

## FAQ

### Where are the Server Files Located

The world data is stored under /srv/minecraft and the server runs as minecraft user to increase security.
Use the minecraft script under /usr/bin/minecraftd to start, stop or backup the server.

### How to configure the Server

Adjust the configuration file under /etc/conf.d/minecraft to your liking.

### Server does not start

For the server to start you have to accept the EULA in /srv/minecraft/eula.txt !
The EULA file is generated after the first server start.

### Running multiple servers on the same host

The generated file `minecraftd@.service` allows you to run than one instance of the server on a single host. A unique data directory (`/srv/minecraft/servers/<instance name>`) is created for each instance.

You need to create, at minimum, `eula.txt` and `server.properties` (the latter specifying an alternate `server-port`) before the server will start. This means the workflow for setting up a new server looks something like:

```sh
systemctl start minecraftd@server-name        #      (creates directories; the service will fail to start, that's ok)
sed -re 's;^eula=.*$;eula=true;' -i /srv/minecraft/servers/server-name/eula.txt
sed -re 's;^(server-port|query\.port)=.*$;\1=25567;g' /srv/minecraft/servers/server-name/server.properties
systemctl start minecraftd@server-name        #      (it should start this time)
```

To facilitate the use of a unique environment variable file per instance, the file `/etc/minecraft/<instance name>` is read in addition to the global environment file, `/etc/conf.d/minecraft`. Note that `minecraft` is the value of the `@GAME@` macro in this case, so change this to `/etc/spigot/<instance name>`, etc. Values in the instance-specific environment file take precedence over values in the global configuration.

Behind the scenes, the systemd instantiated unit achieves instantiation by changing several environment variables as follows (where `%i` is the instance name, and `@SERVER_ROOT` defaults to `/srv/@GAME@`):

* `SERVER_ROOT=@SERVER_ROOT@/servers/%i`
* `BACKUP_DEST=@SERVER_ROOT@/servers/%i/backup`
* `SESSION_NAME=@GAME@-%i`

This means that attempting to override these environment variables in the per-instance environment file may result in the server not starting or files being in the wrong location.

If you need to start an instantiated server manually for some reason, you can do:

```sh
env SERVER_ROOT=/srv/minecraft/servers/creative \
    SESSION_NAME=minecraft-creative \
    minecraftd start
```

To attach to the console, just override the `SESSION_NAME` variable with `minecraft-` followed by the instance name:

```sh
$ SESSION_NAME=minecraft-creative minecraftd console
```

In the above example, `minecraft` is the value of the `@GAME@` macro, so you might need `spigot-creative`, `papermc-creative`, etc.

To take a backup, use instantiated variants of the service and timer, or set `BACKUP_DEST` alongside `SERVER_ROOT` and `SESSION_NAME` when running `minecraftd backup`.

## License

Unless otherwise stated, the files in this project may be distributed under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or any later version. This work is distributed in the hope that it will be useful, but without any warranty; without even the implied warranty of merchantability or fitness for a particular purpose. See [version 2](https://www.gnu.org/licenses/old-licenses/gpl-2.0.html) and [version 3](https://www.gnu.org/copyleft/gpl-3.0.html) of the GNU General Public License for more details.
