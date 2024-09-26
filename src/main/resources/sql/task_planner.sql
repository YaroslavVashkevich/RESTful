--
-- PostgreSQL database dump
--

-- Dumped from database version 15.2
-- Dumped by pg_dump version 15.2

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: add_task(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.add_task() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN
/*категория НЕПУСТАЯ и статус задачи ЗАВЕРШЕН*/
if (coalesce(NEW.category_id, 0)>0 and NEW.completed=1) then
		update public.category set completed_count = (coalesce(completed_count, 0)+1) where id = NEW.category_id and user_id=new.user_id;
	end if;
	
/*категория НЕПУСТАЯ и статус задачи НЕЗАВЕРШЕН*/
 if (coalesce(NEW.category_id, 0)>0 and coalesce(NEW.completed, 0) = 0) then
		update public.category set uncompleted_count = (coalesce(uncompleted_count, 0)+1) where id = NEW.category_id and user_id=new.user_id;
	end if;
	
/* общая статистика */
	if coalesce(NEW.completed, 0) = 1 then
		update public.stat set completed_total = (coalesce(completed_total, 0)+1)  where user_id=new.user_id;
	else
		update public.stat set uncompleted_total = (coalesce(uncompleted_total, 0)+1)  where user_id=new.user_id;
    end if;

	RETURN NEW;
END$$;


ALTER FUNCTION public.add_task() OWNER TO postgres;

--
-- Name: delete_task(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.delete_task() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN
/* категория НЕПУСТАЯ и статус задачи ЗАВЕРШЕН */
    if (coalesce(old.category_id, 0)>0 and coalesce(old.completed, 0)=1) then
		update public.category set completed_count = (coalesce(completed_count, 0)-1) where id = old.category_id and user_id=old.user_id;
	end if;
     
/*  категория НЕПУСТАЯ и статус задачи НЕЗАВЕРШЕН */
    if (coalesce(old.category_id, 0)>0 and coalesce(old.completed, 0)=0) then
		update public.category set uncompleted_count = (coalesce(uncompleted_count, 0)-1) where id = old.category_id and user_id=old.user_id;
	end if;
	
/* общая статистика */
	if coalesce(old.completed, 0)=1 then
		update public.stat set completed_total = (coalesce(completed_total, 0)-1)  where user_id=old.user_id;
	else
		update public.stat set uncompleted_total = (coalesce(uncompleted_total, 0)-1)  where user_id=old.user_id;
    end if;

	RETURN OLD;
END$$;


ALTER FUNCTION public.delete_task() OWNER TO postgres;

--
-- Name: new_user_data(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.new_user_data() RETURNS trigger
    LANGUAGE plpgsql
    AS $$DECLARE
	/* для хранения id вставленных тестовых данных - чтобы их можно было использовать при создании тестовых задач*/
	priorId1 INTEGER; 
	priorId2 INTEGER;
	priorId3 INTEGER;
	catId1 INTEGER;
	catId2 INTEGER;
	catId3 INTEGER;
	/* тестовые даты */
	date1 Date = NOW() + INTERVAL '1 day';
	date2 Date = NOW();
	date3 Date = NOW() + INTERVAL '6 day';
	/* ID роли из таблицы role_data */
	roleId INTEGER = 2;
BEGIN
    /*добавляем нового пользователя в таблицу activity, gen_random_uuid() автогенерирование, либо можно сделать поле uuid типом не text, а uuid (только в postgres)*/
	insert into public.activity (uuid, activated, user_id) values (gen_random_uuid(), 0, new.id);
	/* при вставке нового пользователя - создаем строку для хранения общей статистики - это не тестовые данные, а обязательные (иначе общая статистика не будет работать)*/
    insert into public.stat (completed_total, uncompleted_total, user_id) values (0,0, new.id);
	/* добавляем начальные тестовые категории для нового созданного пользователя */
    insert into public.category (title, completed_count, uncompleted_count, user_id) values ('Семья',0 ,0 ,new.id) RETURNING id into catId1; /* сохранить id вставленной записи в переменную */
    insert into public.category (title, completed_count, uncompleted_count, user_id) values ('Работа',0 ,0 ,new.id) RETURNING id into catId2;
	insert into public.category (title, completed_count, uncompleted_count, user_id) values ('Отдых',0 ,0 ,new.id) RETURNING id into catId3;
	insert into public.category (title, completed_count, uncompleted_count, user_id) values ('Путешествия',0 ,0 ,new.id);
    insert into public.category (title, completed_count, uncompleted_count, user_id) values ('Спорт',0 ,0 ,new.id);
    insert into public.category (title, completed_count, uncompleted_count, user_id) values ('Здоровье',0 ,0 ,new.id);
	/* добавляем начальные тестовые приоритеты для созданного пользователя */
    insert into public.priority (title, color, user_id) values ('Низкий', '#caffdd', new.id) RETURNING id into priorId1;
    insert into public.priority (title, color, user_id) values ('Средний', '#b488e3', new.id) RETURNING id into priorId2;
    insert into public.priority (title, color, user_id) values ('Высокий', '#f05f5f', new.id) RETURNING id into priorId3;
	/* добавляем начальные тестовые задачи для созданного пользователя */
    insert into public.task (title, completed, user_id, priority_id, category_id, task_date) values ('Позвонить родителям', 0, new.id, priorId1, catId1, date1);
    insert into public.task (title, completed, user_id, priority_id, category_id, task_date) values ('Посмотреть мультики', 1,  new.id, priorId1, catId3, date2);
    insert into public.task (title, completed, user_id, priority_id, category_id) values ('Пройти курсы по Java', 0, new.id, priorId3, catId2);
    insert into public.task (title, completed, user_id, priority_id) values ('Сделать зеленый коктейль', 1, new.id, priorId3);
    insert into public.task (title, completed, user_id, priority_id, task_date) values ('Купить буханку хлеба', 0, new.id, priorId2, date3);
	/* по-умолчанию добавляем новому пользователю роль USER */
    insert into public.user_role (user_id, role_id) values (new.id, roleId);
	RETURN NEW;
END$$;


ALTER FUNCTION public.new_user_data() OWNER TO postgres;

--
-- Name: update_task(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_task() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN
 /* изменили completed с 0 на 1, НЕ изменили категорию */
    IF (coalesce(old.completed,0)=0 and new.completed=1 and coalesce(old.category_id,0) = coalesce(new.category_id,0)) THEN        
		/* у неизмененной категории кол-во незавершенных уменьшится на 1,  кол-во завершенных увеличится на 1 */
		update public.category set uncompleted_count = (coalesce(uncompleted_count, 0)-1), completed_count = (coalesce(completed_count,0)+1) where id = old.category_id and user_id=old.user_id;
	    /* общая статистика */
		update public.stat set uncompleted_total = (coalesce(uncompleted_total,0)-1), completed_total = (coalesce(completed_total,0)+1)  where user_id=old.user_id;	
	END IF;
        
/* изменили completed c 1 на 0, НЕ изменили категорию */
    IF (coalesce(old.completed,1) =1 and new.completed=0 and coalesce(old.category_id,0) = coalesce(new.category_id,0)) THEN        
		/* у неизмененной категории кол-во завершенных уменьшится на 1, кол-во незавершенных увеличится на 1 */
		update public.category set completed_count = (coalesce(completed_count,0)-1), uncompleted_count = (coalesce(uncompleted_count,0)+1) where id = old.category_id and user_id=old.user_id; 
	    /* общая статистика */
		update public.stat set completed_total = (coalesce(completed_total,0)-1), uncompleted_total = (coalesce(uncompleted_total,0)+1)  where user_id=old.user_id;	
	END IF;
        
/* изменили категорию, не изменили completed=1 */
    IF (coalesce(old.category_id,0) <> coalesce(new.category_id,0) and coalesce(old.completed,1) = 1 and new.completed=1) THEN    
		/* у старой категории кол-во завершенных уменьшится на 1 */
		update public.category set completed_count = (coalesce(completed_count,0)-1) where id = old.category_id and user_id=old.user_id;   
		/* у новой категории кол-во завершенных увеличится на 1 */
		update public.category set completed_count = (coalesce(completed_count,0)+1) where id = new.category_id and user_id=old.user_id;
		/* общая статистика не изменяется */
	END IF;
    
/* изменили категорию, не изменили completed=0 */
    IF (coalesce(old.category_id,0) <> coalesce(new.category_id,0) and coalesce(old.completed,0)= 0  and new.completed=0) THEN    
		/* у старой категории кол-во незавершенных уменьшится на 1 */
		update public.category set uncompleted_count = (coalesce(uncompleted_count,0)-1) where id = old.category_id and user_id=old.user_id; 
		/* у новой категории кол-во незавершенных увеличится на 1 */
		update public.category set uncompleted_count = (coalesce(uncompleted_count,0)+1) where id = new.category_id and user_id=old.user_id;
		/* общая статистика не изменяется */
	END IF;

/* изменили категорию, изменили completed с 1 на 0 */
    IF (coalesce(old.category_id,0) <> coalesce(new.category_id,0) and coalesce(old.completed,1) =1 and new.completed=0) THEN    
		/* у старой категории кол-во завершенных уменьшится на 1 */
		update public.category set completed_count = (coalesce(completed_count,0)-1) where id = old.category_id and user_id=old.user_id;   
		/* у новой категории кол-во незавершенных увеличится на 1 */
		update public.category set uncompleted_count = (coalesce(uncompleted_count,0)+1) where id = new.category_id and user_id=old.user_id;
	    /* общая статистика */
		update public.stat set uncompleted_total = (coalesce(uncompleted_total,0)+1), completed_total = (coalesce(completed_total,0)-1)  where user_id=old.user_id;	
	END IF;
      
/* изменили категорию, изменили completed с 0 на 1 */
    IF (coalesce(old.completed,0) =0 and new.completed=1 and coalesce(old.category_id,0) <> coalesce(new.category_id,0)) THEN    
		/* у старой категории кол-во незавершенных уменьшится на 1 */
		update public.category set uncompleted_count = (coalesce(uncompleted_count,0)-1) where id = old.category_id and user_id=old.user_id;  
		/* у новой категории кол-во завершенных увеличится на 1 */
		update public.category set completed_count = (coalesce(completed_count,0)+1) where id = new.category_id and user_id=old.user_id;
		/* общая статистика */
		update public.stat set uncompleted_total = (coalesce(uncompleted_total,0)-1), completed_total = (coalesce(completed_total,0)+1)  where user_id=old.user_id;
	END IF;

	RETURN NEW;	
END$$;


ALTER FUNCTION public.update_task() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: activity; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.activity (
    id bigint NOT NULL,
    uuid text NOT NULL,
    activated smallint NOT NULL,
    user_id bigint
);


ALTER TABLE public.activity OWNER TO postgres;

--
-- Name: activity_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.activity ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.activity_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: category; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.category (
    title text NOT NULL,
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    completed_count bigint,
    uncompleted_count bigint
);


ALTER TABLE public.category OWNER TO postgres;

--
-- Name: category_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.category ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.category_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: priority; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.priority (
    title text NOT NULL,
    color text NOT NULL,
    id bigint NOT NULL,
    user_id bigint NOT NULL
);


ALTER TABLE public.priority OWNER TO postgres;

--
-- Name: priority_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.priority ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.priority_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: role_data; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.role_data (
    id bigint NOT NULL,
    name text NOT NULL
);


ALTER TABLE public.role_data OWNER TO postgres;

--
-- Name: role_data_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.role_data ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.role_data_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: stat; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.stat (
    id bigint NOT NULL,
    completed_total bigint,
    uncompleted_total bigint,
    user_id bigint NOT NULL
);


ALTER TABLE public.stat OWNER TO postgres;

--
-- Name: stat_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.stat ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.stat_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: task; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.task (
    title text NOT NULL,
    completed numeric NOT NULL,
    task_date timestamp without time zone,
    id bigint NOT NULL,
    category_id bigint,
    priority_id bigint,
    user_id bigint NOT NULL
);


ALTER TABLE public.task OWNER TO postgres;

--
-- Name: task_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.task ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.task_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: user_data; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_data (
    email text NOT NULL,
    userpassword text NOT NULL,
    username text NOT NULL,
    id bigint NOT NULL
);


ALTER TABLE public.user_data OWNER TO postgres;

--
-- Name: user_data_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.user_data ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.user_data_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: user_role; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_role (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    role_id bigint NOT NULL
);


ALTER TABLE public.user_role OWNER TO postgres;

--
-- Name: user_role_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.user_role ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.user_role_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Data for Name: activity; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.activity (id, uuid, activated, user_id) FROM stdin;
\.


--
-- Data for Name: category; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.category (title, id, user_id, completed_count, uncompleted_count) FROM stdin;
\.


--
-- Data for Name: priority; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.priority (title, color, id, user_id) FROM stdin;
\.


--
-- Data for Name: role_data; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.role_data (id, name) FROM stdin;
1	ADMIN
2	USER
\.


--
-- Data for Name: stat; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.stat (id, completed_total, uncompleted_total, user_id) FROM stdin;
\.


--
-- Data for Name: task; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.task (title, completed, task_date, id, category_id, priority_id, user_id) FROM stdin;
\.


--
-- Data for Name: user_data; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_data (email, userpassword, username, id) FROM stdin;
\.


--
-- Data for Name: user_role; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_role (id, user_id, role_id) FROM stdin;
\.


--
-- Name: activity_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.activity_id_seq', 10000, true);


--
-- Name: category_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.category_id_seq', 60000, true);


--
-- Name: priority_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.priority_id_seq', 30000, true);


--
-- Name: role_data_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.role_data_id_seq', 2, true);


--
-- Name: stat_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.stat_id_seq', 10000, true);


--
-- Name: task_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.task_id_seq', 50000, true);


--
-- Name: user_data_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.user_data_id_seq', 10000, true);


--
-- Name: user_role_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.user_role_id_seq', 10000, true);


--
-- Name: activity activity_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity
    ADD CONSTRAINT activity_pkey PRIMARY KEY (id);


--
-- Name: activity activity_user_id_uniq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity
    ADD CONSTRAINT activity_user_id_uniq UNIQUE (user_id);


--
-- Name: category category_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.category
    ADD CONSTRAINT category_pkey PRIMARY KEY (id);


--
-- Name: priority priority_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.priority
    ADD CONSTRAINT priority_pkey PRIMARY KEY (id);


--
-- Name: role_data role_data_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role_data
    ADD CONSTRAINT role_data_pkey PRIMARY KEY (id);


--
-- Name: stat stat_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.stat
    ADD CONSTRAINT stat_pkey PRIMARY KEY (id);


--
-- Name: stat stat_user_id_uniq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.stat
    ADD CONSTRAINT stat_user_id_uniq UNIQUE (user_id);


--
-- Name: task task_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task
    ADD CONSTRAINT task_pkey PRIMARY KEY (id);


--
-- Name: user_data user_data_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_data
    ADD CONSTRAINT user_data_pkey PRIMARY KEY (id);


--
-- Name: user_role user_role_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_role
    ADD CONSTRAINT user_role_pkey PRIMARY KEY (id);


--
-- Name: activity_activated_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX activity_activated_index ON public.activity USING btree (activated);


--
-- Name: activity_user_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX activity_user_id_index ON public.activity USING btree (user_id);


--
-- Name: activity_uuid_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX activity_uuid_index ON public.activity USING btree (uuid);


--
-- Name: category_title_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX category_title_index ON public.category USING btree (title);


--
-- Name: task_category_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX task_category_id_index ON public.task USING btree (category_id);


--
-- Name: task_title_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX task_title_index ON public.task USING btree (title);


--
-- Name: task_user_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX task_user_id_index ON public.task USING btree (user_id);


--
-- Name: user_data_username_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX user_data_username_index ON public.user_data USING btree (username);


--
-- Name: task add_task_stat; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER add_task_stat AFTER INSERT ON public.task FOR EACH ROW EXECUTE FUNCTION public.add_task();


--
-- Name: task delete_task_stat; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER delete_task_stat AFTER DELETE ON public.task FOR EACH ROW EXECUTE FUNCTION public.delete_task();


--
-- Name: user_data new_user_gen_data; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER new_user_gen_data AFTER INSERT ON public.user_data FOR EACH ROW EXECUTE FUNCTION public.new_user_data();


--
-- Name: task update_task_stat; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_task_stat AFTER UPDATE ON public.task FOR EACH ROW EXECUTE FUNCTION public.update_task();


--
-- Name: task category_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task
    ADD CONSTRAINT category_fkey FOREIGN KEY (category_id) REFERENCES public.category(id) ON DELETE SET NULL NOT VALID;


--
-- Name: task priority_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task
    ADD CONSTRAINT priority_fkey FOREIGN KEY (priority_id) REFERENCES public.priority(id) ON DELETE SET NULL NOT VALID;


--
-- Name: user_role role_data_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_role
    ADD CONSTRAINT role_data_fkey FOREIGN KEY (role_id) REFERENCES public.role_data(id) ON DELETE RESTRICT NOT VALID;


--
-- Name: user_role user_data_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_role
    ADD CONSTRAINT user_data_fkey FOREIGN KEY (user_id) REFERENCES public.user_data(id) ON DELETE CASCADE NOT VALID;


--
-- Name: stat user_data_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.stat
    ADD CONSTRAINT user_data_fkey FOREIGN KEY (user_id) REFERENCES public.user_data(id) ON DELETE CASCADE NOT VALID;


--
-- Name: task user_data_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task
    ADD CONSTRAINT user_data_fkey FOREIGN KEY (user_id) REFERENCES public.user_data(id) ON DELETE CASCADE NOT VALID;


--
-- Name: category user_data_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.category
    ADD CONSTRAINT user_data_fkey FOREIGN KEY (user_id) REFERENCES public.user_data(id) ON DELETE CASCADE NOT VALID;


--
-- Name: priority user_data_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.priority
    ADD CONSTRAINT user_data_fkey FOREIGN KEY (user_id) REFERENCES public.user_data(id) ON DELETE CASCADE NOT VALID;


--
-- Name: activity user_data_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity
    ADD CONSTRAINT user_data_fkey FOREIGN KEY (user_id) REFERENCES public.user_data(id) ON DELETE CASCADE NOT VALID;


--
-- PostgreSQL database dump complete
--

