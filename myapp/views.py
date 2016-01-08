# -*- coding: utf-8 -*-
from django.shortcuts import render
from treensl.calc_values import parents_list, children_range
from .models import SimpleAd, Group


def get_parents_list(ads_l):
    for a in ads_l:
        # Получение списка родителей без дополнительных запросов
        pl = parents_list(a.parent.id, Group.LEVELS,
                          Group.CHILDREN, Group.ROOT_ID)

        # Мы нашли список родителей родителя (группы) объявления
        # Добавим в него и самого родителя объявления
        pl.append(a.parent.id)

        # Добавим в объявление и имена групп (для красивых путей)
        a.parents_list = Group.objects.filter(pk__in=pl).order_by('id')
    return ads_l


def ads_list(request):  # Все объявления

    context = {'ads_l': get_parents_list(SimpleAd.objects.order_by('-id'))}

    return render(request, 'myapp/index.html', context)


def group_list(request, group_id):  # Объявления определенной группы

    # Получение диапазона детей без дополнительных запросов
    group_l = children_range(int(group_id), Group.LEVELS,
                             Group.CHILDREN, Group.ROOT_ID)

    # В нашем случае левая граница это сам group_id (а не group_l[0])
    get_parents_list(SimpleAd.objects.filter(parent__range=(int(group_id),
                     group_l[1])).order_by('-id'))

    context = {'ads_l':
               get_parents_list(
               SimpleAd.objects.filter(parent__range=(int(group_id),
               group_l[1])).order_by('-id'))}

    return render(request, 'myapp/index.html', context)
