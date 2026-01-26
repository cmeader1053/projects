# Fortinet Firewall Backup Automation Project

## Description
 
Python project to automate Fortinet firewall backups. Various versions of the code have been uploaded as I continue to develop this project inside of a production environment. This is a work in progress as I continue learn python and apply my knowlegde to a real world application. 

## Getting Started

### Dependencies

* Install Python latest version on local machine/host
* Install the necessary libraries to local machine/host running scripts

### Installing

* Modify code to add unique information where you see {ENTER...}

## Executing 

* Version one is straight forward and requires user interaction
* Version two requires a REST API Admin to be created inside the Fortinet to generate an API token. This token is hard coded into the script which is NOT a security best practice. This was a learning experience for me using REST API tokens for the first time
* Version three has the most requirements but is by far not the finish product.
  1. Create AWS S3 bucket 
  2. Create IAM user in AWS and assign permissions to user - I found inline policies to be easier. See policies document
  3. Generate access and secret access key credentials for the IAM user. Store with API token in Secrets Manager
  4. Set Windows environment variables to the access and secret access key
* Version four introduces logging. Logs for script execution are now uploaded to a previously configured S3 bucket and local file path. Requires Logging python library.

All versions require the proper libraries to be installed. Utilzie pip to install libraries prior to script execution. 

Setting environment variables in Windows using Powershell
```
setx {ENV_VAR_NAME} "ENTER_ENV_VARIABLE"  # Set environment variable 

# Note - Close and open Powershell terminal to confirm variable is set

echo ${ENV_VAR_NAME} # Confirm that environment variable set
```

## Help

[Fortinet Rest API Admin](https://community.fortinet.com/t5/FortiGate/Technical-Tip-How-to-create-a-REST-API-Admin-user-and-assign-it/ta-p/247199) 

## Authors

Chris Meader 


## Version History

* v1
    * Initial code release
    * Requires user interaction
    * uses netmike library to form ssh tunnel to firewall
* v2
    * Still requires some user interaction
    * Leverages REST API Admin with token 
    * API token is hard coded
* v3
    * API token no longer hard coded 
    * Requires various AWS resources 
    * Requires use of environmental variables set inside Windows
* v4
    * Introduces logging with the use of logging libraries.
    * Log files stored both locally and in S3
    * Continues to require use of environmental variables 

## License

N/A

## Acknowledgments

This is a work in progress as I learn Python and apply my knowledge to real world problems
