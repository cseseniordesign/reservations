while getopts u:p: flag
do 
    case "${flag}" in
        u) username=${OPTARG};;
        p) password=${OPTARG};;
    esac
done
echo "user: $username, pass: $password"
echo "{\"database\":{\"adapter\":\"mysql2\",\"host\":\"cse.unl.edu\",\"username\":\"$username\",\"password\":\"$password\",\"database\":\"reservation\"}}" > config/config.json