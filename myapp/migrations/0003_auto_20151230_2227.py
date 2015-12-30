# -*- coding: utf-8 -*-
from __future__ import unicode_literals

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('myapp', '0002_ads'),
    ]

    operations = [
        migrations.RenameField(
            model_name='ads',
            old_name='next_ads',
            new_name='text_ads',
        ),
    ]
