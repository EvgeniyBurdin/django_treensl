# -*- coding: utf-8 -*-
from django.db import models

# Этот скрипт необходимо выполнять во всех иерархических таблицах-наследниках
# путем добавления в миграции вашего приложения migrations.RunSQL()
# Пример в myapp/migranions/0001_initial.py
POSTGRESQL_CONNECT_TABLE = '''-- тестировал в БД PostgreSQL 9.1 и выше

-- Добавляем поле-массив которое хранит "дырки"
ALTER TABLE  {0} ADD COLUMN holes integer[];

-- Начальный элемент дерева
INSERT INTO {0} ({1}) VALUES {2};

-- Имя таблицы и Размерность нового дерева
INSERT INTO tree_size (table_name, number_of_levels, number_of_children)
               VALUES ('{0}', {3}, {4});

-- Теперь можно подключить триггерные функции
CREATE TRIGGER after_upd
  AFTER UPDATE
  ON {0}
  FOR EACH ROW
  EXECUTE PROCEDURE {5};

CREATE TRIGGER before_del
  BEFORE DELETE
  ON {0}
  FOR EACH ROW
  EXECUTE PROCEDURE {6};

CREATE TRIGGER before_new
  BEFORE INSERT
  ON {0}
  FOR EACH ROW
  EXECUTE PROCEDURE {7};
'''


class TreeAbstract(models.Model):
    
    lvl = models.IntegerField(blank=False, null=False)
    created_children = models.IntegerField(blank=False, null=False)
    removed_children = models.IntegerField(blank=False, null=False)

    # Количество детей
    @property
    def count_children(self):
        return self.created_children - self.removed_children

    class Meta:
        abstract = True

    def sql_end(self):

        # В определении модели, поле 'parent_id',названо как 'parent'
        # Но, так как это поле ссылка на 'id', Django в БД его пишет как 'parent_id'
        # Создадим списки полей абстрактой модели и их значений для первой строки (1-й элемент)
        # (1-й элемент в таблице, хранящей дерево, ссылается сам на себя)
        list_fields = ['id', 'parent_id', 'lvl', 'created_children',
                       'removed_children']
                    #'removed_children', 'label_node']
        #list_values = [self.ROOT_ID, self.ROOT_ID, 0, 0, 0,'root']
        list_values = [self.ROOT_ID, self.ROOT_ID, 0, 0, 0]
        # Наследник модели может иметь свои дополнительные поля, и они могут быть NOT NULL
        # Необходимо вставить начальный элемент дерева, с учетом этого
        # То есть, заполнить такие поля каким-либо значением
        # (0 - подходит для полей всех типов в Postgres... вроде бы)
        for field in self._meta.fields:
            if (field.name not in list_fields) and (field.name != 'parent'):
                list_fields.append(field.name)
                list_values.append(0)
 
        p5 = 'treensl_after_upd()'
        p6 = 'treensl_before_del()'
        p7 = 'treensl_before_new()'

        return POSTGRESQL_CONNECT_TABLE.format(self._meta.db_table,     #Название таблицы-наследника в БД
                                 ", ".join(list_fields,),
                                 tuple(list_values),
                                 self.LEVELS,
                                 self.CHILDREN,
                                 p5, p6, p7)

class Tree32Abstract(TreeAbstract):
    # Некоторые сочетания уровень/дети для int32:
    # 3/1624, 4/255, 5/83, 6/39, 7/23, 8/15
    # Размерность дерева по умолчанию:
    LEVELS = 5
    CHILDREN = 83

    # id корня дерева 5/83
    ROOT_ID = -2091059712

    id = models.IntegerField(primary_key=True)
    parent = models.ForeignKey('self')
    
    class Meta:
        abstract = True



class Tree64Abstract(TreeAbstract):
    # Некоторые сочетания уровень/дети для int64:
    # 3/2642245, 4/65535, 5/7131, 6/1624, 7/564, 8/255, 9/137, 10/83
    # Размерность дерева по умолчанию
    LEVELS = 6
    CHILDREN = 1624

    # id корня дерева 6/1624
    ROOT_ID = -9206407546997070313

    id = models.BigIntegerField(primary_key=True)
    parent = models.ForeignKey('self')
    
    class Meta:
        abstract = True
