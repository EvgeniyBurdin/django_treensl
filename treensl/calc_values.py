# -*- coding: utf-8 -*-
def children_range (id, tree_lv, tree_ch):
    y = tree_ch+1
    lv = tree_lv
    # Найдем уровень элемента
    for i in range(1, tree_lv):
        if (id % (y**(tree_lv-i))) == 0:
            lv = i
            break
    if lv == tree_lv: return[]
    # Теперь вернем диапазон возможных детей (первого и последнего)
    return [id+y**(tree_lv-lv-1), id-1+((y**(tree_lv-lv-1))*(tree_ch+1))]

def parents_list(id, tree_lv, tree_ch):
    pl = []
    y = tree_ch+1
    for i in range(1, tree_lv):
        x = y**(tree_lv-i)
        e = x * (id // x)
        if e != id:
            pl.append(e)
    return pl


'''
Вариант с уровнем элемента:
def parents_list(id, level, tree_lv, tree_ch):
    pl = []
    for i in range(1, level):
        x = (tree_ch+1)**(tree_lv-i)
        pl.insert(0, x * (id // x))
    return pl
'''