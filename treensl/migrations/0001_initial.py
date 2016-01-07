# -*- coding: utf-8 -*-
from __future__ import unicode_literals
from django.db import migrations


def load_stores_from_sql():
    import os
    import treensl
    ini_sql = open(os.path.join(treensl.__path__[0],
                                'sql_scripts/ini_postgres.sql'
                                ), 'r', newline='', encoding='utf-8'
                   ).read()
    return ini_sql


class Migration(migrations.Migration):

    dependencies = [

    ]

    operations = [
        migrations.RunSQL(load_stores_from_sql()),
    ]
