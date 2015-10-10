import os
from setuptools import setup
import treensl

with open(os.path.join(os.path.dirname(__file__), 'README.rst')) as readme:
    README = readme.read()

# allow setup.py to be run from any path
os.chdir(os.path.normpath(os.path.join(os.path.abspath(__file__), os.pardir)))

setup(
    name='django-treensl',
    version=treensl.__version__,
    packages=['treensl'],
    include_package_data=True,
    license='BSD License',
    description='Django app to tree in DB.',
    long_description=README,
    url='https://github.com/EvgeniyBurdin/django_treensl',
    author='Evgeniy Burdin',
    author_email='e.s.burdin@mail.ru',
    keywords='django',
    classifiers=[
        'Environment :: Web Environment',
        'Framework :: Django',
        'Intended Audience :: Developers',
        'License :: BSD License',
        'Operating System :: OS Independent',
        'Programming Language :: Python',

    ],
)