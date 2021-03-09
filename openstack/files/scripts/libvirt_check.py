#!/usr/bin/env python

import os
import sys
from time import sleep
import libvirt

import logging



# Create logger, console handler and formatter
logger = logging.getLogger("Libvirt connection check")
logger.setLevel(logging.DEBUG)
ch = logging.StreamHandler()
ch.setLevel(logging.DEBUG)
formatter = logging.Formatter("%(asctime)s - %(name)s - %(levelname)s - %(message)s")

# Set the formatter and add the handler
ch.setFormatter(formatter)
logger.addHandler(ch)


sleep_time = 1
tries = 60
for i in range(tries):
    try:
        conn = libvirt.open('qemu+tcp://127.0.0.1/system')
        result = conn.listDomainsID()
        conn.close()
        logger.info("Tested connection to libvirt {0}".format(result))
    except:
        logger.info(
            "Could not connect to libvirt, attempt {0} of {1}".format(
                 (i + 1), tries
            )
        )
        if i < tries - 1:
            sleep(sleep_time)
            continue
        else:
            logger.critical("Could not connect to libvirt")
            raise
    break

logger.info("Finished Libvirt connection Check")

