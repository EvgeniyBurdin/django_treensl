# -*- coding: utf-8 -*-
from django.db import models
from treensl.models import Tree64Abstract


class Group(Tree64Abstract):

    namenode = models.CharField(max_length=100, blank=True)

    LEVELS = 7
    CHILDREN = 563
    ROOT_ID = -9223372036854775808

    @property
    def name_for_admin(self):
        return '{0}{1} ({2}) '.format(' - ' * self.lvl,
                                      self.namenode,
                                      self.count_children)

    def __str__(self):
        return '{0} (L={1})'.format(self.namenode, self.lvl)


class SimpleAd(models.Model):
    parent = models.ForeignKey(Group)
    header_ad = models.CharField(max_length=100, blank=False, null=False)
    text_ad = models.CharField(max_length=200)

    def __str__(self):
        return self.header_ad
