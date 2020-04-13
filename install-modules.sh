#!/bin/bash

database=""
container=""
debug="0"

function help() {
    cat << EOF
Usage: install-modules.sh -d DATABASE -c DOCKER_CONTAINER [ -f ENVIRONMENT_FILE ] [-v] [-h]
Installs Odoo modules in stdin in docker container DOCKER_CONTAINER with parameters in ENV_FILE in DATABASE.
Modules in stdin must be one per line. 
ARGUMENTS:
    -d, --database		Database where to install modules. Mandatory.       
    -c, --docker_container	Odoo container where we're installing modules. Mandatory.
    -f, --env_file		Environment file with pgsql parametres. Optional.
    -v, --debug			Shows debug info. 
    -h, --help			Shows this message.

ENVIRONMENT VARIABLES:
    - HOST: database container alias or host. Default db.
    - PORT: database port. Default 5432.
    - USER: user to connect to database. Default odoo.
    - PASSWORD: password for USER. Default odoo.

Example:
cat modules.txt | ./install-modules.sh -d test -c godoo12_web_1 -f odoo.env

EOF
}


# now enjoy the options in order and nicely split until we see --
while [ $# -ge 1 ]
do
    case "$1" in
        -h|--help)
            help
            exit 0
            ;;
        -v|--debug)
            debug="1"
	    shift 1
            ;;
        -d|--database)
            database="$2"
            shift 2
            ;;
        -c|--docker_container)
            container="$2"
            shift 2
            ;;
        -f|--env_file)
	    file="$2"
            shift 2
            ;;
        *)
            help
            echo -e "\n\nUnkown argument."
            exit 1
            ;;
    esac
done
if [ -z "$database" ]
then
    help
    echo -e "\n\nMissing database argument."
    exit 1
fi

if [ -z "$container" ]
then
    help
    echo -e "\n\nMissing container argument."
    exit 1
fi
if [ ! -z "$file" ]
then
    source "$file" # Get passwords
fi

# Get parameters if not defined previously.

: ${HOST:=${DB_PORT_5432_TCP_ADDR:='db'}}
: ${PORT:=${DB_PORT_5432_TCP_PORT:=5432}}
: ${USER:=${DB_ENV_POSTGRES_USER:=${POSTGRES_USER:='odoo'}}}
: ${PASSWORD:=${DB_ENV_POSTGRES_PASSWORD:=${POSTGRES_PASSWORD:='odoo'}}}

while read line
do
  modlist="$modlist,${line}"
done < "/dev/stdin"

modlist="${modlist:1}"

if [ "$debug" == "1" ]; then
   echo "host: $HOST"
   echo "port: $PORT"
   echo "user: $USER"
   echo "password: $PASSWORD"
   echo "database: $database"
   echo "container: $container"
   echo "module list: $modlist "
fi

docker exec -t $container \
	/usr/bin/python3 /usr/bin/odoo \
	--db_host ${HOST} \
	--db_port ${PORT} \
	--db_user ${USER} \
	--db_password ${PASSWORD} \
	--init=${modlist} \
	--database=${database} \
	--stop-after-init
