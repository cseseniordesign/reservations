while getopts u:p: flag
do 
    case "${flag}" in
        u) username=${OPTARG};;
        p) password=${OPTARG};;
    esac
done
echo "{\"database\":{\"adapter\":\"mysql2\",\"host\":\"cse.unl.edu\",\"username\":\"$username\",\"password\":\"$password\",\"database\":\"reservation\"}}" > config/server.json