# Resources Portal Infrstructure

The Resources Portal is configured to run in AWS.
You will need to have your AWS credentials configured or make them available as environment variables.

The configuration is written in [terraform](https://learn.hashicorp.com/terraform/getting-started/install.html).
You will need to have it installed to be able to deploy.

All commands from this README should be run from the `infrastructure/` directory.

## Deployment

Currently we do not have a staging or production stack, but a development stack can be deployed with:

```
python3 deploy.py -d [dockerhub-repo] -e dev -u [username] -v v0.0.0
```

You will need an `resources-portal-api:v0.0.0` image in the dockerhub-repo you supply. Run `python3 infrastructure/deploy.py -h` for more options.

Once your deployment is complete it will output the elastic_ip_address like:  `elastic_ip_address = X.X.X.X`
To make requests against the API that you deployed see the [READEME for the API](../api/README.md).

Subsequent deploys to the same stack will use the same elastic IP address.

## Teardown

You can destroy an existing stack with:
```
cd infrastructure && python3 destroy_terraform.py -e dev -u [username]
```

The username you use to destroy should match the one you supplied to `deploy.py`.
