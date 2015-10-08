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
ALTER TABLE tree_size
  OWNER TO postgres;

CREATE OR REPLACE FUNCTION const_ch(tn name)
  RETURNS integer AS
'SELECT number_of_children FROM tree_size WHERE table_name = $1;'
  LANGUAGE sql IMMUTABLE
  COST 100;
ALTER FUNCTION const_ch(name)
  OWNER TO postgres;


CREATE OR REPLACE FUNCTION const_lv(tn name)
  RETURNS integer AS
'SELECT number_of_levels FROM tree_size WHERE table_name = $1;'
  LANGUAGE sql IMMUTABLE
  COST 100;
ALTER FUNCTION const_lv(name)
  OWNER TO postgres;

-- 1
CREATE OR REPLACE FUNCTION tree64_after_upd_parent()
  RETURNS trigger AS
$BODY$DECLARE
		     -- Размерность дерева:
	lv  integer; -- количество уровней
	ch  bigint;  -- количество детей у родителя

	new_p_lv  integer; -- Уровень нового родителя
	new_p_ch  bigint; -- Количество детей у нового родителя
	new_p_rem  bigint; -- Количество дырок у нового родителя
	parent_holes bigint[]; -- Массив дырок у родителя
	old_p_ch  bigint; -- Количество детей у старого родителя

	delta_lv  integer; -- Разница в уровнях при переносе
	dlv	  integer; -- Модуль разницы в уровнях
	max_lv	  integer; -- Максимальный уровень в переносимом поддереве

	limit_right  bigint;  -- Правая граница для подгруппы переноса

	id_dep	 bigint; -- Исходный головной (если есть поддерево) переносимый элемент
	id_dest	 bigint; -- Конечный головной (если есть поддерево) элемент при переносе

	x  bigint; -- Коэф "сжатия/расширения" переносимого поддерева головного эдемента

	max_id_for_parent  bigint; -- Самый "правый", т.е. больший существующий прямой ребенок у родителя
	removed_child_no   bigint; -- Номер "дырки" (если она найдется)

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

		-- Найдем нового родителя и его текущие данные
		EXECUTE 'SELECT lvl, created_children, removed_children FROM '
		  || quote_ident(TG_TABLE_NAME)
		  || ' WHERE id = $1 '
		  INTO new_p_lv, new_p_ch, new_p_rem
		  USING NEW.parent_id;

		-- Может ли родитель Вообще иметь детей?
		IF new_p_lv = lv THEN
			RAISE EXCEPTION 'Элементу с id = % нельзя иметь детей (его уровень % максимально возможный)', new_p_id, lv;
		END IF;

		-- Может ли родитель еше иметь детей?

		IF new_p_ch < ch THEN -- Если количество детей еще не превышено

			-- Создаем новый элемент для родителя
			id_dest := ((((ch + 1) ^ (lv - new_p_lv - 1))::bigint * (new_p_ch + 1)::numeric) + NEW.parent_id)::bigint;

			-- Увеличиваем счетчик детей у нового родителя
			EXECUTE format('UPDATE %I SET created_children = created_children + 1 WHERE id = $1', quote_ident(TG_TABLE_NAME))
			  USING NEW.parent_id;

		ELSIF new_p_rem > 0 THEN -- Если кол-во детей превышено, но есть дырки

			-- Возьмем массив дырок родителя
			EXECUTE 'SELECT holes FROM '
			  || quote_ident(TG_TABLE_NAME)
			  || ' WHERE id = $1 '
			  INTO parent_holes
			  USING NEW.parent_id;

			-- Берем последнюю дырку
			removed_child_no := parent_holes[new_p_rem];

			-- Новый элемент поставим на место "дырки"
			id_dest := ((((ch + 1) ^ (lv - new_p_lv - 1))::bigint * removed_child_no::numeric) + NEW.parent_id)::bigint;

			-- Удаляем дырку из массива родителя
			parent_holes := array_remove(parent_holes, removed_child_no);
			-- и  уменьшаем removed_children родителя
			EXECUTE format('UPDATE %I SET removed_children = removed_children - 1, holes = $1 WHERE id = $2', quote_ident(TG_TABLE_NAME))
				USING parent_holes, NEW.parent_id;

		ELSE
			RAISE EXCEPTION 'Родителю c id=% более нельзя иметь детей (их количество уже %)', NEW.parent_id, ch;
		END IF;


		-- Возьмем количество детей старого родителя
		EXECUTE 'SELECT created_children FROM '
		  || quote_ident(TG_TABLE_NAME)
		  || ' WHERE id = $1 '
		  INTO old_p_ch
		  USING OLD.parent_id;

		-- Найдем максимально правого существующего ребенка у старого родителя
		-- (здесь и далее "(OLD.lvl - 1)" - уровень старого родителя)
		max_id_for_parent := ((((ch + 1) ^ (lv - (OLD.lvl - 1) - 1))::bigint * (old_p_ch - 1)::numeric) + OLD.parent_id)::bigint;

		-- (old_p_ch - 1) чтобы не выйти за диапазон допустимых значений bigint
		-- поэтому в следующем сравнении >= ..... (а не просто >, как было бы при old_p_ch)
		IF max_id_for_parent >= OLD.id THEN -- имеем "дырку"

			-- Возьмем массив дырок старого родителя
			EXECUTE 'SELECT holes FROM '
			  || quote_ident(TG_TABLE_NAME)
			  || ' WHERE id = $1 '
			  INTO parent_holes
			  USING OLD.parent_id;

			-- Добавим в конец новую дырку
			parent_holes := array_append(parent_holes,
			  OLD.id / ((ch + 1) ^ (lv - (OLD.lvl - 1) - 1))::bigint - OLD.parent_id / ((ch + 1) ^ (lv - (OLD.lvl - 1) - 1))::bigint);

			-- Запишем новый массив дырок родителя и увеличим у него счетчик дырок
			EXECUTE format('UPDATE %I SET removed_children = removed_children + 1, holes = $1 WHERE id = $2', quote_ident(TG_TABLE_NAME))
			  USING parent_holes, OLD.parent_id;

		ELSE 	-- переносимый элемент последний

			-- Уменьшаем количество детей у старого родителя
			EXECUTE format('UPDATE %I SET created_children = created_children - 1 WHERE id = $1', quote_ident(TG_TABLE_NAME))
			  USING OLD.parent_id;

		END IF;

		delta_lv := (OLD.lvl - 1) - new_p_lv;

		dlv := @delta_lv;-- модуль

		-- Так как переносим элемент и всех его детей
		-- то найдем правую границу диапазона всех этих элементов
		id_dep := OLD.id;
		limit_right := id_dep - 1 + ((ch + 1) ^ (lv - (OLD.lvl - 1) - 1))::bigint;

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
		x := ((ch + 1) ^ dlv)::bigint;

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
ALTER FUNCTION tree64_after_upd_parent()
  OWNER TO postgres;

-- 2

CREATE OR REPLACE FUNCTION tree64_before_del_row()
  RETURNS trigger AS
$BODY$DECLARE
	             -- Размерность дерева:
	lv  integer; -- количество уровней
	ch  bigint;  -- количество детей у родителя

	old_p_ch  bigint; -- Количество детей у старого родителя

	max_id_for_parent  bigint; -- Самый "правый", т.е. больший существующий прямой ребенок у родителя

	parent_holes bigint[]; -- Массив дырок родителя

BEGIN

	IF (OLD.created_children - OLD.removed_children)  > 0 THEN
		RAISE EXCEPTION 'У данного элемента имеются дети в количестве % шт. Удалите сначала их.', (OLD.created_children - OLD.removed_children);
	END IF;

	-- Возьмем количество детей у родителя удаляемого элемента
	EXECUTE 'SELECT created_children FROM '
	  || quote_ident(TG_TABLE_NAME)
	  || ' WHERE id = $1 '
	  INTO old_p_ch
	  USING OLD.parent_id;

	-- Глобальные параметры размерности дерева
	ch:=const_ch(TG_TABLE_NAME);
	lv:=const_lv(TG_TABLE_NAME);

	-- Найдем максимально правого существующего ребенка у родителя
	-- (здесь и далее "(OLD.lvl - 1)" - уровень родителя)
	max_id_for_parent := ((((ch + 1) ^ (lv - (OLD.lvl - 1) - 1))::bigint * (old_p_ch - 1)::numeric) + OLD.parent_id)::bigint;

	-- (old_p_ch - 1) чтобы не выйти за диапазон допустимых значений bigint
	-- поэтому в следующем сравнении >= ..... (а не просто >, как было бы при old_p_ch)
	IF max_id_for_parent >= OLD.id THEN -- имеем "дырку"

		-- Возьмем массив дырок родителя
		EXECUTE 'SELECT holes FROM '
		  || quote_ident(TG_TABLE_NAME)
		  || ' WHERE id = $1 '
		  INTO parent_holes
		  USING OLD.parent_id;

		-- Добавим в конец новую дырку
		parent_holes := array_append(parent_holes,
		  OLD.id / ((ch + 1) ^ (lv - (OLD.lvl - 1) - 1))::bigint - OLD.parent_id / ((ch + 1) ^ (lv - (OLD.lvl - 1) - 1))::bigint);

		-- Запишем новый массив дырок родителя и увеличим у него счетчик дырок
		EXECUTE format('UPDATE %I SET removed_children = removed_children + 1, holes = $1 WHERE id = $2', quote_ident(TG_TABLE_NAME))
		  USING parent_holes, OLD.parent_id;

	ELSE 	-- удаляемый элемент последний

		-- Уменьшаем количество детей у его родителя
		EXECUTE format('UPDATE %I SET created_children = created_children - 1 WHERE id = $1', quote_ident(TG_TABLE_NAME))
		  USING OLD.parent_id;

	END IF;

	RETURN OLD;
END;

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION tree64_before_del_row()
  OWNER TO postgres;

-- 3

CREATE OR REPLACE FUNCTION tree64_before_new_id()
  RETURNS trigger AS
$BODY$DECLARE
		     -- Размерность дерева:
	lv  integer; -- количество уровней
	ch  bigint;  -- количество детей у родителя

	new_p_lv  integer; -- Уровень нового родителя
	new_p_ch  bigint; -- Количество детей у нового родителя
	new_p_rem  bigint; -- Количество дырок у нового родителя

	removed_child_no  bigint; -- Номер "дырки" у родителя
	parent_holes bigint[];

BEGIN
	-- Глобальные параметры размерности дерева
	ch := const_ch(TG_TABLE_NAME);
	lv := const_lv(TG_TABLE_NAME);

	-- Возьмем данные родителя
	EXECUTE 'SELECT lvl, created_children, removed_children FROM '
	  || quote_ident(TG_TABLE_NAME)
	  || ' WHERE id = $1 '
	  INTO new_p_lv, new_p_ch, new_p_rem
	  USING NEW.parent_id;

	-- Может ли родитель Вообще иметь детей?
	IF new_p_lv = lv THEN
		RAISE EXCEPTION 'Элементу с id=% нельзя иметь детей (его уровень % максимально возможный)', NEW.parent_id, lv;
	END IF;

	-- Может ли родитель еше иметь детей?

	IF new_p_ch < ch THEN -- Если количество детей еще не превышено

		-- Создаем новый элемент для родителя
		NEW.id := ((((ch + 1) ^ (lv - new_p_lv - 1))::bigint * (new_p_ch + 1)::numeric) + NEW.parent_id)::bigint;

		-- Увеличиваем счетчик детей у родителя
		EXECUTE format('UPDATE %I SET created_children = created_children + 1 WHERE id = $1', quote_ident(TG_TABLE_NAME))
		  USING NEW.parent_id;

	ELSIF new_p_rem > 0 THEN -- Если кол-во детей превышено, но есть дырки

		-- Возьмем дырки родителя
		EXECUTE 'SELECT holes FROM '
		  || quote_ident(TG_TABLE_NAME)
		  || ' WHERE id = $1 '
		  INTO parent_holes
		  USING NEW.parent_id;

		-- Берем последнюю дырку
		removed_child_no := parent_holes[new_p_rem];

		-- Новый элемент поставим на место "дырки"
		NEW.id := ((((ch + 1) ^ (lv - new_p_lv - 1))::bigint * removed_child_no::numeric) + NEW.parent_id)::bigint;

		-- Удаляем дырку из массива родителя
		parent_holes := array_remove(parent_holes, removed_child_no);
		-- и  уменьшаем removed_children родителя
		EXECUTE format('UPDATE %I SET removed_children = removed_children - 1, holes = $1 WHERE id = $2', quote_ident(TG_TABLE_NAME))
		  USING parent_holes, NEW.parent_id;

	ELSE
		RAISE EXCEPTION 'Родителю c id=% более нельзя иметь детей (их количество уже %)', NEW.parent_id, ch;
	END IF;

	NEW.lvl := new_p_lv + 1;
	NEW.created_children := 0;
	NEW.removed_children := 0;

	RETURN NEW;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION tree64_before_new_id()
  OWNER TO postgres;

-- 4

CREATE OR REPLACE FUNCTION tree32_after_upd_parent()
  RETURNS trigger AS
$BODY$DECLARE
		     -- Размерность дерева:
	lv  integer; -- количество уровней
	-- ch  bigint;  -- количество детей у родителя
	ch  integer;  -- количество детей у родителя

	new_p_lv  integer; -- Уровень нового родителя
	-- new_p_ch  bigint; -- Количество детей у нового родителя
	new_p_ch  integer; -- Количество детей у нового родителя
	-- new_p_rem  bigint; -- Количество дырок у нового родителя
	new_p_rem  integer; -- Количество дырок у нового родителя
	-- parent_holes bigint[]; -- Массив дырок у родителя
	parent_holes integer[]; -- Массив дырок у родителя
	--old_p_ch  bigint; -- Количество детей у старого родителя
	old_p_ch  integer; -- Количество детей у старого родителя

	delta_lv  integer; -- Разница в уровнях при переносе
	dlv	  integer; -- Модуль разницы в уровнях
	max_lv	  integer; -- Максимальный уровень в переносимом поддереве

	--limit_right  bigint;  -- Правая граница для подгруппы переноса
	limit_right  integer;  -- Правая граница для подгруппы переноса

	-- id_dep bigint; -- Исходный головной (если есть поддерево) переносимый элемент
	id_dep integer; -- Исходный головной (если есть поддерево) переносимый элемент
	--id_dest bigint; -- Конечный головной (если есть поддерево) элемент при переносе
	id_dest integer; -- Конечный головной (если есть поддерево) элемент при переносе

	-- x  bigint; -- Коэф "сжатия/расширения" переносимого поддерева головного эдемента
	x  integer; -- Коэф "сжатия/расширения" переносимого поддерева головного эдемента

	-- max_id_for_parent  bigint; -- Самый "правый", т.е. больший существующий прямой ребенок у родителя
	max_id_for_parent  integer; -- Самый "правый", т.е. больший существующий прямой ребенок у родителя
	-- removed_child_no   bigint; -- Номер "дырки" (если она найдется)
	removed_child_no   integer; -- Номер "дырки" (если она найдется)

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

		-- Найдем нового родителя и его текущие данные
		EXECUTE 'SELECT lvl, created_children, removed_children FROM '
		  || quote_ident(TG_TABLE_NAME)
		  || ' WHERE id = $1 '
		  INTO new_p_lv, new_p_ch, new_p_rem
		  USING NEW.parent_id;

		-- Может ли родитель Вообще иметь детей?
		IF new_p_lv = lv THEN
			RAISE EXCEPTION 'Элементу с id = % нельзя иметь детей (его уровень % максимально возможный)', new_p_id, lv;
		END IF;

		-- Может ли родитель еше иметь детей?

		IF new_p_ch < ch THEN -- Если количество детей еще не превышено

			-- Создаем новый элемент для родителя
			id_dest := ((((ch + 1) ^ (lv - new_p_lv - 1))::integer * (new_p_ch + 1)::bigint) + NEW.parent_id)::integer;

			-- Увеличиваем счетчик детей у нового родителя
			EXECUTE format('UPDATE %I SET created_children = created_children + 1 WHERE id = $1', quote_ident(TG_TABLE_NAME))
			  USING NEW.parent_id;

		ELSIF new_p_rem > 0 THEN -- Если кол-во детей превышено, но есть дырки

			-- Возьмем массив дырок родителя
			EXECUTE 'SELECT holes FROM '
			  || quote_ident(TG_TABLE_NAME)
			  || ' WHERE id = $1 '
			  INTO parent_holes
			  USING NEW.parent_id;

			-- Берем последнюю дырку
			removed_child_no := parent_holes[new_p_rem];

			-- Новый элемент поставим на место "дырки"
			id_dest := ((((ch + 1) ^ (lv - new_p_lv - 1))::integer * removed_child_no::bigint) + NEW.parent_id)::integer;

			-- Удаляем дырку из массива родителя
			parent_holes := array_remove(parent_holes, removed_child_no);
			-- и  уменьшаем removed_children родителя
			EXECUTE format('UPDATE %I SET removed_children = removed_children - 1, holes = $1 WHERE id = $2', quote_ident(TG_TABLE_NAME))
				USING parent_holes, NEW.parent_id;

		ELSE
			RAISE EXCEPTION 'Родителю c id=% более нельзя иметь детей (их количество уже %)', NEW.parent_id, ch;
		END IF;


		-- Возьмем количество детей старого родителя
		EXECUTE 'SELECT created_children FROM '
		  || quote_ident(TG_TABLE_NAME)
		  || ' WHERE id = $1 '
		  INTO old_p_ch
		  USING OLD.parent_id;

		-- Найдем максимально правого существующего ребенка у старого родителя
		-- (здесь и далее "(OLD.lvl - 1)" - уровень старого родителя)
		max_id_for_parent := ((((ch + 1) ^ (lv - (OLD.lvl - 1) - 1))::integer * (old_p_ch - 1)::bigint) + OLD.parent_id)::integer;

		-- (old_p_ch - 1) чтобы не выйти за диапазон допустимых значений bigint
		-- поэтому в следующем сравнении >= ..... (а не просто >, как было бы при old_p_ch)
		IF max_id_for_parent >= OLD.id THEN -- имеем "дырку"

			-- Возьмем массив дырок старого родителя
			EXECUTE 'SELECT holes FROM '
			  || quote_ident(TG_TABLE_NAME)
			  || ' WHERE id = $1 '
			  INTO parent_holes
			  USING OLD.parent_id;

			-- Добавим в конец новую дырку
			parent_holes := array_append(parent_holes,
			  OLD.id / ((ch + 1) ^ (lv - (OLD.lvl - 1) - 1))::integer - OLD.parent_id / ((ch + 1) ^ (lv - (OLD.lvl - 1) - 1))::integer);

			-- Запишем новый массив дырок родителя и увеличим у него счетчик дырок
			EXECUTE format('UPDATE %I SET removed_children = removed_children + 1, holes = $1 WHERE id = $2', quote_ident(TG_TABLE_NAME))
			  USING parent_holes, OLD.parent_id;

		ELSE 	-- переносимый элемент последний

			-- Уменьшаем количество детей у старого родителя
			EXECUTE format('UPDATE %I SET created_children = created_children - 1 WHERE id = $1', quote_ident(TG_TABLE_NAME))
			  USING OLD.parent_id;

		END IF;

		delta_lv := (OLD.lvl - 1) - new_p_lv;

		dlv := @delta_lv;-- модуль

		-- Так как переносим элемент и всех его детей
		-- то найдем правую границу диапазона всех этих элементов
		id_dep := OLD.id;
		limit_right := id_dep - 1 + ((ch + 1) ^ (lv - (OLD.lvl - 1) - 1))::integer;

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
		x := ((ch + 1) ^ dlv)::integer;

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
ALTER FUNCTION tree32_after_upd_parent()
  OWNER TO postgres;


-- 5

CREATE OR REPLACE FUNCTION tree32_before_del_row()
  RETURNS trigger AS
$BODY$DECLARE
	             -- Размерность дерева:
	lv  integer; -- количество уровней
	-- ch  bigint;  -- количество детей у родителя
	ch  integer;  -- количество детей у родителя

	-- old_p_ch  bigint; -- Количество детей у старого родителя
	old_p_ch  integer; -- Количество детей у старого родителя

	-- max_id_for_parent  bigint; -- Самый "правый", т.е. больший существующий прямой ребенок у родителя
	max_id_for_parent  integer; -- Самый "правый", т.е. больший существующий прямой ребенок у родителя

	-- parent_holes bigint[]; -- Массив дырок родителя
	 parent_holes integer[]; -- Массив дырок родителя

BEGIN

	IF (OLD.created_children - OLD.removed_children)  > 0 THEN
		RAISE EXCEPTION 'У данного элемента имеются дети в количестве % шт. Удалите сначала их.', (OLD.created_children - OLD.removed_children);
	END IF;

	-- Возьмем количество детей у родителя удаляемого элемента
	EXECUTE 'SELECT created_children FROM '
	  || quote_ident(TG_TABLE_NAME)
	  || ' WHERE id = $1 '
	  INTO old_p_ch
	  USING OLD.parent_id;

	-- Глобальные параметры размерности дерева
	ch:=const_ch(TG_TABLE_NAME);
	lv:=const_lv(TG_TABLE_NAME);

	-- Найдем максимально правого существующего ребенка у родителя
	-- (здесь и далее "(OLD.lvl - 1)" - уровень родителя)
	max_id_for_parent := ((((ch + 1) ^ (lv - (OLD.lvl - 1) - 1))::integer * (old_p_ch - 1)::bigint) + OLD.parent_id)::integer;

	-- (old_p_ch - 1) чтобы не выйти за диапазон допустимых значений bigint
	-- поэтому в следующем сравнении >= ..... (а не просто >, как было бы при old_p_ch)
	IF max_id_for_parent >= OLD.id THEN -- имеем "дырку"

		-- Возьмем массив дырок родителя
		EXECUTE 'SELECT holes FROM '
		  || quote_ident(TG_TABLE_NAME)
		  || ' WHERE id = $1 '
		  INTO parent_holes
		  USING OLD.parent_id;

		-- Добавим в конец новую дырку
		parent_holes := array_append(parent_holes,
		  OLD.id / ((ch + 1) ^ (lv - (OLD.lvl - 1) - 1))::integer - OLD.parent_id / ((ch + 1) ^ (lv - (OLD.lvl - 1) - 1))::integer);

		-- Запишем новый массив дырок родителя и увеличим у него счетчик дырок
		EXECUTE format('UPDATE %I SET removed_children = removed_children + 1, holes = $1 WHERE id = $2', quote_ident(TG_TABLE_NAME))
		  USING parent_holes, OLD.parent_id;

	ELSE 	-- удаляемый элемент последний

		-- Уменьшаем количество детей у его родителя
		EXECUTE format('UPDATE %I SET created_children = created_children - 1 WHERE id = $1', quote_ident(TG_TABLE_NAME))
		  USING OLD.parent_id;

	END IF;

	RETURN OLD;
END;

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION tree32_before_del_row()
  OWNER TO postgres;


-- 6

CREATE OR REPLACE FUNCTION tree32_before_new_id()
  RETURNS trigger AS
$BODY$DECLARE
		     -- Размерность дерева:
	lv  integer; -- количество уровней
	-- ch  bigint;  -- количество детей у родителя
	ch  integer;  -- количество детей у родителя

	new_p_lv  integer; -- Уровень нового родителя
	-- new_p_ch  bigint; -- Количество детей у нового родителя
	new_p_ch  integer; -- Количество детей у нового родителя
	-- new_p_rem  bigint; -- Количество дырок у нового родителя
	new_p_rem  integer; -- Количество дырок у нового родителя

	-- removed_child_no  bigint; -- Номер "дырки" у родителя
	removed_child_no  integer; -- Номер "дырки" у родителя
	-- parent_holes bigint[];
	parent_holes integer[];

BEGIN
	-- Глобальные параметры размерности дерева
	ch := const_ch(TG_TABLE_NAME);
	lv := const_lv(TG_TABLE_NAME);

	-- Возьмем данные родителя
	EXECUTE 'SELECT lvl, created_children, removed_children FROM '
	  || quote_ident(TG_TABLE_NAME)
	  || ' WHERE id = $1 '
	  INTO new_p_lv, new_p_ch, new_p_rem
	  USING NEW.parent_id;

	-- Может ли родитель Вообще иметь детей?
	IF new_p_lv = lv THEN
		RAISE EXCEPTION 'Элементу с id=% нельзя иметь детей (его уровень % максимально возможный)', NEW.parent_id, lv;
	END IF;

	-- Может ли родитель еше иметь детей?

	IF new_p_ch < ch THEN -- Если количество детей еще не превышено

		-- Создаем новый элемент для родителя
		NEW.id := ((((ch + 1) ^ (lv - new_p_lv - 1))::integer * (new_p_ch + 1)::bigint) + NEW.parent_id)::integer;

		-- Увеличиваем счетчик детей у родителя
		EXECUTE format('UPDATE %I SET created_children = created_children + 1 WHERE id = $1', quote_ident(TG_TABLE_NAME))
		  USING NEW.parent_id;

	ELSIF new_p_rem > 0 THEN -- Если кол-во детей превышено, но есть дырки

		-- Возьмем дырки родителя
		EXECUTE 'SELECT holes FROM '
		  || quote_ident(TG_TABLE_NAME)
		  || ' WHERE id = $1 '
		  INTO parent_holes
		  USING NEW.parent_id;

		-- Берем последнюю дырку
		removed_child_no := parent_holes[new_p_rem];

		-- Новый элемент поставим на место "дырки"
		NEW.id := ((((ch + 1) ^ (lv - new_p_lv - 1))::integer * removed_child_no::bigint) + NEW.parent_id)::integer;

		-- Удаляем дырку из массива родителя
		parent_holes := array_remove(parent_holes, removed_child_no);
		-- и  уменьшаем removed_children родителя
		EXECUTE format('UPDATE %I SET removed_children = removed_children - 1, holes = $1 WHERE id = $2', quote_ident(TG_TABLE_NAME))
		  USING parent_holes, NEW.parent_id;

	ELSE
		RAISE EXCEPTION 'Родителю c id=% более нельзя иметь детей (их количество уже %)', NEW.parent_id, ch;
	END IF;

	NEW.lvl := new_p_lv + 1;
	NEW.created_children := 0;
	NEW.removed_children := 0;

	RETURN NEW;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION tree32_before_new_id()
  OWNER TO postgres;


