-- Для БД PostgreSQL 9.1 и выше

-- Пример SQL скрипта для окончательной настройки (подключение к механизму создания id).
-- таблицы хранящей дерево, без использования механизма миграций.

-- То есть, если Вы по каким-то причинам, хотите вручную настроить БД, то
-- делайте как в этом примере.
-- Например, если имеете версию Django, не поддерживающую миграции,
-- или вообще будете использовать структуру дерева Treensl не с Django.

-- Внимание! Повторюсь - этот скрипт только лишь шаблон!
-- Если вы используете миграции, то этот скрипт не нужен!
-- (см. константу treensl/models.POSTGRESQL_CONNECT_TABLE - это он!)

-- Этот скрипт необходимо выполнить для каждой созданной модели-потомка
-- от Tree64Abstract или Tree32Abstract.

-- Далее, пример, для приложения board модель Group, т.е. для таблицы в
-- БД board_group, потомка от Tree64Abstract

-- Дополним таблицу массивом для хранения "дырок"
ALTER TABLE board_group ADD COLUMN holes integer[];

-- Запишем Имя таблицы и Размерность нового дерева
INSERT INTO tree_size (table_name name, number_of_levels, number_of_children)
               VALUES ('board_group', 6, 1623);

-- Создадим корневой элемент дерева
-- Если в таблице есть дополнительные поля NOT NULL,
-- то добавьте их названия и значения в этот оператор
INSERT INTO board_group (id, parent_id, lvl, created_children, removed_children)
              VALUES (-9223372036854775808, -9223372036854775808, 0, 0, 0);


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
