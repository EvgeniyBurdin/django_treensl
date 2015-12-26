# -*- coding: utf-8 -*-
from django.db import models
from treensl.models import Tree64Abstract

class Group(Tree64Abstract):
    
    namenode = models.CharField(max_length=100, blank=True)
    
    LEVELS = 7
    CHILDREN = 564
    ROOT_ID = -9189865158000664063

    @property
    def name_for_admin(self):
        return '{0}{1} ({2}) '.format('- ' * self.lvl, self.namenode, self.count_children)

    def __str__(self):
        return '{0} (lvl={1})'.format(self.namenode, self.lvl)

