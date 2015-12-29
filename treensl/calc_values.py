def children_range(id_e, id_lv, tree_lv, tree_ch, root_id):
    y = tree_ch+1
    lv = id_lv
    return [id_e+y**(tree_lv-lv-1), id_e-1+((y**(tree_lv-lv-1))*(tree_ch+1))]
    

def parents_list(id_e, id_lv, tree_lv, tree_ch, root_id):
    pl = []
    for i in range(1, id_lv):
        x = (tree_ch+1)**(tree_lv-i)
        korr = 0 if (x%2)==0 else 1
        idr = id_e - root_id
        y = idr//x   
        pl.append((x*y) + root_id - korr)      
    return pl
