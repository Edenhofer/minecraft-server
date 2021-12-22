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
  MYNAME=spigot \
  SERVER_ROOT=/srv/craftbukkit \
  BACKUP_PATHS="world world_nether world_the_end" \
  GAME_USER=craftbukkit \
  MAIN_EXECUTABLE=spigot.jar \
  SERVER_START_CMD="java -Xms512M -Xmx1024M -jar ./spigot.jar nogui"
```

```
make install \
  GAME=spigot \
  MYNAME=spigot
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

## License

Unless otherwise stated, the files in this project may be distributed under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or any later version. This work is distributed in the hope that it will be useful, but without any warranty; without even the implied warranty of merchantability or fitness for a particular purpose. See [version 2](https://www.gnu.org/licenses/old-licenses/gpl-2.0.html) and [version 3](https://www.gnu.org/copyleft/gpl-3.0.html) of the GNU General Public License for more details.
