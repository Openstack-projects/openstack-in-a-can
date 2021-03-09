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
    description="Extract a value from an ini file"
)
parser.add_argument(
    "--config-file",
    dest="config_file",
    help="location of the ini file",
)
parser.add_argument(
    "--section",
    dest="section",
    help="the section in the config file",
)
parser.add_argument(
    "--key",
    dest="key",
    help="the key in the config file",
)
args = parser.parse_args()

config = ConfigParser.RawConfigParser(**PARSER_OPTS)
config.read(args.config_file)
user_db_conn = config.get(args.section, args.key)

print(user_db_conn)
