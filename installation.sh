COLOR="\033[1;33m"
SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

echo -e "${COLOR}"
echo "
   ___   _  _____   ____  __  ______________  ___  ____  ______
  / _ | / |/ / _ | / __/  \ \/ / __/ __/ __ \/ _ \/ __ \/_  __/
 / __ |/    / __ |/ _/     \  / _/_\ \/ /_/ / // / /_/ / / /
/_/ |_/_/|_/_/ |_/_/       /_/___/___/\____/____/\____/ /_/

  ____   ____   ___    _____________   __  ___
 / / /  |_  /  / _ \  /_  __/ __/ _ | /  |/  /
/_  _/ _/_ <  / // /   / / / _// __ |/ /|_/ / 
 /_/  /____/  \___/   /_/ /___/_/ |_/_/  /_/                                                                                                                                                                                     
"
# sleep 3
printf "\n"
echo "Hello dear installer"
printf "\n"
echo "Please make sure you have the followed softwares installed on this host."
echo "Without those softwares installed on this host, this installer won't work."
printf "\n"
echo "1. Docker Desktop - https://desktop.docker.com/win/stable/amd64/Docker%20Desktop%20Installer.exe"
echo "2. Git - https://git-scm.com/download/win"
printf "\n"
printf "While installing, this host must be connected to the internet."
printf "\n"
# sleep 3

# Check if docker is running
if ! docker info >/dev/null 2>&1; then
    printf "\nDocker Desktop is not running on this host.\nPlease launch and try again...\n\n"
    exit 1
fi
printf "\n\n\n\n"
read -p "Please provide this host's STATIC IP (on production network): " firsthostip
read -p "Please retype this host's IP Address for confirmation: " secondhostip
if [ $firsthostip == $secondhostip ]
then
  HOST_IP=$firsthostip
  [ ! -d "${SCRIPTPATH}/rozen" ] && {git clone https://github.com/rozenpro/rozen.git}&> /dev/null
  # CHANGE HOST IP IN DOCKER COMPOSE
  COMPOSE_LINE="ROOT_URL=http://ishare:80"
  SED_FORAMATTED=$(echo "$COMPOSE_LINE" | sed 's/\//\\\//g')
  sed -i '19s/.*/      - '$SED_FORAMATTED'/g' ${SCRIPTPATH}/rozen/rocket/docker-compose.yml
  # CHANGE JITSI .ENV CONFIG FILE
  COMPOSE_LINE="PUBLIC_URL=https://${HOST_IP}:8443"
  SED_FORAMATTED=$(echo "$COMPOSE_LINE" | sed 's/\//\\\//g')
  sed -i '45s/.*/'$SED_FORAMATTED'/g' ${SCRIPTPATH}/rozen/jitsi/.env
  # CHANGE WINDOWS HOSTS FILE
  printf "\n${HOST_IP}    xmpp.meet.jitsi" >> "C:\Windows\System32\drivers\etc\hosts"
  printf "\n${HOST_IP}    ishare" >> "C:\Windows\System32\drivers\etc\hosts"
  printf "\n${HOST_IP}:8443    meet.jit.si" >> "C:\Windows\System32\drivers\etc\hosts"
  printf "\nKilling all previous versions that might be running on this host ..."
  {
    docker compose -f ${SCRIPTPATH}/rozen/rocket/docker-compose.yml down
    docker compose -f ${SCRIPTPATH}/rozen/jitsi/docker-compose.yml down
    docker rm -f $(docker ps -q)
    docker rmi -f $(docker images -a)
    docker volume rm -f $(docker volume ls)
  } &> /dev/null
  printf "\nLaunching RocketChat And Jitsi ..."
  {
    docker compose -f ${SCRIPTPATH}/rozen/rocket/docker-compose.yml up -d
    docker compose -f ${SCRIPTPATH}/rozen/jitsi/docker-compose.yml up -d
  } &> /dev/null
  printf "\033c"
  echo -e "${COLOR}"
  printf "\nInstallation completed successfully !"
  sleep 2
  printf "\nThe Application Might Take Some Time To Start.."
  sleep 2
  printf "\n\nYou Can Access The Application On http://${HOST_IP} Or The Alias http://ishare/\n\n\n"
  sleep 5
else
  printf "\nIP Address Confirmation Failed..\nPlease Try Again\n\n"
fi