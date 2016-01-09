==================
django-treensl
==================

Django application to the tree structure in the model.

``django-treensl`` supports `Django`_ 1.8 and later on Python 2.7,
3.2 - 3.5.

**Works only with PostgreSQL 9.1 and later!**

.. _Django: http://www.djangoproject.com/

This app is available on `PyPI`_.

.. _PyPI: https://pypi.python.org/pypi/django-treensl/


Installation
============

1. ``pip install django-treensl``

2. Add app ``treensl`` in ``settings.py``

3. Create a new class of models from ``Tree32Abstract`` or ``Tree64Abstract`` (from ``treensl.models``). Add your field in the model. If necessary, change the dimension of the default tree (properties ``LEVELS`` and ``CHILDREN``). For example see `myapp/models.py`_

.. _myapp/models.py: https://github.com/EvgeniyBurdin/django_treensl/blob/master/myapp/models.py

4. Run ``python manage.py makemigrations``

5. The new file migration, add the 3 lines as in the example file `myapp/migrations/0001_initial.py`_ (the rows are marked with comments ``# add after makemigrations``)

.. _myapp/migrations/0001_initial.py: https://github.com/EvgeniyBurdin/django_treensl/blob/master/myapp/migrations/0001_initial.py

6. Run ``python manage.py migrate``