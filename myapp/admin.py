# -*- coding: utf-8 -*-
from django.contrib import admin
from .models import Group, Ads

# настраиваем показ таблицы в адм. интерфейсе
class GroupAdmin(admin.ModelAdmin):
    list_display = ('name_for_admin', 'parent',) # поля, показываемые в админке
    ordering = ('id',)

    fieldsets = [
        ('Поля для "Групп"',
         {'fields': ['parent', 'namenode', ]}),
    ]
    
class AdsAdmin(admin.ModelAdmin):
    list_display = ('parent', 'header_ads', 'text_ads')

admin.site.register(Group, GroupAdmin)
admin.site.register(Ads, AdsAdmin)



