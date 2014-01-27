#bookr-aws

##What

bootstrapping to deploy all bookr components to aws
```

        _/                            _/                                        _/  _/
       _/_/_/      _/_/      _/_/    _/  _/    _/  _/_/                _/_/_/  _/     
      _/    _/  _/    _/  _/    _/  _/_/      _/_/      _/_/_/_/_/  _/        _/  _/  
     _/    _/  _/    _/  _/    _/  _/  _/    _/                    _/        _/  _/   
    _/_/_/      _/_/      _/_/    _/    _/  _/                      _/_/_/  _/  _/    

    Bootstraps AWS environment for bookr components. Version 1.0

Options:
  --all               run all tasks
  --create-db-sec     creates the database security group
  --create-web-sec    creates the web security group
  --launch-db         launches database instance
  --ops-api           adds opsworks configuration for api stack, layer
  --ops-api-instance  adds opsworks configuration for api instance
  --lb-api            adds opsworks HAProxy configuration for api
  --launch-api        launches api instance
  --launch-lb         launches loadbalancer instance
  --add-api-db-sec    adds the api ip to database security group
  --deploy-api        deployes api application to api instance
  --ops-web           adds opsworks configuration for webclient
  --launch-web        launches web instance
  --deploy-web        deployes web application to web instance
  
```

##Setup

###AWS IAM/ARN settings


- this app uses a service role that needs `Trusted Entities: The service opsworks.amazonaws.com`
- this app uses an instance role that needs `Trusted Entities: The service ec2.amazonaws.com`

Here's a working IAM/ARN setup for instance role and service role:

![EC2 instance profile arn](https://raw.github.com/makepanic/bookr-aws/master/pics/iam-aws-ec2.png)

![Opsworks service role arn](https://raw.github.com/makepanic/bookr-aws/master/pics/iam-aws-opsworks.png)

__PSA: This tool should work with the shown config but I can't promise it.
I don't have full access to the aws account that was given to me.
Before using it try to check that your user has ec2 and opsworks permissions.__


###Tool related

0. Change instance size in `aws-setup.json` if you need to
1. Add your aws credentials to `aws-credentials.json`
2. Add your service-role-arn to `aws-setup.json` for api and web.
    Example: `"service-role-arn": "arn:aws:iam::000000000000:role/aws-opsworks-service-role"`
3. Add your default-instance-profile-arn to `aws-setup.json` for api and web.
    Example: `"default-instance-profile-arn": "arn:aws:iam::000000000000:instance-profile/aws-opsworks-ec2-role"`
4. Add your isbndb api-key to `aws-setup.json` in `opsworks.customChef.isbndb`
    Example:
```
"customChef": {
  "bookr": {
    "api": "",
    "server": "",
    "isbndb": "12345678"
  }
}
```

###Local nodejs

You need nodejs, npm and grunt. (tested with node v0.10.24 ).

1. install dependencies via `npm install`
2. run `grunt` to convert coffeescript files
3. start `aws-setup` (`node aws-setup.js --all`)

###Vagrant

If you don't want to use/install nodejs locally there is a Vagrantfile that uses [Vagrant](http://www.vagrantup.com/)
to provide a virtual machine with everything that is required to run this app.

1. run `vagrant up`
2. if everything is done call `vagrant ssh`
3. cd to `/vagrant`
4. run `grunt`
5. start `aws-setup` (`node aws-setup.js --all`)

##Architecture

In the end this tool is just a collection of aws sdk wrappers bound to commandline flags.
It stores the result in the `aws-setup.json` file. This allows some neat tricks (see __useful commands__).
Each component reads data from the config file.

##Useful commands

- for scaling add a new api instance and register with everybody: `node aws-setup.js --ops-api-instance --launch-api --add-api-db-sec --deploy-api`
