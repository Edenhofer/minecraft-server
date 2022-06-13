SHELL = /bin/sh
INSTALL = install
INSTALL_PROGRAM = $(INSTALL) -m755
INSTALL_DIR = $(INSTALL) -d -m755
INSTALL_DATA = $(INSTALL) -m644
confdir = /etc/conf.d
prefix = /usr
bindir = $(prefix)/bin
libdir = $(prefix)/lib
datarootdir = $(prefix)/share
mandir = $(prefix)/share/man
man1dir = $(mandir)/man1

SOURCES = $(wildcard *.in)
OBJECTS = $(SOURCES:.in=)

GAME = minecraft
INAME = minecraftd
SERVER_ROOT = /srv/$(GAME)
CONFIG_PATH = /etc/conf.d/$(GAME)
SYSCONFDIR = /etc
INSTANCE_CONFIG_DIR = $(SYSCONFDIR)/$(GAME)
BACKUP_DEST = $(SERVER_ROOT)/backup
LIBRARY_PATH = $(libdir)/$(GAME)
BACKUP_PATHS = world
BACKUP_FLAGS = -z
KEEP_BACKUPS = 10
GAME_USER = $(GAME)
SERVER_MEMORY_INITIAL = 512
SERVER_MEMORY_MAXIMUM = 1024
MAIN_EXECUTABLE = minecraft_server.jar
ifeq ($(MAIN_EXECUTABLE),$(MAIN_EXECUTABLE:/%=))
MAIN_EXECUTABLE_ABSOLUTE = $(SERVER_ROOT)/$(MAIN_EXECUTABLE)
else
MAIN_EXECUTABLE_ABSOLUTE = $(MAIN_EXECUTABLE)
endif
TMUX_SOCKET_DIR = /run/$(GAME)/tmux
SESSION_NAME = $(GAME)
SERVER_START_CMD = java -Xms@SERVER_MEMORY_INITIAL@M -Xmx@SERVER_MEMORY_MAXIMUM@M -jar @MAIN_EXECUTABLE@ nogui
SERVER_START_SUCCESS = done
IDLE_SERVER = false
IDLE_SESSION_NAME = idle_server_@SESSION_NAME@
GAME_PORT = 25565
CHECK_PLAYER_TIME = 30
IDLE_IF_TIME = 1200
GAME_COMMAND_DUMP = $(TMUX_SOCKET_DIR)/@INAME@_@SESSION_NAME@_command_dump.txt

.MAIN = all

define replace_all
	cp -a $(1) $(2)
	sed -i \
		-e 's#@INAME@#$(INAME)#g' \
		-e 's#@GAME@#$(GAME)#g' \
		-e 's#@SERVER_ROOT@#$(SERVER_ROOT)#g' \
		-e 's#@CONFIG_PATH@#$(CONFIG_PATH)#g' \
		-e 's#@LIBRARY_PATH@#$(LIBRARY_PATH)#g' \
		-e 's#@SYSCONFDIR@#$(SYSCONFDIR)#g' \
		-e 's#@INSTANCE_CONFIG_DIR@#$(INSTANCE_CONFIG_DIR)#g' \
		-e 's#@BACKUP_DEST@#$(BACKUP_DEST)#g' \
		-e 's#@BACKUP_PATHS@#$(BACKUP_PATHS)#g' \
		-e 's#@BACKUP_FLAGS@#$(BACKUP_FLAGS)#g' \
		-e 's#@KEEP_BACKUPS@#$(KEEP_BACKUPS)#g' \
		-e 's#@GAME_USER@#$(GAME_USER)#g' \
		-e 's#@MAIN_EXECUTABLE@#$(MAIN_EXECUTABLE)#g' \
		-e 's#@MAIN_EXECUTABLE_ABSOLUTE@#$(MAIN_EXECUTABLE_ABSOLUTE)#g' \
		-e 's#@SERVER_MEMORY_INITIAL@#$(SERVER_MEMORY_INITIAL)#g' \
		-e 's#@SERVER_MEMORY_MAXIMUM@#$(SERVER_MEMORY_MAXIMUM)#g' \
		-e 's#@TMUX_SOCKET_DIR@#$(TMUX_SOCKET_DIR)#g' \
		-e 's#@SESSION_NAME@#$(SESSION_NAME)#g' \
		-e 's#@SERVER_START_CMD@#$(SERVER_START_CMD)#g' \
		-e 's#@SERVER_START_SUCCESS@#$(SERVER_START_SUCCESS)#g' \
		-e 's#@IDLE_SERVER@#$(IDLE_SERVER)#g' \
		-e 's#@IDLE_SESSION_NAME@#$(IDLE_SESSION_NAME)#g' \
		-e 's#@GAME_PORT@#$(GAME_PORT)#g' \
		-e 's#@CHECK_PLAYER_TIME@#$(CHECK_PLAYER_TIME)#g' \
		-e 's#@IDLE_IF_TIME@#$(IDLE_IF_TIME)#g' \
		-e 's#@GAME_COMMAND_DUMP@#$(GAME_COMMAND_DUMP)#g' \
		$(2)
endef

all: $(OBJECTS)
	echo $(OBJECTS)

%.sh: %.sh.in
	$(call replace_all,$<,$@)

%.conf: %.conf.in
	$(call replace_all,$<,$@)

%.service: %.service.in
	$(call replace_all,$<,$@)

%.sysusers: %.sysusers.in
	$(call replace_all,$<,$@)

%.tmpfiles: %.tmpfiles.in
	$(call replace_all,$<,$@)

%.timer: %.timer.in
	$(call replace_all,$<,$@)

clean:
	rm -f $(OBJECTS)

distclean: clean

maintainer-clean: clean

install:
	$(INSTALL_PROGRAM) -D minecraftd.sh "$(DESTDIR)$(bindir)/$(INAME)"
	$(INSTALL_DIR) "$(DESTDIR)$(LIBRARY_PATH)"
	$(INSTALL_DATA) -D argparse.sh                "$(DESTDIR)$(LIBRARY_PATH)/argparse.sh"
	$(INSTALL_DATA) -D minecraftd.conf            "$(DESTDIR)$(confdir)/$(GAME)"
	$(INSTALL_DATA) -D minecraftd.service         "$(DESTDIR)$(libdir)/systemd/system/$(INAME).service"
	$(INSTALL_DATA) -D minecraftd-backup.service  "$(DESTDIR)$(libdir)/systemd/system/$(INAME)-backup.service"
	$(INSTALL_DATA) -D minecraftd-backup.timer    "$(DESTDIR)$(libdir)/systemd/system/$(INAME)-backup.timer"
	$(INSTALL_DATA) -D minecraftd@.service        "$(DESTDIR)$(libdir)/systemd/system/$(INAME)@.service"
	$(INSTALL_DATA) -D minecraftd-init@.service   "$(DESTDIR)$(libdir)/systemd/system/$(INAME)-init@.service"
	$(INSTALL_DATA) -D minecraftd-backup@.service "$(DESTDIR)$(libdir)/systemd/system/$(INAME)-backup@.service"
	$(INSTALL_DATA) -D minecraftd-backup@.timer   "$(DESTDIR)$(libdir)/systemd/system/$(INAME)-backup@.timer"
	$(INSTALL_DATA) -D minecraftd.sysusers        "$(DESTDIR)$(libdir)/sysusers.d/$(INAME).conf"
	$(INSTALL_DATA) -D minecraftd.tmpfiles        "$(DESTDIR)$(libdir)/tmpfiles.d/$(INAME).conf"

uninstall:
	rm -f "$(bindir)/$(INAME)"
	rm -f "$(confdir)/$(GAME)"
	rm -f "$(libdir)/systemd/system/$(INAME).service"
	rm -f "$(libdir)/systemd/system/$(INAME)-backup.service"
	rm -f "$(libdir)/systemd/system/$(INAME)-backup.timer"
	rm -f "$(libdir)/sysusers.d/$(INAME).conf"
	rm -f "$(libdir)/tmpfiles.d/$(INAME).conf"
