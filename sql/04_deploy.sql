--These will show different warnings depending on version 
SET client_min_messages = error;
\set VERBOSITY TERSE
/***
No deploy allowed if table would be added to replication
***/
SET ROLE test_pgl_ddl_deploy;
CREATE TABLE foo(id serial primary key);
SET ROLE postgres;
SELECT pgl_ddl_deploy.deploy('test1');
SET ROLE test_pgl_ddl_deploy;
DROP TABLE foo;
SET ROLE postgres;

--This should work now
SELECT pgl_ddl_deploy.deploy('test1');
--This should work
SELECT pgl_ddl_deploy.disable('test1');

--This should not work
SET ROLE test_pgl_ddl_deploy;
CREATE TABLE foo(id serial primary key);
SET ROLE postgres;
SELECT pgl_ddl_deploy.enable('test1');
SET ROLE test_pgl_ddl_deploy;
DROP TABLE foo;
SET ROLE postgres;

--This should work now
SELECT pgl_ddl_deploy.enable('test1');

--Enable all the rest
DO $$
DECLARE v_rec RECORD;
BEGIN

FOR v_rec IN
    SELECT name
    FROM pgl_ddl_deploy.rep_set_wrapper() 
    WHERE name LIKE 'test%' AND name <> 'test1'
    ORDER BY name
LOOP

PERFORM pgl_ddl_deploy.deploy(v_rec.name);

END LOOP;

END$$;
