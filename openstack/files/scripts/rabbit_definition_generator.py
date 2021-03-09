#!/usr/bin/env python
import json
import hashlib
import binascii
import secrets
import os
import argparse
import logging
import yaml

# Create logger, console handler and formatter
logger = logging.getLogger("RabbitMQ definition file generator")
logger.setLevel(logging.DEBUG)
ch = logging.StreamHandler()
ch.setLevel(logging.DEBUG)
formatter = logging.Formatter("%(asctime)s - %(name)s - %(levelname)s - %(message)s")

# Set the formatter and add the handler
ch.setFormatter(formatter)
logger.addHandler(ch)

parser = argparse.ArgumentParser(
    description="Generate a rabbitmq definitions.file.json with hashed passwords from raw input snippets"
)
parser.add_argument(
    "--search-dir",
    dest="search_dir",
    default="/tmp/snippets",
    help="directory to search for yaml snippets (default: /tmp/snippets)",
)
parser.add_argument(
    "--output",
    dest="output_location",
    default="/tmp/definitions.file.json",
    help="ouptut location (default: /tmp/definitions.file.json)",
)
args = parser.parse_args()


def encode_rabbit_password_hash(salt, password):
    salt_and_password = salt + password.encode("utf-8").hex()
    salt_and_password = bytearray.fromhex(salt_and_password)
    salted_sha256 = hashlib.sha256(salt_and_password).hexdigest()
    password_hash = bytearray.fromhex(salt + salted_sha256)
    password_hash = binascii.b2a_base64(password_hash).strip().decode("utf-8")
    return password_hash


output = {}
output["users"] = []
output["vhosts"] = []
output["permissions"] = []

logger.info("Searching {0} directory for json snippets to use".format(args.search_dir))
for subdir, dirs, files in os.walk(args.search_dir):
    for filename in files:
        filepath = subdir + os.sep + filename
        if filepath.endswith(".yaml"):
            logger.info("Loading snippet from {0}".format(filepath))
            with open(filepath) as f:
                data = yaml.safe_load(f)
                hashed_users = []
                for i, user in enumerate(data["users"]):
                    user["password_hash"] = encode_rabbit_password_hash(
                        secrets.token_hex(4), user["password"]
                    )
                    user["hashing_algorithm"] = "rabbit_password_hashing_sha256"
                    del user["password"]
                    hashed_users.append(user)
                del data["users"]
                data["users"] = hashed_users
                output["users"].extend(data["users"])
                output["vhosts"].extend(data["vhosts"])
                output["permissions"].extend(data["permissions"])

logger.info("Writing out definition file to {0}".format(args.output_location))
definintion_file = open(args.output_location, "w")
definintion_file.write(json.dumps(output))
definintion_file.close()

logger.info("Finished Defininition file creation")
