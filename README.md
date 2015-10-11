На данный момент приложение тестировалось в Django 1.8, и БД PostgreSQL 9.1 и выше.

Установку можно произвести двумя способами.

## 1. Установка из git репозитария

Колнирование текущего репозитария создаст папку проекта `django_treensl`.

В нем имеется уже настроенное приложение для примера `myapp`.

В этом приложении присутствует пример описания иерархической модели `Group`, а так же готовый файл миграции, который, после выполнения команды `migrate`, подключит модель к триггерным функциям в БД PostgreSQL. БД, конечно же, надо предварительно создать и прописать корректные параметры подключения к ней в файле настроек проекта.

## 2. Стандартная установка

### 2.1. Установка пакета

`pip install django-treensl`

### 2.2. Подключение приложения

Подключить приложение `treensl` в `settings.py`:

     INSTALLED_APPS = (
         ...,
         'treensl',
     )



Подробнее - смотри wiki к этому репозитарию



---------
Приложение для создание структуры "дерево" в моделях Django типа — Вложенные 
множества с ограничением по количеству уровней и возможному количеству детей 
у родителя.

Ключ «id» - целочисленный. Либо int32 либо int64. 
От размера целого зависят количества допустимых уровней и детей.

Связанный список с полями «id» и «parent», где «parent» ссылка на «id» родителя.

Значение нового «id» вычисляется на основании размерности дерева, «id» родителя, 
и количества уже имеющихся у родителя детей.

Реализованное дерево сочетает достоинства деревьев типа «Связанный список», 
«Вложенные множества», «Материализованный путь». 
Ключ — целое число (не строка). 

Зная «id» элемента и размерность дерева (а мы всегда это знаем) можно осуществить:
- Вычисление диапазона детей, без запроса к БД
- Вычисление списка родителей, без запроса к БД
- Почти всегда, для получения данных, можно обойтись одним запрос к таблице

Недостаток — ограниченность размерности дерева разрядностью ключа. 
После выбора размерности дерева, и начала работы с ним (то есть с заполнением таблицы), 
будет уже нельзя изменить размерность.

Описание алгоритма в моей статье:
http://habrahabr.ru/post/166699/

Состав репозитария:

django_treensl — проект Django.

treensl — приложение, реализующее описание абстрактных таблиц-деревьев и 
осуществляющее настройку БД (создание триггерных функций, вспомогательных функций, 
таблицы хранящей размерности таблиц-деревьев).

myapp — приложение для примера. В нем создается модель-дерево, наследница от одной 
из абстрактных таблиц приложения treensl, записывается во вспомогательную таблицу 
размерность дерева, вставляется в дерево начальный элемент (первая запись, родитель 
для всех остальных), и производится подключение таблицы к триггерным функциям в БД.

docs — на данный момент в этой папке один файл, текст программы для помощи в выборе 
размерности дерева и «id» начального элемента. Программа на python2.

calc_values.py — в нем функции для вычисления диапазона детей, и списка родителей 
без обращения к БД. Эти функции могут быть использованы в приложении myapp.

Приложение создавалось в Django 1.8

БД пока только PostgreSQL 9.1 +

Для установки скопируйте репозитарий к себе на диск, создайте БД, поменяйте настройки 
в settings.py на свои, выполните manage.py migrate... можно запускать и смотреть работу 
тестовой таблицы Group