#!/usr/bin/env python
# NOTE (Portdirect): This file is required to support Horizon regardless of the
# image used, and to provide PyMySQL support.

import os
import sys

import pymysql

pymysql.version_info = (1, 3, 13, "final", 0)
pymysql.install_as_MySQLdb()

from django.core.management import execute_from_command_line

if __name__ == "__main__":
    os.environ.setdefault("DJANGO_SETTINGS_MODULE", "openstack_dashboard.settings")
    execute_from_command_line(sys.argv)
