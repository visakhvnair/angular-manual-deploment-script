# #!/bin/bash

ENV=$1
SKIP_BUILD=$2
PROJECT_LOCATION="<project-root-directory>"
RELATIVE_BUILD_LOCTION = "<build-location>"
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
reset=`tput sgr0`

SSH_KEY_PROD="<ssh-key-file-location>"
SSH_KEY_STAGING="<ssh-key-file-location>"
SSH_KEY_QA="<ssh-key-file-location>"

PROD_DESTINATION='<username>@<ip>:<root-directory>'
QA_DESTINATION='<username>@<ip>:<root-directory>'
STAG_DESTINATION="<username>@<ip>:<root-directory>"



if [ -z "$ENV" ]
    then
        echo "Please provide environment"
        exit
fi    

if [ "$ENV" == "prod" ]
    then

    while true; do
    read -p "Do you wish to deploy to prod?" yn
    case $yn in
        [Yy]* ) make install; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
    done

    SSH_KEY=$SSH_KEY_PROD
    DESTINATION=$PROD_DESTINATION
    BUILD_CMD="ng build"

fi

if [ "$ENV" == "staging" ]
    then
    SSH_KEY=$SSH_KEY_STAGING
    DESTINATION=$STAG_DESTINATION
    BUILD_CMD="ng build" 
fi

if [ "$ENV" == "qa" ]
    then
    SSH_KEY=$SSH_KEY_QA
    DESTINATION=$QA_DESTINATION
    BUILD_CMD="ng build"
fi


eval cd "$PROJECT_LOCATION"
if [ $? -eq 0 ]
    then
        echo -e "${green}\nChanged directory to Project location\n${reset}"

        eval cat src/assets/appconfig-"${ENV}".json > src/assets/appconfig.json 
        if [ $? -eq 0 ]
            then
                echo -e "${green}\nCopied ${ENV} config to config\n${reset}"
                if [ "$SKIP_BUILD" == 'skip' ]
                then
                    echo -e "${yellow}\nSkipping build\n${reset}"
                else
                    echo '' > ../last-build.log
                    echo -e "${yellow}\nBuilding... (Running ${BUILD_CMD} )\n${reset}"
                    
                    eval "${BUILD_CMD}" >> ../last-build.log 2>>../last-build.log
                    if [ $? -eq 0 ]
                        then
                        echo -e "${green}\nBuild success. Log file last-build.log \n${reset}"
                        
                    else
                        echo -e  "${red}\n!!!!!!!!!\nBuild Failed.Check last-build.log\n!!!!!!!!!\n${reset}"
                        exit
                    fi  
                fi  


                echo -e "${yellow}\nDeploying...\n${reset}"
                
                eval rsync -ave   \"ssh -p 4895 -i ${SSH_KEY}\"   ${PROJECT_LOCATION}${RELATIVE_BUILD_LOCTION}  "${DESTINATION}"  --delete > ../last-deployemt.log
                if [ $? -eq 0 ]
                then
                    echo -e "${green}\nDeployment success. Log file last-deployemt.log \n${reset}"
                else
                    echo -e  "${red}\n!!!!!!!!!\nDeployment Failed.Check last-deployemt.log\n!!!!!!!!!\n${reset}"
                    exit
                fi
                    
        else
            echo -e  "${red}\n!!!!!!!!!\nCopying config failed\n!!!!!!!!!\n${reset}"
            exit        
        fi
else
    echo -e  "${red}\n!!!!!!!!!\nChange directory failed\n!!!!!!!!!\n${reset}"
    exit 
fi    


echo -e "${yellow}\nResetting local config \n${reset}"
eval cat src/assets/appconfig-dev.json > src/assets/appconfig.json 
if [ $? -eq 0 ]
then
    echo -e "${green}\nReset config success\n${reset}"
else
    echo -e  "${red}\n!!!!!!!!!\nFailed to reset config.Please do it manually.\n!!!!!!!!!\n${reset}"
exit
fi   
