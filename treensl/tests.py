# -*- coding: utf-8 -*-
from django.test import TestCase
from .calc_values import children_range, parents_list


class CalcValuesTests(TestCase):

    def test_children_range(self):

        self.assertEqual(children_range(27, 4, 2, 0), [36, 53])
        self.assertEqual(children_range(36, 4, 2, 0), [39, 44])
        self.assertEqual(children_range(45, 4, 2, 0), [48, 53])
        self.assertEqual(children_range(54, 4, 2, 0), [63, 80])
        self.assertEqual(children_range(78, 4, 2, 0), [79, 80])

        self.assertEqual(children_range(-16, 3, 3, -32), [-12, -1])
        self.assertEqual(children_range(-8, 3, 3, -32), [-7, -5])
        self.assertEqual(children_range(16, 3, 3, -32), [20, 31])
        self.assertEqual(children_range(28, 3, 3, -32), [29, 31])

        self.assertEqual(children_range(-9200779753821634560, 6, 1623,
                                        -9223372036854775808),
                         [-9200772798069469184, -9189483612305063937])
        self.assertEqual(children_range(9121561786055917567, 6, 1623,
                                        -9223372036854775808),
                         [])
        self.assertEqual(children_range(9121561786055915944, 6, 1623,
                                        -9223372036854775808),
                         [9121561786055915945, 9121561786055917567])
        self.assertEqual(children_range(9121554830303752192, 6, 1623,
                                        -9223372036854775808),
                         [9121554834586850816, 9121561786055917567])

    def test_parents_list(self):

        self.assertEqual(parents_list(80, 4, 2, 0), [54, 72, 78])
        self.assertEqual(parents_list(70, 4, 2, 0), [54, 63, 69])
        self.assertEqual(parents_list(67, 4, 2, 0), [54, 63, 66])

        self.assertEqual(parents_list(31, 3, 3, -32), [16, 28])
        self.assertEqual(parents_list(5, 3, 3, -32), [0, 4])

        self.assertEqual(parents_list(9121554830303752192, 6, 1623,
                                      -9223372036854775808),
                         [9110265644539346944])
        self.assertEqual(parents_list(9121561786055917567, 6, 1623,
                                      -9223372036854775808),
                         [9110265644539346944, 9121554830303752192,
                          9121561781772818944, 9121561786053280192,
                          9121561786055915944])
