FROM python:3.8
ENV PYTHONUNBUFFERED 1

RUN groupadd user && useradd --create-home --home-dir /home/user -g user user
WORKDIR /home/user

# Allows docker to cache installed dependencies between builds
COPY ./requirements.txt requirements.txt
RUN pip install -r requirements.txt

# Adds our application code to the image
COPY . .

# uWSGI
RUN chmod +x /home/user/collect_and_run_uwsgi.sh

RUN mkdir -p /tmp/www/static
RUN chown user /tmp/www/static

ARG SYSTEM_VERSION
ARG PORT

ENV SYSTEM_VERSION $SYSTEM_VERSION

USER user

# We collect Django's static files and expose them
# as a volume so that Nginx can serve them directly.
VOLUME /tmp/www/static

EXPOSE $PORT

# Run the production server
CMD newrelic-admin run-program gunicorn --bind 0.0.0.0:$PORT --access-logfile - resources_portal.wsgi:application
