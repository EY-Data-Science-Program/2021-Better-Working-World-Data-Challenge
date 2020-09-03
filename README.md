# Cube in a Box

The Cube in a Box is a simple way to run the [Open Data Cube](https://opendatacube.com).

## How to use locally

If you have `make`:

* Start a local environment using `make up`
* Set up your local postgres database (after the above has finished) using `make initdb`
* Add the Sentinel-2 metadata and product definitions by with `make metadata` and `make product`
* Index a default region with `make index`
* View the Jupyter notebook at [http://localhost](http://localhost) using the password `secretpassword`

If you don't have make, you can inspect the [Makefile](Makefile) for the commands that are needed to be executed.

## Deploying to AWS

To deploy to AWS, you can either do it on the command line, with the AWS command line installed or the magic URL below and the AWS console. Detailed instructions are [available](docs/Detailed_Install.md).

Once deployed, if you navigate to the IP of the deployed instance, you can access Jupyter with the password you set in the parameter in the AWS UI. Or you can SSH into the instance using the IP address and the SSH key you set.

## Magic Links

### AWS

[Launch a Cube in a Box](https://console.aws.amazon.com/cloudformation/home?#/stacks/new?stackName=cube-in-a-box&templateURL=http://opendatacube-cube-in-a-box.s3.amazonaws.com/cube-in-a-box-dea-cloudformation.yml)

You need to be logged in to the AWS Console deploy using this URL. Once logged in, click the link, and follow the prompts including settings a bounding box region of interest, EC2 instance type and password for Jupyter.


### Azure

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%sFcodeindulgence%sFcube-in-a-box-dea%sFmain%sFcube-in-a-box-dea-azurerm.json)

## Command line

* Alter the parameters in the [parameters.json](./parameters.json) file
* Run `make create-infra`
