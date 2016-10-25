Wercker step to deploy aws ecs services
=======================================

tamtam-pro/aws-ecs step is a very simple bash script using aws cli to deploy ecs services, please feel free to fork and modify it for your specific needs.

**You must be familiar with docker, aws ec2, to be able to use ecs([EC2 Container Service](http://docs.aws.amazon.com/AmazonECS/latest/developerguide/Welcome.html))**

`NB: This step can be used to deploy ecs services only`

## Requirements
* `py-pip`>= 1.5.6
* `awscli` >= 1.10.8
* `GNU Bash`
* `jq` command-line JSON processor

`NB: All requirements above are already bundled in tamtamp/aws-cli box`


## Example
```yml
deploy-to-dev:
    box: tamtamp/aws-cli
    steps:
    -  tamtam-pro/aws-ecs :
        key: aws-secret-access-key-id
        secret: aws-secret-access-key
        region: aws-region
        cluster: cluster-name
        service: service-name
        desired-count: 1 #numbre of instances to run of this service
        task-definition: task-definition-name #task definition family
        task-definition-file: $WERCKER_SOURCE_DIR/task-definition-name.json #path to your task definition file
```
`NB: All this parameters are required`

### More about task definition
Run this command to get latest task-definition syntax
```sh
aws ecs register-task-definition --generate-cli-skeleton
```

If your are new to aws ecs please refer to the folowing links

[Task deifnition parameters] (http://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html)

[Task definition example]
(http://docs.aws.amazon.com/AmazonECS/latest/developerguide/example_task_definitions.html)

## How it works
* First: it tries to register a new task-definition and retrieve the new task revision.
* Second: it downscales `service-name` to 0 instance and wait until the `running count` return 0.
* Third: it updates `service-name`by new task revision and new `desired-count` instances. If update command return ok, it waits until the `running count` match `desired-count`.
* Last: it checks if the service has reached a steady state.
