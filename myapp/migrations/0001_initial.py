# -*- coding: utf-8 -*-
from __future__ import unicode_literals

from django.db import models, migrations

from myapp.models import Group as new_model # add after makemigrations


class Migration(migrations.Migration):

    dependencies = [
        ('treensl', '0001_initial'), # add after makemigrations
    ]

    operations = [
        migrations.CreateModel(
            name='Group',
            fields=[
                ('id', models.BigIntegerField(serialize=False, primary_key=True)),
                ('lvl', models.IntegerField()),
                ('created_children', models.BigIntegerField()),
                ('removed_children', models.BigIntegerField()),
                ('name', models.CharField(max_length=100, blank=True)),
                ('parent', models.ForeignKey(to='myapp.Group')),
            ],
            options={
                'abstract': False,
            },
        ),
        migrations.RunSQL(new_model.sql_end(new_model)), # add after makemigrations
    ]
