-- Для БД PostgreSQL 9.1 и выше

-- Шаблон SQL скрипта для окончательной настройки таблицы (модели) хранящей дерево,
-- без использования механизма миграций.

-- То есть если хотите вручную настроить БД 
-- (например, если имеете версию Django, неподдерживающую миграции)
-- (или вообще будете использовать структуру дерева Treensl не в Django)

-- На данный момент приложение treensl настроено для использования миграций в потомках
-- Но можно и запускать данный скрипт руками на сервере, изменив, конечно таблицы
-- на те которые используете

-- Этот скрипт необходимо выполнить для каждой созданной модели-потомка
-- от Tree64Abstract или Tree32Abstract

-- Далее пример для приложения board модель Group, т.е. таблицы в БД board_group,
-- потомка от Tree64Abstract

-- Дополним таблицу массивом для хранения "дырок"
ALTER TABLE board_group ADD COLUMN holes integr[];

-- Запишем размерность созданной таблицы
INSERT INTO tree_size (table_name name, number_of_levels, number_of_children)
               VALUES ('board_group', 6, 1624);

-- Создадим корневой элемент дерева
-- Если в унаследованной таблице есть дополнительные поля NOT NULL,
-- то добавьте их названия и значения в этот оператор
INSERT INTO board_group (id, parent_id, lvl, created_children, removed_children)
              VALUES (-9206407546997070313, -9206407546997070313, 0, 0, 0);


-- Триггеры подключаем после создания корневого элемента. Это важно!
-- Теперь id для строк таблицы будут вычисляться триггерными функциями

CREATE TRIGGER after_upd
  AFTER UPDATE
  ON board_group
  FOR EACH ROW
  EXECUTE PROCEDURE treensl_after_upd();

CREATE TRIGGER before_del
  BEFORE DELETE
  ON board_group
  FOR EACH ROW
  EXECUTE PROCEDURE treensl_before_del();

CREATE TRIGGER before_new
  BEFORE INSERT
  ON board_group
  FOR EACH ROW
  EXECUTE PROCEDURE treensl_before_new();
