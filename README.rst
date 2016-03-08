==================
django-treensl
==================

Django application for creating the tree structure in the model (very fast structure).

To create a new item in the tree need only choose a parent. The key (id) for the new item will be calculated automatically.
You can get a list of the parents and the range of children without a database query.

Implemented to create a new item, delete the item, transfer item to the other parent (and the transfer of the group).

Description of the algorithm for constructing the tree can be found  `habr.ru`_ or in the `wiki`_ (in Russian)

.. _habr.ru: http://habrahabr.ru/post/166699/

.. _wiki: https://github.com/EvgeniyBurdin/django_treensl/wiki

This app is available on `PyPI`_.

.. _PyPI: https://pypi.python.org/pypi/django-treensl/


Requirements
============

Supports `Django`_ 1.8 and later on Python 2.7,
3.2 - 3.5.

Works only with PostgreSQL 9.1 and later!

.. _Django: http://www.djangoproject.com/


Installation
============

Clone `this`_ repository. The is an example of a project (app ``myapp`` use ``treensl``)

.. _this: https://github.com/EvgeniyBurdin/django_treensl

Change the settings for connecting to the correct PostgreSQL DB.


or:

1. ``pip install django-treensl``

2. Add app ``treensl`` in ``settings.py``

3. Create a new class of models from ``Tree32Abstract`` or ``Tree64Abstract`` (from ``treensl.models``). Add your field in the model (for their fields, **do not use** the following names: ``id``, ``parent_id``, ``lvl``, ``created_children``, ``removed_children``, ``holes``). If necessary, change the dimension of the default tree (properties ``LEVELS`` and ``CHILDREN``). For example see `myapp/models.py`_

4. Run ``python manage.py makemigrations``

5. The new file migration, add the 3 lines as in the example file `myapp/migrations/0001_initial.py`_ (the rows are marked with comments ``# add after makemigrations``)

.. _myapp/models.py: https://github.com/EvgeniyBurdin/django_treensl/blob/master/myapp/models.py

.. _myapp/migrations/0001_initial.py: https://github.com/EvgeniyBurdin/django_treensl/blob/master/myapp/migrations/0001_initial.py


Possible dimensions of the tree
===============================

**Before** executing the ``migrate`` you can adjust the settings tree. The dimension of the tree depends on the length ``integer``.

Recommended values (in the format ``LEVELS/CHILDREN/ROOT_ID``):

1. For **int32**: ``3/1623/-2147483648``, ``4/255/-2147483648``, ``5/83/-2147483648``, ``6/39/-2147483648``

2. For **int64**: ``3/2642243/-9223372036854775808``, ``4/65535/-9223372036854775808``, ``5/7129/-9223372036854775808``, ``6/1623/-9223372036854775808``, ``7/563/-9223372036854775808``, ``8/255/-9223372036854775808``, ``9/137/-9223372036854775808``, ``10/83/-9223372036854775808``


Start usage
===========

Run ``python manage.py migrate``

Now, to create a new item in the tree need only choose a parent. The key (id) for the new item will be calculated automatically.

You can get a list of the parents and the range of children without a database query.

For any ``id`` call functions from the `treensl.calc_values`_:

1. ``parents_list(id, LEVELS, CHILDREN, ROOT_ID)`` - returns a list of the first to the last parent

2. ``children_range(id, LEVELS, CHILDREN, ROOT_ID)``- returns a list of the range of children

``LEVELS``, ``CHILDREN``, ``ROOT_ID`` - settings current tree


.. _treensl.calc_values: https://github.com/EvgeniyBurdin/django_treensl/blob/master/treensl/calc_values.py
