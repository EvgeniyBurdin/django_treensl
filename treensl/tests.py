from django.test import TestCase
from .calc_values import children_range, parents_list

class CalcValuesTests(TestCase):

    def test_children_range(self):

        self.assertEqual(children_range(27,4,2), [36, 53])
        self.assertEqual(children_range(36,4,2), [39, 44])
        self.assertEqual(children_range(45,4,2), [48, 53])
        self.assertEqual(children_range(54,4,2), [63, 80])
        self.assertEqual(children_range(78,4,2), [79, 80])

        self.assertEqual(children_range(-16,3,3), [-12, -1])
        self.assertEqual(children_range(-8,3,3), [-7, -5])
        self.assertEqual(children_range(16,3,3), [20, 31])
        self.assertEqual(children_range(28,3,3), [29, 31])

    def test_parents_list(self):
        
        self.assertEqual(parents_list(80,4,2), [54,72,78])
        self.assertEqual(parents_list(70,4,2), [54,63,69])
        self.assertEqual(parents_list(67,4,2), [54,63,66])

        self.assertEqual(parents_list(31,3,3), [16,28])
        self.assertEqual(parents_list(5,3,3), [0,4])


