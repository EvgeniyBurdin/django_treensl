# -*- coding: utf-8 -*-
from __future__ import unicode_literals

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('myapp', '0001_initial'),
    ]

    operations = [
        migrations.CreateModel(
            name='Ads',
            fields=[
                ('id', models.AutoField(auto_created=True, serialize=False, primary_key=True, verbose_name='ID')),
                ('header_ads', models.CharField(max_length=100)),
                ('next_ads', models.CharField(max_length=200)),
                ('parent', models.ForeignKey(to='myapp.Group')),
            ],
        ),
    ]
