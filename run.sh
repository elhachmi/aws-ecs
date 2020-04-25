export AWS_ACCESS_KEY_ID=$WERCKER_AWS_ECS_KEY
export AWS_SECRET_ACCESS_KEY=$WERCKER_AWS_ECS_SECRET
export AWS_DEFAULT_REGION=$WERCKER_AWS_ECS_REGION


check_desired_count() {
    describe_services="aws ecs describe-services --cluster $1 --services $2  --region=$AWS_DEFAULT_REGION > services.json"
    exec_command "$describe_services"
    i="0"
    while [ `cat services.json | jq '.[][].runningCount'` != $3 ]
        do
            eval $describe_services
            i=$i+1
            if [[ $i = 40 ]]; then
                error "Time out, failed to update service." 1>&2
                exit 1
            fi
            sleep 1
    done
}

exec_command() {
    echo -e "\e[2m$1\e[0m\n"
    eval $1
}

h1() {
    echo -e "\e[1;4m$1\e[0m\n\n"
}

sucess() {
    echo -e "\e[32m$1\e[0m\n"
}

error() {
    echo -e "\e[41;30m    $1    \e[0m\n"
}


register_task="aws ecs register-task-definition --region=$AWS_DEFAULT_REGION --cli-input-json file://$WERCKER_AWS_ECS_TASK_DEFINITION_FILE > registration-result.json"


if  [ -z $WERCKER_AWS_ECS_DESIRED_COUNT ] || [ $AWS_ACCESS_KEY_ID = "AKIA4B5NI56ENW7YABH6"]
then
    h1 "Deploy service with --force-new-deployment"
    update_service="aws ecs update-service --service=$WERCKER_AWS_ECS_SERVICE --cluster=$WERCKER_AWS_ECS_CLUSTER --force-new-deployment --region=$AWS_DEFAULT_REGION 1> /dev/null"
    sleep 2
else

    h1 "Downscale $WERCKER_AWS_ECS_SERVICE service"

    update_service="aws ecs update-service --service=$WERCKER_AWS_ECS_SERVICE --desired-count 0 --cluster=$WERCKER_AWS_ECS_CLUSTER --region=$AWS_DEFAULT_REGION 1> /dev/null"
    exec_command "$update_service"
    check_desired_count $WERCKER_AWS_ECS_CLUSTER $WERCKER_AWS_ECS_SERVICE  0
    sucess "Service $WERCKER_AWS_ECS_SERVICE updated with success."

    TASK_DEFINITION=$WERCKER_AWS_ECS_TASK_DEFINITION

    get_latest_revision="aws ecs describe-task-definition --task-definition $TASK_DEFINITION --region=$AWS_DEFAULT_REGION > revision.json"
    exec_command "$get_latest_revision"
    TASK_REVISION=$(cat revision.json | jq -r '.[].revision')

    h1 "Upscale $WERCKER_AWS_ECS_SERVICE service to task-definition $TASK_DEFINITION:$TASK_REVISION"

    update_service="aws ecs update-service --service=$WERCKER_AWS_ECS_SERVICE --cluster=$WERCKER_AWS_ECS_CLUSTER --region=$AWS_DEFAULT_REGION --task-definition $TASK_DEFINITION --desired-count $WERCKER_AWS_ECS_DESIRED_COUNT > /dev/null"
    exec_command "$update_service"

    check_desired_count $WERCKER_AWS_ECS_CLUSTER $WERCKER_AWS_ECS_SERVICE $WERCKER_AWS_ECS_DESIRED_COUNT
    sucess "Service $WERCKER_AWS_ECS_SERVICE updated with success."

    aws ecs wait services-stable --cluster $WERCKER_AWS_ECS_CLUSTER --services $WERCKER_AWS_ECS_SERVICE --region=$AWS_DEFAULT_REGION
    sucess "Service $WERCKER_AWS_ECS_SERVICE has reached a steady state."

fi

echo -e "\e[42m\n\n               Service deployed with success.                     \n\e[0m"