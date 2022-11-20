while getopts u:p:c:s: flag
do 
    case "${flag}" in
        u) username=${OPTARG};;
        p) password=${OPTARG};;
        c) site=${OPTARG};;
        s) secret=${OPTARG};;
    esac
done
echo "{\"database\":{\"adapter\":\"mysql2\",\"host\":\"cse.unl.edu\",\"username\":\"$username\",\"password\":\"$password\",\"database\":\"reservation\"},\"reCaptcha\":{\"site_key\":\"$site\",\"secret_key\":\"$secret\"}}" > config/server.json