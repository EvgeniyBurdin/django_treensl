# -*- coding: utf-8 -*-
from django.db import models

# Этот скрипт необходимо выполнять во всех иерархических таблицах-наследниках
# путем добавления в миграции вашего приложения migrations.RunSQL().
# Пример в файле myapp/migranions/0001_initial.py
POSTGRESQL_CONNECT_TABLE = '''-- тестировал в БД PostgreSQL 9.1 и выше

-- Добавляем поле-массив которое хранит "дырки"
ALTER TABLE  {0} ADD COLUMN holes integer[];

-- Начальный элемент дерева
INSERT INTO {0} ({1}) VALUES {2};

-- Запишем Имя таблицы и Размерность нового дерева
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

    lvl = models.IntegerField(blank=True, null=False)
    created_children = models.IntegerField(blank=True, null=False)
    removed_children = models.IntegerField(blank=True, null=False)

    # Актуальное количество детей можно получить так:
    # self.created_children - self.removed_children

    class Meta:
        abstract = True

    # Подстановка значений в POSTGRESQL_CONNECT_TABLE
    def sql_end(self):

        # В определении модели, поле 'parent_id',названо как 'parent'.
        # Но, так как это поле ссылка на 'id', Django в БД его пишет
        # как 'parent_id'.

        # Создадим списки полей модели и их значений для первой
        # строки (для начального элемента, корня дерева).
        # Начальный элемент в таблице, хранящей дерево, ссылается сам на себя.
        list_fields = ['id', 'parent_id', 'lvl', 'created_children',
                       'removed_children']

        list_values = [self.ROOT_ID, self.ROOT_ID, 0, 0, 0]

        # Наследник модели может иметь свои дополнительные поля,
        # ...и они могут быть NOT NULL.
        # Необходимо вставить начальный элемент дерева, с учетом этого
        # То есть, заполнить такие поля каким-либо значением
        # (0 - подходит для полей всех типов в Postgres)
        for field in self._meta.fields:
            if (field.name not in list_fields) and (field.name != 'parent'):
                list_fields.append(field.name)
                list_values.append(0)

        # Триггерные функции для работы с id
        p5 = 'treensl_after_upd()'
        p6 = 'treensl_before_del()'
        p7 = 'treensl_before_new()'

        return POSTGRESQL_CONNECT_TABLE.format(self._meta.db_table,
                                               ", ".join(list_fields,),
                                               tuple(list_values),
                                               self.LEVELS,
                                               self.CHILDREN,
                                               p5, p6, p7
                                               )


class Tree32Abstract(TreeAbstract):
    # Размерность дерева по умолчанию для ключей типа int32.
    # Можно переопределить в потомках.
    # (некоторые допустимые значаения: 3/1623, 4/255, 5/83, 6/39)
    LEVELS = 5
    CHILDREN = 83

    # Начальный элемент взят минимально допустимый для int32.
    ROOT_ID = -2147483648

    id = models.IntegerField(primary_key=True)
    parent = models.ForeignKey('self')

    class Meta:
        abstract = True


class Tree64Abstract(TreeAbstract):
    # Размерность дерева по умолчанию для ключей типа int64.
    # Можно переопределить в потомках.
    # (некоторые допустимые значаения: 3/2642243, 4/65535, 5/7129,
    #  6/1623, 7/563, 8/255, 9/137, 10/83)
    LEVELS = 6
    CHILDREN = 1623

    # Начальный элемент взят минимально допустимый для int64.
    ROOT_ID = -9223372036854775808

    id = models.BigIntegerField(primary_key=True)
    parent = models.ForeignKey('self')

    class Meta:
        abstract = True
