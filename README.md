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
  --all             run all tasks                             
  --create-db-sec   creates the database security group       
  --create-web-sec  creates the web security group            
  --add-api-db-sec  adds the api ip to database security group
  --launch-db       launches database instance                
  --ops-api         adds opsworks configuration for api       
  --launch-api      launches api instance                     
  --deploy-api      deployes api application to api instance  
  --ops-web         adds opsworks configuration for webclient 
  --launch-web      launches web instance                     
  --deploy-web      deployes web application to web instance  
  
```

##Setup

1. Add your aws credentials to `aws-credentials.json`
2. Add your service-role-arn to `aws-setup.json` for api and web.
    Example: `"service-role-arn": "arn:aws:iam::000000000000:role/opsworks-role"`
3. Add your default-instance-profile-arn to `aws-setup.json` for api and web.
    Example: `"default-instance-profile-arn": "arn:aws:iam::000000000000:instance-profile/opsworks-role"`
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
3. start `aws-setup`

###Vagrant

If you don't want to use/install nodejs locally there is a Vagrantfile that uses [Vagrant](http://www.vagrantup.com/)
to provide a virtual machine with everything that is required to run this app.

1. run `vagrant up`
2. if everything is done call `vagrant ssh`
3. cd to `/vagrant`
4. run `grunt`
5. start `aws-setup`