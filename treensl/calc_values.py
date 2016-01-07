def children_range(id_e, tree_lv, tree_ch, root_id):
    y = tree_ch+1
    lv = tree_lv
    # Найдем уровень элемента
    for i in range(1, tree_lv):
        if ((id_e-root_id) % (y**(tree_lv-i))) == 0:
            lv = i
            break
    if lv == tree_lv:
        return[]
    # Теперь вернем диапазон возможных детей (первого и последнего)
    return [id_e+y**(tree_lv-lv-1), id_e-1+((y**(tree_lv-lv-1))*(tree_ch+1))]


def parents_list(id_e, tree_lv, tree_ch, root_id):
    pl = []
    y = tree_ch+1
    for i in range(1, tree_lv):
        x = y**(tree_lv-i)
        e = x * ((id_e-root_id) // x)
        if e != (id_e-root_id):
            pl.append(e+root_id)

    return pl
