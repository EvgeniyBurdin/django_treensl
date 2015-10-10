from django.contrib import admin
from .models import Group

# настраиваем показ таблицы в адм. интерфейсе
class GroupAdmin(admin.ModelAdmin):
    list_display = ('name_for_admin', 'parent',) # поля, показываемые в админке
    ordering = ('id',)

    fieldsets = [
        ('Поля для "Групп"',
         {'fields': ['parent', 'name', ]}),
    ]

admin.site.register(Group, GroupAdmin)



