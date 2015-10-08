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
                ('id', models.BigIntegerField(primary_key=True, serialize=False)),
                ('lvl', models.IntegerField()),
                ('created_children', models.BigIntegerField()),
                ('removed_children', models.BigIntegerField()),
                ('label_node', models.CharField(blank=True, max_length=100)),
                ('rem', models.CharField(blank=True, max_length=100)),
                ('parent', models.ForeignKey(to='myapp.Group')),
            ],
            options={
                'abstract': False,
            },
        ),
        migrations.RunSQL(new_model.sql_end(new_model)), # add after makemigrations
    ]
