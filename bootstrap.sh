#!/usr/bin/env bash

#shellcheck disable=2164

# Only update the major version when a breaking change is introduced

bootstrap_version="1.3"
steam_cmd=/usr/games/steamcmd
folder="/home/rootlessrunner/.local/share/Steam/steamapps/common/tModLoader"

username=$STEAM_USERNAME

script_version="3.0.0.0m_3"
tmod_script_url="https://raw.githubusercontent.com/tModLoader/tModLoader/1.4.4/patches/tModLoader/Terraria/release_extras/DedicatedServerUtils/manage-tModLoaderServer.sh"}

# Check PATH and flags for required commands for tml/mod installation done manually.
function install_tml
{
	echo "Installing TML from Steam"
	# Installs tML, but all other steam assets will be in $HOME/Steam or $HOME/.steam
	eval "$steam_cmd +login $username +app_update 1281930 +quit"

	if [[ $? = "5" ]]; then # Only recurse when not being used in the docker container.
		echo "Try entering password/2fa code again"
		install_tml
	fi
}

function install_workshop_mods
{
	if ! [[ -r install.txt ]]; then
		echo "No workshop mods to install"
		return
	fi
	echo "Installing workshop mods"

	local steamcmd_command
	lines=$(cat install.txt)
	for line in $lines; do
		steamcmd_command="$steamcmd_command +workshop_download_item 1281930 $line"
	done

	eval "$steam_cmd +login $username $steamcmd_command +quit"

	echo "Done"
}

function print_help
{
	echo \
"tML dedicated server installation and maintenance script

Usage: script.sh COMMAND [OPTIONS]

Options:
 -h|--help           Show command line help
 -v|--version        Display the current version of the management script
 -u|--username       The steam username to login use when downloading tML. Not required to download mods
 --keepbackups       Will keep all tML backups instead of the most recent one when updating

Commands:
 cp-serverconfig     Copies the serverconfig to the CWD
 bak-serverconfig    Backs up serverconfig to serverconfig.bak
 edit-serverconfig   VIM of serverconfig
 install-tml         Installs tModLoader from Steam (or Github if --github is provided)
 install-mods        Installs any mods from install.txt, if present. Requires steamcmd
 install             Alias for install-tml install-mods
 update              Alias for install
 start [args]        Launches the server and passes through any extra args
"
	exit
}

# Set SteamCMD by default. Checks are done to ensure it's installed and the user will be notified if any issues arise
steamcmd=true
start_args=""

if [ $# -eq 0 ]; then # Check for commands
	echo "No command supplied"
	print_help
fi

# Covers cases where you only want to provide -h or -v without a command
cmd="$1"
if [[ "${cmd:0:1}" != "-" ]]; then
	shift
fi

while [[ $# -gt 0 ]]; do
	case $1 in
		-h|--help)
			print_help
			;;
		-v|--version)
			echo "tML Maintenance Tool v$bootstrap_version"
			exit
			;;
		-u|--username)
			username="$2"
			shift
			;;
		*)
			start_args="$start_args $1"
			;;
	esac
	shift
done

case $cmd in
	bak-serverconfig)
		cp "$folder/serverconfig.txt" "$folder/serverconfig.txt.bak"
		;;
        cp-serverconfig)
                cp "$folder/serverconfig.txt" .
                ;;
        edit-serverconfig)
                vim "$folder/serverconfig.txt"
                ;;
	install-mods)
		install_workshop_mods
		;;
	install-tml)
		install_tml
		;;
	install|update)
		install_tml
		install_workshop_mods
		;;
	start)
		cd "$folder" || exit
		chmod u+x start-tModLoaderServer.sh
		./start-tModLoaderServer.sh -config "$folder/serverconfig.txt" -nosteam "$start_args"
		;;
	*)
		echo "Invalid Command: $1"
		print_help
		;;
esac
