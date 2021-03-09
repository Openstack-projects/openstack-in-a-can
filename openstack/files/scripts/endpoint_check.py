#!/usr/bin/env python

import os
import sys
import argparse
from time import sleep

try:
    import ConfigParser

    PARSER_OPTS = {}
except ImportError:
    import configparser as ConfigParser

    PARSER_OPTS = {"strict": False}

import logging

import requests

from keystoneclient.v3 import client
from keystoneauth1.identity import v3
from keystoneauth1 import session
from keystoneclient.v3 import client


parser = argparse.ArgumentParser(description="Check that an endpoint is up")
parser.add_argument(
    "--config-file",
    dest="config_file",
    help="location of the oslo.config file which contains a keystone_auth section",
)
parser.add_argument(
    "--service",
    dest="check_service",
    help="the section in the config file with the connection string (default: database)",
)
parser.add_argument(
    "--interface",
    dest="check_interface",
    default="public",
    help="the key in the config file with the connection string (default: connection)",
)
args = parser.parse_args()

# Create logger, console handler and formatter
logger = logging.getLogger("Keystone Endpoint connection check")
logger.setLevel(logging.DEBUG)
ch = logging.StreamHandler()
ch.setLevel(logging.DEBUG)
formatter = logging.Formatter("%(asctime)s - %(name)s - %(levelname)s - %(message)s")

# Set the formatter and add the handler
ch.setFormatter(formatter)
logger.addHandler(ch)

# Get the connection string for the service db
try:
    config = ConfigParser.RawConfigParser(**PARSER_OPTS)
    logger.info("Using {0} as keystone auth config source".format(args.config_file))
    config.read(args.config_file)
    auth_url = config.get("keystone_authtoken", "auth_url")
    username = config.get("keystone_authtoken", "username")
    password = config.get("keystone_authtoken", "password")
    project_name = config.get("keystone_authtoken", "project_name")
    user_domain_name = config.get("keystone_authtoken", "user_domain_name")
    project_domain_name = config.get("keystone_authtoken", "project_domain_name")
    cafile = config.get("keystone_authtoken", "cafile")
    logger.info("Got config from {0}".format(args.config_file))
except:
    logger.critical(
        "Tried to load config from {0} but failed.".format(args.config_file)
    )
    raise

auth = v3.Password(
    auth_url=auth_url,
    username=username,
    password=password,
    project_name=project_name,
    user_domain_name=user_domain_name,
    project_domain_name=project_domain_name,
)

sess = session.Session(auth=auth, verify=cafile)

sleep_time = 1
tries = 600
for i in range(tries):
    try:
        keystone = client.Client(session=sess)

        service = keystone.services.list(type=args.check_service)[0]
        url = keystone.endpoints.list(
            service=service.id, interface=args.check_interface
        )[0].url

        result = requests.get(url, verify=cafile)
        if result.status_code == 503:
            raise

        logger.info(
            "Tested connection to the {0} service via the {1} interface, getting the result '{2}'".format(
                args.check_service, args.check_interface, result
            )
        )
    except:
        logger.info(
            "Could not connect to the {0} service via the {1} interface, attempt {2} of {3}".format(
                args.check_service, args.check_interface, (i + 1), tries
            )
        )
        if i < tries - 1:
            sleep(sleep_time)
            continue
        else:
            logger.critical(
                "Could not connect to the {0} service via the {1} interface".format(
                    args.check_service, args.check_interface
                )
            )
            raise
    break

logger.info("Finished Keystone Endpoint Check")