/*Удаление всех пользователей и всех их данных*/
TRUNCATE public.user_data CASCADE;
/*Сброс счетчиков первичных ключей*/
ALTER SEQUENCE category_id_seq RESTART WITH 1;
ALTER SEQUENCE priority_id_seq RESTART WITH 1;
ALTER SEQUENCE stat_id_seq RESTART WITH 1;
ALTER SEQUENCE task_id_seq RESTART WITH 1;
ALTER SEQUENCE user_data_id_seq RESTART WITH 1;
ALTER SEQUENCE user_role_id_seq RESTART WITH 1;
ALTER SEQUENCE activity_id_seq RESTART WITH 1;
/*Вставка данных*/  
DO $GEN_DATA$
BEGIN
FOR i IN 1..10000 LOOP
RAISE NOTICE 'Добавлена строка номер: %', i;
EXECUTE $$ INSERT INTO public.user_data(email, username, userpassword) VALUES (
'email' || $1 || '@gmail.com', 'username' || $1, gen_random_uuid ()) returning id; $$
USING i;
END LOOP;
END;
$GEN_DATA$
