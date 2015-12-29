# -*- coding: utf-8 -*-
from django.test import TestCase
from .calc_values import children_range, parents_list

class CalcValuesTests(TestCase):

    def test_children_range(self):

        self.assertEqual(children_range(27,1,4,2,0), [36, 53])
        self.assertEqual(children_range(36,2,4,2,0), [39, 44])
        self.assertEqual(children_range(45,2,4,2,0), [48, 53])
        self.assertEqual(children_range(54,1,4,2,0), [63, 80])
        self.assertEqual(children_range(78,3,4,2,0), [79, 80])

        self.assertEqual(children_range(-16,1,3,3,-32), [-12, -1])
        self.assertEqual(children_range(-8,2,3,3,-32), [-7, -5])
        self.assertEqual(children_range(16,1,3,3,-32), [20, 31])
        self.assertEqual(children_range(28,2,3,3,-32), [29, 31])

    def test_parents_list(self):
        
        #self.assertEqual(parents_list(80,4,4,2,0), [54,72,78])
        #self.assertEqual(parents_list(70,4,4,2,0), [54,63,69])
        #self.assertEqual(parents_list(67,4,4,2,0), [54,63,66])

        self.assertEqual(parents_list(31,3,3,3,-32), [16,28])
        self.assertEqual(parents_list(5,3,3,3,-32), [0,4])


