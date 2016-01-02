# -*- coding: utf-8 -*-
from django.shortcuts import render
from treensl.calc_values import parents_list, children_range

from .models import SimpleAd, Group

def ads_list(request):
    ads_l = SimpleAd.objects.order_by('-id')
    for a in ads_l:
        # получение списка родителей должно обходиться без дополнительных запросов
        # если a.parent.id инициирует запрос, то поправить потом
        a.parents_list = parents_list(a.parent.id, Group.LEVELS, 
                                       Group.CHILDREN, Group.ROOT_ID)
        a.parents_list.append(a.parent.id)
        
    context = {'ads_l': ads_l}
    return render(request, 'myapp/index.html', context)
    
    
def group_list(request, group_id):
    
    group_l = children_range(int(group_id), Group.LEVELS,
                                       Group.CHILDREN, Group.ROOT_ID)
    # в текущем случае левая граница это сам group_id (а не group_l[0])
    ads_l = SimpleAd.objects.filter(parent__range=(int(group_id), group_l[1]))
    
    for a in ads_l:
        # получение списка родителей должно обходиться без дополнительных запросов
        # если a.parent.id инициирует запрос, то поправить потом
        a.parents_list = parents_list(a.parent.id, Group.LEVELS, 
                                       Group.CHILDREN, Group.ROOT_ID)
        a.parents_list.append(a.parent.id)
        
    context = {'ads_l': ads_l}
    return render(request, 'myapp/index.html', context)