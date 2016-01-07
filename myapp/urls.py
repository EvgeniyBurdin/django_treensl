# -*- coding: utf-8 -*-
from django.conf.urls import url

from . import views

urlpatterns = [
    url(r'^$', views.ads_list, name='ads_list'),
    url(r'^(?P<group_id>[+-]?\d+)/$', views.group_list, name='group_list')
]
