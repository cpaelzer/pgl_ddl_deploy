
SET client_min_messages = warning;
DO $$
BEGIN

IF current_setting('server_version_num')::INT >= 100000 THEN
SET session_replication_role TO replica;
ELSE
CREATE EXTENSION pglogical;
END IF;

END$$;
CREATE EXTENSION pgl_ddl_deploy;

CREATE OR REPLACE FUNCTION pgl_ddl_deploy.override() RETURNS BOOLEAN AS $BODY$
BEGIN
RETURN TRUE;
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE;

INSERT INTO pgl_ddl_deploy.queue (queued_at,role,pubnames,message_type,message)
VALUES (now(),current_role,'{mock}'::TEXT[],pgl_ddl_deploy.queue_ddl_message_type(),'CREATE TABLE nativerox(id int)');

INSERT INTO pgl_ddl_deploy.queue (queued_at,role,pubnames,message_type,message)
VALUES (now(),current_role,'{mock}'::TEXT[],pgl_ddl_deploy.queue_ddl_message_type(),'ALTER TABLE nativerox ADD COLUMN bar text;');

INSERT INTO pgl_ddl_deploy.queue (queued_at,role,pubnames,message_type,message)
VALUES (now(),current_role,'{mock}'::TEXT[],pgl_ddl_deploy.queue_ddl_message_type(),$$SELECT pgl_ddl_deploy.notify_subscription_refresh('mock', true);$$);

DO $$
DECLARE v_ct INT;
BEGIN

IF current_setting('server_version_num')::INT >= 100000 THEN
    SELECT COUNT(1) INTO v_ct FROM information_schema.columns WHERE table_name = 'nativerox';
    RAISE LOG 'v_ct: %', v_ct;
    IF v_ct != 2 THEN
        RAISE EXCEPTION 'Count does not match expected: v_ct: %', v_ct;
    END IF;
    SELECT COUNT(1) INTO v_ct FROM pgl_ddl_deploy.subscriber_logs;
    RAISE LOG 'v_ct: %', v_ct;
    IF v_ct != 1 THEN
        RAISE EXCEPTION 'Count does not match expected: v_ct: %', v_ct;
    END IF;
    PERFORM pgl_ddl_deploy.retry_all_subscriber_logs(); 
    SELECT (SELECT COUNT(1) FROM pgl_ddl_deploy.subscriber_logs WHERE NOT succeeded) +
    (SELECT COUNT(1) FROM pgl_ddl_deploy.subscriber_logs WHERE error_message ~* 'No subscription to publication mock exists') INTO v_ct; 
    RAISE LOG 'v_ct: %', v_ct;
    IF v_ct != 3 THEN
        RAISE EXCEPTION 'Count does not match expected: v_ct: %', v_ct;
    END IF;
ELSE
    SELECT COUNT(1) INTO v_ct FROM pgl_ddl_deploy.subscriber_logs;
    RAISE LOG 'v_ct: %', v_ct;
    IF v_ct != 0 THEN
        RAISE EXCEPTION 'Count does not match expected: v_ct: %', v_ct;
    END IF;
END IF;

END$$;
