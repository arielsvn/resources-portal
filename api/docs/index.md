# resources_portal

[![Build Status](https://travis-ci.org/ccdl/resources_portal.svg?branch=master)](https://travis-ci.org/ccdl/resources_portal)
[![Built with](https://img.shields.io/badge/Built_with-Cookiecutter_Django_Rest-F7B633.svg)](https://github.com/agconti/cookiecutter-django-rest)

Resources Portal. Check out the project's [documentation](http://ccdl.github.io/resources_portal/).

# Prerequisites

- [Docker](https://docs.docker.com/docker-for-mac/install/)

# Initialize the project

Start the dev server for local development:

```bash
docker-compose up
```

Create a superuser to login to the admin:

```bash
docker-compose run --rm web ./manage.py createsuperuser
```

# Making migrations

```bash
docker-compose run --rm web ./manage.py makemigrations resources_portal
```

# Visualizing the data model

This project includes [django-extensions graph_models command](https://django-extensions.readthedocs.io/en/latest/graph_models.html).

```bash
docker-compose run --rm web ./manage.py graph_models -a -g > model.dot
```

At the moment png exports are not setup but these can be generated from the `.dot` file.
(Either with `dot -Tpng model.dot -o database_diagram.png` or https://convertio.co/dot-png/)

![database-diagram](/database_diagram.png)
