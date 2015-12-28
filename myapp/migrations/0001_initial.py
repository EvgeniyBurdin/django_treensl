# -*- coding: utf-8 -*- 
from __future__ import unicode_literals

from django.db import migrations, models

from myapp.models import Group as GroupModel # add after makemigrations

class Migration(migrations.Migration):

    dependencies = [
                    ('treensl', '0001_initial'), # add after makemigrations
    ]

    operations = [
        migrations.CreateModel(
            name='Group',
            fields=[
                ('lvl', models.IntegerField()),
                ('created_children', models.IntegerField()),
                ('removed_children', models.IntegerField()),
                ('id', models.BigIntegerField(primary_key=True, serialize=False)),
                ('namenode', models.CharField(max_length=100, blank=True)),
                ('parent', models.ForeignKey(to='myapp.Group')),
            ],
            options={
                'abstract': False,
            },
        ),
        migrations.RunSQL(GroupModel.sql_end(GroupModel)), # add after makemigrations
    ]
