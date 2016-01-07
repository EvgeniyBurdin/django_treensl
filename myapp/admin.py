# -*- coding: utf-8 -*-
from django.contrib import admin
from .models import Group, SimpleAd


class GroupAdmin(admin.ModelAdmin):
    list_display = ('name_for_admin', 'parent',)  # поля, показываемые в админке
    ordering = ('id',)

    fieldsets = [
        ('Поля для "Групп"',
         {'fields': ['parent', 'namenode', ]}),
    ]


class SimpleAdAdmin(admin.ModelAdmin):
    list_display = ('parent', 'header_ad', 'text_ad')

admin.site.register(Group, GroupAdmin)
admin.site.register(SimpleAd, SimpleAdAdmin)
