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

You need nodejs and npm. (tested with node v0.10.24 ).

1. instlal dependencies via `npm install`
2. run `grunt` to convert coffeescript files
3. start `aws-setup`

