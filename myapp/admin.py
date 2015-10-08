from django.contrib import admin
from .models import Group

# настраиваем показ таблицы в адм. интерфейсе
class GroupAdmin(admin.ModelAdmin):
    list_display = ('label_node_for_adminterface', 'parent',) # поля, показываемые в админке
    ordering = ('id',)

    fieldsets = [
        ('Поля для "Групп"',
         {'fields': ['parent', 'label_node', ]}),
    ]

admin.site.register(Group, GroupAdmin)



