-- Для БД PostgreSQL 9.1 и выше

-- Шаблон SQL скрипта для окончательной настройки таблицы (модели) хранящей дерево,
-- без использования механизма миграций.

-- На данный момент приложение treensl настроено для использования миграций в потомках
-- Но можно и запускать данный скрипт руками на сервере, изменив, конечно таблицы
-- на те которые используете

-- Этот скрипт необходимо выполнить для каждой созданной модели-потомка
-- от Tree64Abstract или Tree32Abstract

-- Далее пример для приложения board модель Group, т.е. таблицы в БД board_group,
-- потомка от Tree64Abstract

-- Дополним таблицу массивом для хранения "дырок"
ALTER TABLE board_group ADD COLUMN holes bigint[];

-- Создадим корневой элемент дерева
-- Если в унаследованной таблице есть дополнительные поля NOT NULL,
-- то добавьте их названия и значения в этот оператор
INSERT INTO board_group (id, parent_id, lvl, created_children, removed_children)
              VALUES (-9223372036854775808, -9223372036854775808, 0, 0, 0);
-- INSERT INTO board_group (id, parent_id, lvl, created_children, removed_children, label_node)
--                 VALUES (-9223372036854775808, -9223372036854775808, 0, 0, 0, 'root');


-- Запишем размерность созданной таблицы
INSERT INTO tree_size (table_name name, number_of_levels, number_of_children)
               VALUES ('board_group', 6, 1624);

-- Триггеры подключаем после создания корневого элемента. Это важно!
-- Теперь id для строк таблицы будут вычисляться триггерными функциями

CREATE TRIGGER after_upd
  AFTER UPDATE
  ON board_group
  FOR EACH ROW
  -- Если потомок будет от Tree32Abstract, то имя подключаемой процедуры tree32_after_upd_parent()
  EXECUTE PROCEDURE tree64_after_upd_parent();

CREATE TRIGGER before_del
  BEFORE DELETE
  ON board_group
  FOR EACH ROW
  -- Если потомок будет от Tree32Abstract, то имя подключаемой процедуры tree32_before_del_row()
  EXECUTE PROCEDURE tree64_before_del_row();

CREATE TRIGGER before_new
  BEFORE INSERT
  ON board_group
  FOR EACH ROW
  -- Если потомок будет от Tree32Abstract, то имя подключаемой процедуры tree32_before_new_id()
  EXECUTE PROCEDURE tree64_before_new_id();
