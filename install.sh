#!/bin/bash

################################################
# Script by Locikll - 20/08/2018
# For Steem v0.19.11
################################################

LOG_FILE=/tmp/install.log

decho () {
  echo `date +"%H:%M:%S"` $1
  echo `date +"%H:%M:%S"` $1 >> $LOG_FILE
}

error() {
  local parent_lineno="$1"
  local message="$2"
  local code="${3:-1}"
  echo "Error on or near line ${parent_lineno}; exiting with status ${code}"
  exit "${code}"
}
trap 'error ${LINENO}' ERR

clear

cat <<'FIG'
   _____   _______   ______   ______   __  __ 
  / ____| |__   __| |  ____| |  ____| |  \/  |
 | (___      | |    | |__    | |__    | \  / |
  \___ \     | |    |  __|   |  __|   | |\/| |
  ____) |    | |    | |____  | |____  | |  | |
 |_____/     |_|    |______| |______| |_|  |_|

    __                     ______     __                  _     __      __    __
   / /_    __  __         / ____ \   / /  ____   _____   (_)   / /__   / /   / /
  / __ \  / / / /        / / __ `/  / /  / __ \ / ___/  / /   / //_/  / /   / / 
 / /_/ / / /_/ /        / / /_/ /  / /  / /_/ // /__   / /   / ,<    / /   / /  
/_.___/  \__, /         \ \__,_/  /_/   \____/ \___/  /_/   /_/|_|  /_/   /_/   
        /____/           \____/                                              
FIG

# Check for systemd
systemctl --version >/dev/null 2>&1 || { decho "systemd is required. Are you using Ubuntu 16.04?"  >&2; exit 1; }

# Check if executed as root user
if [[ $EUID -ne 0 ]]; then
	echo -e "This script has to be run as \033[1mroot\033[0m user"
	exit 1
fi

#print variable on a screen
decho "Make sure you double check before hitting enter !"

read -e -p "User that will run Steemd /!\ case sensitive /!\ : " whoami
if [[ "$whoami" == "" ]]; then
	decho "WARNING: No user entered, exiting!"
	exit 3
fi
if [[ "$whoami" == "root" ]]; then
	decho "WARNING: user root entered? It is recommended to use a non-root user, exiting !!!"
	exit 3
fi
read -e -p "Password for this user : " whoamipass
if [[ "$whoamipass" == "" ]]; then
	decho "WARNING: No password entered, exiting!"
	exit 3
fi
read -e -p "Server IP Address : " ip
if [[ "$ip" == "" ]]; then
	decho "WARNING: No IP entered, exiting!"
	exit 3
fi
read -e -p "Steem Witness version (vX.YY.ZZ), current version (20/08/2018) is v0.19.11 : " witver
if [[ "$witver" == "" ]]; then
	decho "WARNING: No Witness version entered, exiting!"
	exit 3
fi

read -e -p "Witness Username (e.g. locikll) : " wituser
if [[ "$wituser" == "" ]]; then
	decho "WARNING: No witness user entered, exiting!"
	exit 3
fi

read -e -p "Witness Signing Key (# THE SIGNING KEY YOU SHOULD HAVE GENERATED EARLIER) : " key
if [[ "$key" == "" ]]; then
	decho "WARNING: No signing key entered, exiting!"
	exit 3
fi
read -e -p "(Optional) Install Fail2ban? (Recommended) [Y/n] : " install_fail2ban
read -e -p "(Optional) Install UFW and configure ports? (Recommended) [Y/n] : " UFW
read -e -p "(Optional) Disable root login once complete? (Recommended) [Y/n] : " disableroot
read -e -p "(Optional) Run on RAM? [Y/n] : " mem_run
read -e -p "(Optional) Install Conductor for price feeds / failover switch [Y/n] : " conductor_install

if [[ ("$conductor_install" == "y" || "$conductor_install" == "Y") ]]; then

  read -e -p "Account Active-Private Key (# YOUR WITNESS ACCOUNT's ACTIVE KEY (REQUIRED AUTHORITY FOR FEED/FAIL OVER PUBLISHING) : " activekey
  if [[ "$activekey" == "" ]]; then
	  decho "WARNING: No Active key entered, exiting!"
	  exit 3
  fi
fi

decho "Updating system and installing required packages."   

# update package and upgrade Ubuntu
apt-get -y update >> $LOG_FILE 2>&1

decho "Installing base packages and dependencies..."

apt-get install -y git >> $LOG_FILE 2>&1
apt-get install -y build-essential >> $LOG_FILE 2>&1
apt-get install -y nano >> $LOG_FILE 2>&1
apt-get install -y cmake libssl-dev >> $LOG_FILE 2>&1
apt-get install -y libboost-all-dev >> $LOG_FILE 2>&1
apt-get install -y autoconf >> $LOG_FILE 2>&1
apt-get install -y autotools-dev >> $LOG_FILE 2>&1
apt-get install -y doxygen >> $LOG_FILE 2>&1
apt-get install -y libbz2-dev >> $LOG_FILE 2>&1
apt-get install -y libsnappy-dev >> $LOG_FILE 2>&1
apt-get install -y libncurses5-dev >> $LOG_FILE 2>&1
apt-get install -y libreadline-dev >> $LOG_FILE 2>&1
apt-get install -y libtool >> $LOG_FILE 2>&1
apt-get install -y screen >> $LOG_FILE 2>&1
apt-get install -y libicu-dev >> $LOG_FILE 2>&1
apt-get install -y libbz2-dev >> $LOG_FILE 2>&1
apt-get install -y graphviz >> $LOG_FILE 2>&1
apt-get install -y unzip >> $LOG_FILE 2>&1
apt-get install -y libffi-dev >> $LOG_FILE 2>&1
apt-get install -y python3 >> $LOG_FILE 2>&1
apt-get install -y python3-dev >> $LOG_FILE 2>&1
apt-get install -y python3-pip >> $LOG_FILE 2>&1
apt-get install -y htop >> $LOG_FILE 2>&1

pip3 install steem >> $LOG_FILE 2>&1
pip3 install jinja2 >> $LOG_FILE 2>&1

. ~/.bashrc

if [[ ("$install_fail2ban" == "y" || "$install_fail2ban" == "Y" || "$install_fail2ban" == "") ]]; then
	decho "Optional installs : fail2ban"
	cd ~
	apt-get -y install fail2ban >> $LOG_FILE 2>&1
	systemctl enable fail2ban >> $LOG_FILE 2>&1
	systemctl start fail2ban >> $LOG_FILE 2>&1
fi

if [[ ("$UFW" == "y" || "$UFW" == "Y" || "$UFW" == "") ]]; then
	decho "Optional installs : ufw"
	apt-get -y install ufw >> $LOG_FILE 2>&1
	ufw allow ssh/tcp >> $LOG_FILE 2>&1
	ufw allow sftp/tcp >> $LOG_FILE 2>&1
	ufw allow 8090/tcp >> $LOG_FILE 2>&1
	ufw allow 2001/tcp >> $LOG_FILE 2>&1
	ufw allow 8090/udp >> $LOG_FILE 2>&1
	ufw allow 2001/udp >> $LOG_FILE 2>&1
	ufw default deny incoming >> $LOG_FILE 2>&1
	ufw default allow outgoing >> $LOG_FILE 2>&1
	ufw logging on >> $LOG_FILE 2>&1
	ufw --force enable >> $LOG_FILE 2>&1
fi



decho "Create user $whoami"
#desactivate trap only for this command
trap '' ERR
getent passwd $whoami > /dev/null 2&>1

if [ $? -ne 0 ]; then
	trap 'error ${LINENO}' ERR
	adduser --disabled-password --gecos "" $whoami >> $LOG_FILE 2>&1
else
	trap 'error ${LINENO}' ERR
fi


decho "Setting up Steemd" 

git clone https://github.com/steemit/steem.git /home/$whoami/steem >> $LOG_FILE 2>&1
chown -R $whoami:$whoami /home/$whoami/steem >> $LOG_FILE 2>&1

cd /home/$whoami/steem

git checkout $witver
git submodule update --init --recursive
cmake -DENABLE_CONTENT_PATCHING=OFF -DLOW_MEMORY_NODE=ON CMakeLists.txt

make -j $nproc

cd /home/$whoami/steem/programs/steemd

screen -S steemdinit -dm /home/$whoami/steem/programs/steemd/steemd

sleep 30

pkill -SIGINT steemd

screen -X -S steemdinit quit
mv /root/.steemd /home/firepower/

cd /home/$whoami/.steemd/
rm -R blockchain && mkdir blockchain >> $LOG_FILE 2>&1

if [[ ("$mem_run" == "y" || "$mem_run" == "Y") ]]; then
  sharedfiledir='/dev/shm'
else
  sharedfiledir='/home/$whoami/.steemd/blockchain'
fi

echo 'Creating config.ini ...'

cat << EOF > /home/$whoami/.steemd/config.ini

log-appender = {"appender":"stderr","stream":"std_error"}
log-appender = {"appender":"p2p","file":"logs/p2p/p2p.log"}
log-logger = {"name":"default","level":"info","appender":"stderr"}
log-logger = {"name":"p2p","level":"warn","appender":"p2p"}
backtrace = yes
plugin = witness account_by_key
history-disable-pruning = 0
account-history-rocksdb-path = "blockchain/account-history-rocksdb-storage"
block-data-export-file = NONE
block-log-info-print-interval-seconds = 86400
block-log-info-print-irreversible = 1
block-log-info-print-file = ILOG
shared-file-dir = "$sharedfiledir"
shared-file-size = 64G
shared-file-full-threshold = 0
shared-file-scale-rate = 0
follow-max-feed-size = 500
follow-start-feeds = 0
market-history-bucket-size = [15,60,300,3600,86400]
market-history-buckets-per-size = 5760
p2p-seed-node = steem-seed1.abit-more.com:2001 52.74.152.79:2001 seed.steemd.com:34191 anyx.co:2001 seed.xeldal.com:12150 seed.steemnodes.com:2001 seed.liondani.com:2016 gtg.steem.house:2001 seed.jesta.us:2001 steemd.pharesim.me:2001 5.9.18.213:2001 lafonasteem.com:2001 seed.rossco99.com:2001 steem-seed.altcap.io:40696 seed.roelandp.nl:2001 steem.global:2001 seed.esteem.ws:2001 seed.timcliff.com:2001 104.199.118.92:2001 seed.steemviz.com:2001 steem-seed.lukestokes.info:2001 seed.steemian.info:2001 seed.followbtcnews.com:2001 node.mahdiyari.info:2001 seed.curiesteem.com:2001 seed.riversteem.com:2001 seed1.blockbrothers.io:2001 steemseed-fin.privex.io:2001 seed.jamzed.pl:2001 seed1.cryptobot.news:2001 seed.thecryptodrive.com:2001 seed.brandonfrye.us:2001 seed.firepower.ltd:2001
statsd-batchsize = 1
tags-start-promoted = 0
tags-skip-startup-update = false
webserver-thread-pool-size = 32
enable-stale-production = false
required-participation = 33
witness = "$wituser"
private-key=$key 

EOF

echo 'Downloading blocklog from gtg.steem.house/get/blockchain/ ... (THIS MIGHT TAKE A LONG TIME)'
cd /home/$whoami/.steemd/blockchain/
wget https://gtg.steem.house/get/blockchain/block_log

#Reown everything to user
chown -R $whoami:$whoami /home/$whoami

#Make user a sudo user
usermod -aG sudo username

#Disable root login, if selected yes
if [[ ("$disableroot" == "y" || "$disableroot" == "Y") ]]; then
  printf '\n%s\n' 'PermitRootLogin no' >>/etc/ssh/sshd_config
fi

cd /home/$whoami
su $whoami

echo "Starting Screen (Steemd), and starting witness node with --replay-blockchain"
screen -S Steemd -dm steem/programs/steemd/steemd --replay-blockchain


if [[ ("$conductor_install" == "y" || "$conductor_install" == "Y") ]]; then
  echo 'Installing and Setting up and running conductor pricefeed and failover switch'
  pip3 install -U git+git://github.com/Netherdrake/steem-python
  pip3 install -U git+https://github.com/Netherdrake/conductor
  printf '$activekey\nwalletpass\nwalletpass\n\n' | steempy addkey
  printf '$wituser\ny\nhttps://steemit.com/@$wituser\n\n\n\nwalletpass\n' | conductor init
  
  screen -S feed -dm conductor feed
  screen -S switchover -dm conductor kill-switch -n 2
  
  #Delete bash history afterwards to make the adding key operation safe.
  printf '$whoamipass\n' | sudo cat /dev/null > ~/.bash_history
  
fi


echo "Installation complete, Steemd node and everything else should now be up and running!"
