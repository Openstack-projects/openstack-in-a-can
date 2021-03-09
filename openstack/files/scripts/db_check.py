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
from sqlalchemy import create_engine

parser = argparse.ArgumentParser(
    description="Check that the DB is up, and can be connected to by the openstack service user"
)
parser.add_argument(
    "--config-file",
    dest="config_file",
    help="location of the oslo.config file with an sqlalchemy connection string to test connectivity with",
)
parser.add_argument(
    "--db-section",
    dest="db_section",
    default="database",
    help="the section in the config file with the connection string (default: database)",
)
parser.add_argument(
    "--db-key",
    dest="db_key",
    default="connection",
    help="the key in the config file with the connection string (default: connection)",
)
args = parser.parse_args()

# Create logger, console handler and formatter
logger = logging.getLogger("DB connection check")
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
    logger.info("Using {0} as db config source".format(args.config_file))
    config.read(args.config_file)
    logger.info(
        "Trying to load db config from {0}:{1}".format(args.db_section, args.db_key)
    )
    user_db_conn = config.get(args.db_section, args.db_key)
    logger.info("Got config from {0}".format(args.config_file))
except:
    logger.critical(
        "Tried to load config from {0} but failed.".format(args.config_file)
    )
    raise
# User DB engine
try:
    user_engine = create_engine(user_db_conn)
    # Get our user data out of the user_engine
    database = user_engine.url.database
    user = user_engine.url.username
    password = user_engine.url.password
    logger.info("Got user db config")
except:
    logger.critical("Could not get user database config")
    raise

sleep_time = 1
tries = 60
for i in range(tries):
    try:
        connection = user_engine.connect()
        connection.close()
        logger.info("Tested connection to DB {0} as {1}".format(database, user))
    except:
        logger.info(
            "Could not connect to DB {0} as {1}, attempt {2} of {3}".format(
                database, user, (i + 1), tries
            )
        )
        if i < tries - 1:
            sleep(sleep_time)
            continue
        else:
            logger.critical("Could not connect to database as user")
            raise
    break

logger.info("Finished DB Check")
