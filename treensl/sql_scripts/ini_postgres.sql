-- Для БД PostgreSQL 9.1 и выше

CREATE TABLE tree_size
(
  table_name name NOT NULL,
  number_of_levels integer,
  number_of_children integer,
  CONSTRAINT pk_table_name PRIMARY KEY (table_name)
)
WITH (
  OIDS=FALSE
);
-- ALTER TABLE tree_size
--  OWNER TO postgres;


CREATE OR REPLACE FUNCTION pow_int(
    x bigint,
    y bigint)
  RETURNS bigint AS
$BODY$DECLARE

r bigint;

BEGIN

     IF y<0 THEN
        RAISE EXCEPTION 'Отрицательная степень y=% в pow_int(x,y) - недопустима! Можно только положительные степени!',y;
     END IF;

     IF y=0 THEN
        RETURN 1;
     END IF;

     IF y=1 THEN
        RETURN x;
     END IF;

     r := x;

     FOR i IN 1..(y-1) LOOP
         r:= r * x;
     END LOOP;

     RETURN r;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
-- ALTER FUNCTION pow_int(bigint, bigint)
--  OWNER TO postgres;


CREATE OR REPLACE FUNCTION calc_new_id(
    step bigint,
    child integer,
    parent bigint)
  RETURNS bigint AS
$BODY$DECLARE

   c1  integer;
   c2  integer;
   r   bigint;

BEGIN
       c1 := div(child, 2);
       c2 := child - c1;
       IF (c1*2) = child THEN
          c2 := c1;
       END IF;
       r := step * c1 + parent;
       r := step * c2 + r;
       RETURN r;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
-- ALTER FUNCTION calc_new_id(bigint, integer, bigint)
--  OWNER TO postgres;


CREATE OR REPLACE FUNCTION calc_number_ch(
    child bigint,
    parent bigint,
    step bigint)
  RETURNS integer AS
$BODY$DECLARE

   p1  bigint;
   p2  bigint;
   c1  bigint;
   c2  bigint;

BEGIN
       IF ((parent>0) AND (child>0)) OR ((parent<0) AND (child<0)) THEN
          RETURN div((child - parent), step);
       END IF;

       p1 := div(parent, step);
       p2 := parent - (p1*step);
       c1 := div(child, step);
       c2 := child - (c1*step);

       RETURN c1 - p1 + div(c2-p2,step);
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
-- ALTER FUNCTION calc_number_ch(bigint, bigint, bigint)
--  OWNER TO postgres;


CREATE OR REPLACE FUNCTION const_ch(tn name)
  RETURNS integer AS
'SELECT number_of_children FROM tree_size WHERE table_name = $1;'
  LANGUAGE sql IMMUTABLE
  COST 100;
-- ALTER FUNCTION const_ch(name)
--  OWNER TO postgres;


CREATE OR REPLACE FUNCTION const_lv(tn name)
  RETURNS integer AS
'SELECT number_of_levels FROM tree_size WHERE table_name = $1;'
  LANGUAGE sql IMMUTABLE
  COST 100;
-- ALTER FUNCTION const_lv(name)
--  OWNER TO postgres;


CREATE OR REPLACE FUNCTION create_new_id(
    IN parent bigint,
    IN tn name,
    OUT new_id bigint,
    OUT new_lv integer)
  RETURNS record AS
$BODY$
DECLARE
   -- Размерность дерева:
   lv                 integer;
   ch                 integer;

   new_p_lv           integer; -- Уровень родителя
   new_p_ch           integer;  -- Количество детей у родителя
   new_p_rem          integer;  -- Количество дырок у родителя

   removed_child_no   integer;    -- Номер "дырки" у родителя
   parent_holes       integer []; -- Массив "дырок"

BEGIN
   -- Присвоим размерность дерева (данные хранятся в таблице tree_size)
   ch := const_ch(tn);
   lv := const_lv(tn);

   -- Возьмем данные родителя
   EXECUTE
         'SELECT lvl, created_children, removed_children FROM '
      || quote_ident (tn)
      || ' WHERE id = $1 '
      INTO new_p_lv, new_p_ch, new_p_rem
      USING parent;

   -- Может ли родитель Вообще иметь детей?
   IF new_p_lv = lv
   THEN
       RAISE EXCEPTION 'Элементу с id=% нельзя иметь детей - его уровень % максимально возможный!', parent, lv;
   END IF;

   IF new_p_rem > 0 THEN
      -- Если есть дырки
      -- Возьмем дырки родителя
      EXECUTE
            'SELECT holes FROM '
         || quote_ident (tn)
         || ' WHERE id = $1 '
         INTO parent_holes
         USING parent;

      -- Берем последнюю дырку
      removed_child_no := parent_holes[new_p_rem];

      -- Новый элемент поставим на место "дырки"
      -- new_id := calc_new_id(((ch + 1)^(lv - new_p_lv - 1))::bigint, removed_child_no::integer, parent::bigint);
      -- 1 R_pow_int
      new_id := calc_new_id(pow_int((ch + 1),(lv - new_p_lv - 1)), removed_child_no::integer, parent::bigint);

      -- Удаляем дырку из массива родителя
      parent_holes := array_remove(parent_holes, removed_child_no);

      -- и  уменьшаем removed_children родителя
      EXECUTE format (
         'UPDATE %I SET removed_children = removed_children - 1, holes = $1 WHERE id = $2',
         quote_ident (tn))
         USING parent_holes, parent;

   -- Может ли родитель еше иметь детей?
   ELSIF new_p_ch < ch THEN
      -- Если количество детей еще не превышено
      -- Создаем новый элемент для родителя
      -- calc_new_id(шаг, номер_ребенка, родитель)
      -- new_id := calc_new_id(((ch + 1)^(lv - new_p_lv - 1))::bigint, (new_p_ch + 1)::integer, parent::bigint);
      -- 2 R_pow_int
      new_id := calc_new_id(pow_int((ch + 1),(lv - new_p_lv - 1)), (new_p_ch + 1)::integer, parent::bigint);

      -- Увеличиваем счетчик детей у родителя
      EXECUTE format (
         'UPDATE %I SET created_children = created_children + 1 WHERE id = $1',
         quote_ident (tn))
         USING parent;
   ELSE
      RAISE EXCEPTION 'Родителю c id=% более нельзя иметь детей - их количество уже %!', parent, ch;
   END IF;

   new_lv := new_p_lv +1;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
-- ALTER FUNCTION create_new_id(bigint, name)
--  OWNER TO postgres;


CREATE OR REPLACE FUNCTION delete_row(
    id bigint,
    lvl integer,
    created_children integer,
    removed_children integer,
    parent_id bigint,
    tn name)
  RETURNS integer AS
$BODY$
DECLARE
   -- Размерность дерева:
   lv                 integer;
   ch                 integer;

   old_p_ch  integer;          -- Количество детей у старого родителя
   max_id_for_parent  bigint;  -- Самый "правый", т.е. больший существующий прямой ребенок у родителя
   parent_holes integer[];     -- Массив дырок родителя

BEGIN
   -- Возьмем количество детей у родителя удаляемого элемента
   EXECUTE 'SELECT created_children FROM '
	  || quote_ident(tn)
	  || ' WHERE id = $1 '
	  INTO old_p_ch
	  USING parent_id;

   -- Присвоим размерность дерева (данные хранятся в таблице tree_size)
   ch := const_ch(tn);
   lv := const_lv(tn);

	-- Найдем максимально правого существующего ребенка у родителя
	-- (здесь и далее "(lvl - 1)" - уровень родителя)

    -- max_id_for_parent := calc_new_id( ((ch + 1) ^ (lv - (lvl - 1) - 1))::bigint,
    --                                  (old_p_ch - 1)::integer,
    --                                  parent_id::bigint);
    -- 3 R_pow_int
    max_id_for_parent := calc_new_id(pow_int((ch + 1),(lv - (lvl - 1) - 1)),
                                      (old_p_ch - 1)::integer,
                                      parent_id::bigint);

    -- (old_p_ch - 1) чтобы не выйти за диапазон допустимых значений bigint
    -- поэтому в следующем сравнении >= ..... (а не просто >, как было бы при old_p_ch)

    IF max_id_for_parent >= id THEN -- имеем "дырку"

		-- Возьмем массив дырок родителя
		EXECUTE 'SELECT holes FROM '
		  || quote_ident(tn)
		  || ' WHERE id = $1 '
		  INTO parent_holes
		  USING parent_id;

		-- Добавим в конец новую дырку
		-- parent_holes := array_append(parent_holes, calc_number_ch(id, parent_id,
        --                                 ((ch + 1)^(lv - (lvl - 1) - 1))::bigint));
        -- 4 R_pow_int
        parent_holes := array_append(parent_holes, calc_number_ch(id, parent_id,
                                    pow_int((ch + 1),(lv - (lvl - 1) - 1))));


		-- Запишем новый массив дырок родителя и увеличим у него счетчик дырок
		EXECUTE format('UPDATE %I SET removed_children = removed_children + 1, holes = $1 WHERE id = $2',
                       quote_ident(tn))
          USING parent_holes, parent_id;

	ELSE 	-- удаляемый элемент последний

		-- Уменьшаем количество детей у его родителя
		EXECUTE format('UPDATE %I SET created_children = created_children - 1 WHERE id = $1',
                       quote_ident(tn))
          USING parent_id;

	END IF;

	RETURN 0;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
-- ALTER FUNCTION delete_row(bigint, integer, integer, integer, bigint, name)
--  OWNER TO postgres;



-- 1
CREATE OR REPLACE FUNCTION treensl_after_upd()
  RETURNS trigger AS
$BODY$DECLARE
		     -- Размерность дерева:
	lv  integer; -- количество уровней
	ch  integer;  -- количество детей у родителя

	delta_lv  integer; -- Разница в уровнях при переносе
	dlv	  integer; -- Модуль разницы в уровнях
	max_lv	  integer; -- Максимальный уровень в переносимом поддереве

	limit_right  bigint;  -- Правая граница для подгруппы переноса

	id_dep	 bigint; -- Исходный головной (если есть поддерево) переносимый элемент
	id_dest	 bigint; -- Конечный головной (если есть поддерево) элемент при переносе

	x  bigint; -- Коэф "сжатия/расширения" переносимого поддерева головного эдемента

    new_rec  record;


BEGIN
    -- В клиентах id не изменяются (и менять их руками нельзя так как порушится дерево)
    -- Для переноса надо изменить родителя (parent_id)
    IF (NEW.id = OLD.id) AND (NEW.parent_id != OLD.parent_id) THEN -- имеем перенос
       IF NEW.id = NEW.parent_id THEN
	      RAISE EXCEPTION 'Перенос id = % к самому себе невозможен!', NEW.id;
       END IF;

       -- Имеем перенос к другому родителю
       -- Пересчитаем сам головной элемент, который переносим, и его возможное "поддерево"

       -- Глобальные параметры размерности дерева для запустившей триггер таблицы
       ch := const_ch(TG_TABLE_NAME);
       lv := const_lv(TG_TABLE_NAME);

       new_rec := create_new_id(NEW.parent_id, TG_TABLE_NAME);
       id_dest := new_rec.new_id;

       PERFORM delete_row(OLD.id, OLD.lvl, OLD.created_children, OLD.removed_children, OLD.parent_id, TG_TABLE_NAME);

       delta_lv := (OLD.lvl - 1) - (new_rec.new_lv-1);

       dlv := @delta_lv;-- модуль

       -- Так как переносим элемент и всех его детей
       -- то найдем правую границу диапазона всех этих элементов
       id_dep := OLD.id;
       -- limit_right := id_dep - 1 + ((ch + 1) ^ (lv - (OLD.lvl - 1) - 1))::bigint;
       -- 5 R_pow_int
       limit_right := id_dep - 1 + pow_int((ch + 1), (lv - (OLD.lvl - 1) - 1));


       -- Найдем максимальное значения поля lvl для продгруппы переноса
       EXECUTE 'SELECT max(lvl) FROM '
	       || quote_ident(TG_TABLE_NAME)
	       || ' WHERE id BETWEEN $1 AND $2 '
	       INTO max_lv
	       USING id_dep + 1, limit_right;

       IF (max_lv - delta_lv) > lv THEN
	  RAISE EXCEPTION 'Перенос невозможен из-за выхода переносимых элементов за нижний уровень';
       END IF;

       -- Запишем головной элемент
       EXECUTE format('UPDATE %I SET id = $1, lvl = lvl - $2, parent_id = $3 WHERE id = $4', quote_ident(TG_TABLE_NAME))
	       USING id_dest, delta_lv, NEW.parent_id, id_dep;

       -- Коэф расфирения/сжатия переносимого поддерева
       -- x := ((ch + 1) ^ dlv)::bigint;
       -- 6 R_pow_int
       x := pow_int((ch + 1), dlv);

       IF delta_lv < 0 THEN -- Переносим "вниз"

	  EXECUTE format('UPDATE %I SET id=((id-$1)/$2)+$3, lvl=lvl-$4, parent_id=((parent_id-$1)/$2)+$3 WHERE id BETWEEN $1+1 AND $5',
			  quote_ident(TG_TABLE_NAME))
	          USING id_dep, x, id_dest, delta_lv, limit_right;

       ELSE -- Переносим "вверх"

	  EXECUTE format('UPDATE %I SET id=((id-$1)*$2)+$3, lvl=lvl-$4, parent_id=((parent_id-$1)*$2)+$3 WHERE id BETWEEN $1+1 AND $5',
			  quote_ident(TG_TABLE_NAME))
	          USING id_dep, x, id_dest, delta_lv, limit_right;

       END IF;
    END IF;
    RETURN NEW;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
-- ALTER FUNCTION treensl_after_upd()
--  OWNER TO postgres;

-- 2
CREATE OR REPLACE FUNCTION treensl_before_del()
  RETURNS trigger AS
$BODY$BEGIN
   IF (OLD.created_children - OLD.removed_children)  > 0 THEN
		RAISE EXCEPTION 'У данного элемента имеются дети в количестве % шт. Удалите сначала их.',
        (OLD.created_children - OLD.removed_children);
   END IF;
   PERFORM delete_row(OLD.id, OLD.lvl, OLD.created_children, OLD.removed_children, OLD.parent_id, TG_TABLE_NAME);
   RETURN OLD;
END$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
-- ALTER FUNCTION treensl_before_del()
--  OWNER TO postgres;


-- 3
CREATE OR REPLACE FUNCTION treensl_before_new()
  RETURNS trigger AS
$BODY$
DECLARE
    r record;

BEGIN

   r := create_new_id(NEW.parent_id, TG_TABLE_NAME);
   NEW.id := r.new_id;
   NEW.lvl := r.new_lv;
   NEW.created_children := 0;
   NEW.removed_children := 0;

   RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
-- ALTER FUNCTION treensl_before_new()
--  OWNER TO postgres;