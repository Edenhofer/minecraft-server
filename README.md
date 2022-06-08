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

Adjust the configuration file under `/etc/conf.d/minecraft` to your liking.

If you are running multiple servers, the configuration file `/etc/minecraft/<instance name>` will be loaded if it exists, and will supersede any options set in the global configuration.

Any configuration variable can be overridden in the environment.

To see the effective configuration based on the instance name and all applicable configuration files, run `minecraftd print`, `minecraftd -i server2 print`, etc. To print the plain value of a single configuration key, use the `-k` argument: `minecraftd print -k SERVER_ROOT`.

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

The configuration variables whose defaults change in instantiated mode are:

* `SERVER_ROOT` changes from `/srv/minecraft` to `/srv/minecraft/servers/<instance name>`
* `SESSION_NAME` changes from `minecraft` to `minecraft-<instance name>`
* `BACKUP_DEST` changes from `/srv/minecraft/backup` to `/srv/minecraft/servers/<instance name>/backup`

These can also be overridden in the instance-specific configuration file, `/etc/minecraft/<instance name>`.

## License

Unless otherwise stated, the files in this project may be distributed under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or any later version. This work is distributed in the hope that it will be useful, but without any warranty; without even the implied warranty of merchantability or fitness for a particular purpose. See [version 2](https://www.gnu.org/licenses/old-licenses/gpl-2.0.html) and [version 3](https://www.gnu.org/copyleft/gpl-3.0.html) of the GNU General Public License for more details.
