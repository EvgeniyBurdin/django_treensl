# -*- coding: utf-8 -*-
from __future__ import unicode_literals

from django.db import migrations

def load_stores_from_sql():
    #from django.conf import settings
    import os
    import treensl
    #sql_scripts = open(os.path.join(os.getcwd(),'treensl/sql_scripts/ini_postgres.sql'), 'r').read()
    #ini_sql = open(os.path.join(settings.BASE_DIR,'treensl/sql_scripts/ini_postgres.sql'), 'r').read()
    ini_sql = open(os.path.join(treensl.__path__[0],'sql_scripts/ini_postgres.sql' ), 'r').read()

    return ini_sql

class Migration(migrations.Migration):

    dependencies = [

    ]

    operations = [
        migrations.RunSQL(load_stores_from_sql()),
    ]
