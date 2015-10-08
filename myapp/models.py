# -*- coding: utf-8 -*-
from django.db import models
from treensl.models import Tree64Abstract

class Group(Tree64Abstract):
    # Некоторые сочетания уровень/дети для int64:
    # 3/2642245, 4/65535, 5/7131, 6/1624, 7/564, 8/255, 9/137, 10/83
    # Размерность дерева по умолчанию:
    # (при необходимости раскомментить и изменить на предложенные выше)
    # LEVELS = 6
    # CHILDREN = 1624
    # id корня дерева для 6/1624
    # ROOT_ID = -9223372036854775808
    rem = models.CharField(max_length=100, blank=True)

    def __str__(self):
        return '{0} (lvl={1})'.format(self.label_node, self.lvl)

