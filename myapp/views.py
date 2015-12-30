# -*- coding: utf-8 -*-
from django.http import HttpResponse
from django.shortcuts import render

from .models import Ads


def ads_list(request):
    a_list = Ads.objects.order_by('-id')
    context = {'a_list': a_list}
    return render(request, 'myapp/index.html', context)
    
    
def group_list(request, group_id):
    response = "You're looking at the results of question %s."
    return HttpResponse(response % group_id)