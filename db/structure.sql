--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: cforum; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA cforum;


--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: hstore; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public;


--
-- Name: EXTENSION hstore; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION hstore IS 'data type for storing sets of (key, value) pairs';


SET search_path = cforum, pg_catalog;

--
-- Name: count_messages_delete_trigger(); Type: FUNCTION; Schema: cforum; Owner: -
--

CREATE FUNCTION count_messages_delete_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO
    cforum.counter_table (table_name, difference, group_crit)
  VALUES
    ('messages', -1, OLD.forum_id);

  RETURN NULL;
END;
$$;


--
-- Name: count_messages_insert_forum_trigger(); Type: FUNCTION; Schema: cforum; Owner: -
--

CREATE FUNCTION count_messages_insert_forum_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO
    cforum.counter_table (table_name, group_crit, difference)
    VALUES ('messages', NEW.forum_id, 0);

  RETURN NULL;
END;
$$;


--
-- Name: count_messages_insert_trigger(); Type: FUNCTION; Schema: cforum; Owner: -
--

CREATE FUNCTION count_messages_insert_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO
    cforum.counter_table (table_name, difference, group_crit)
  VALUES
    ('messages', +1, NEW.forum_id);

  RETURN NULL;
END;
$$;


--
-- Name: count_messages_truncate_trigger(); Type: FUNCTION; Schema: cforum; Owner: -
--

CREATE FUNCTION count_messages_truncate_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  DELETE FROM
    cforum.counter_table
  WHERE
    table_name = 'messages';

  INSERT INTO cforum.counter_table (table_name, difference, group_crit)
    SELECT 'messages', 0, forum_id FROM cforum.forums;

  RETURN NULL;
END;
$$;


--
-- Name: count_threads_delete_trigger(); Type: FUNCTION; Schema: cforum; Owner: -
--

CREATE FUNCTION count_threads_delete_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO
    cforum.counter_table (table_name, difference, group_crit)
  VALUES
    (TG_TABLE_NAME, -1, OLD.forum_id);

  RETURN NULL;
END;
$$;


--
-- Name: count_threads_insert_forum_trigger(); Type: FUNCTION; Schema: cforum; Owner: -
--

CREATE FUNCTION count_threads_insert_forum_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO
    cforum.counter_table (table_name, group_crit, difference)
    VALUES ('threads', NEW.forum_id, 0);

  RETURN NULL;
END;
$$;


--
-- Name: count_threads_insert_trigger(); Type: FUNCTION; Schema: cforum; Owner: -
--

CREATE FUNCTION count_threads_insert_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO
    cforum.counter_table (table_name, difference, group_crit)
  VALUES
    (TG_TABLE_NAME, +1, NEW.forum_id);

  RETURN NULL;
END;
$$;


--
-- Name: count_threads_truncate_trigger(); Type: FUNCTION; Schema: cforum; Owner: -
--

CREATE FUNCTION count_threads_truncate_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  DELETE FROM
    cforum.counter_table
  WHERE
    table_name = 'threads';

  INSERT INTO cforum.counter_table (table_name, difference, group_crit)
    SELECT 'threads', 0, forum_id FROM cforum.forums;

  RETURN NULL;
END;
$$;


--
-- Name: counter_table_get_count(name, bigint); Type: FUNCTION; Schema: cforum; Owner: -
--

CREATE FUNCTION counter_table_get_count(v_table_name name, v_group_crit bigint) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_table_n NAME := quote_ident(v_table_name);
  v_sum BIGINT;
  v_nr BIGINT;
BEGIN
  SELECT
    COUNT(*), SUM(difference)
  FROM
    cforum.counter_table
  WHERE
      table_name = v_table_name
    AND
      ((v_group_crit IS NULL AND group_crit IS NULL) OR (v_group_crit IS NOT NULL AND group_crit = v_group_crit))
  INTO v_nr, v_sum;

  IF v_sum IS NULL THEN
    RAISE EXCEPTION 'table_count: count on uncounted table';
  END IF;

  /*
   * We only sum up if we encounter a big enough amount of rows so summing
   * is a real benefit.
   */
  IF v_nr > 100 THEN
    DECLARE
      v_cur_id BIGINT;
      v_cur_difference BIGINT;
      v_new_sum BIGINT := 0;
      v_delete_ids BIGINT[];

    BEGIN
      RAISE NOTICE 'table_count: summing counter';

      FOR v_cur_id, v_cur_difference IN
        SELECT count_id, difference
        FROM
          cforum.counter_table
        WHERE
            table_name = v_table_name
          AND
            ((v_group_crit IS NULL AND group_crit IS NULL) OR (v_group_crit IS NOT NULL AND group_crit = v_group_crit))
        ORDER BY
          count_id
        FOR UPDATE NOWAIT
      LOOP
        --collecting ids instead of doing every single delete is more efficient
        v_delete_ids := v_delete_ids || v_cur_id;
        v_new_sum := v_new_sum + v_cur_difference;

        IF array_length(v_delete_ids, 1) > 100 THEN
          DELETE FROM cforum.counter_table WHERE count_id = ANY(v_delete_ids);
          v_delete_ids = '{}';
        END IF;

      END LOOP;

      DELETE FROM cforum.counter_table WHERE count_id = ANY(v_delete_ids);
      INSERT INTO cforum.counter_table(table_name, group_crit, difference) VALUES(v_table_name, v_group_crit, v_new_sum);

    EXCEPTION
      --if somebody else summed up in a transaction which was open at the
      --same time we ran the above statement
      WHEN lock_not_available THEN
        RAISE NOTICE 'table_count: locking failed';
      --if somebody else summed up in a transaction which has committed
      --successfully
      WHEN serialization_failure THEN
        RAISE NOTICE 'table_count: serialization failed';
      --summing up won't work in a readonly transaction. One could check
      --that explicitly
      WHEN read_only_sql_transaction THEN
        RAISE NOTICE 'table_count: not summing because in read only txn';
    END;
  END IF;

  RETURN v_sum;
END;
$$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: access; Type: TABLE; Schema: cforum; Owner: -; Tablespace: 
--

CREATE TABLE access (
    user_id bigint,
    forum_id bigint,
    access_id bigint NOT NULL
);


--
-- Name: access_access_id_seq; Type: SEQUENCE; Schema: cforum; Owner: -
--

CREATE SEQUENCE access_access_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: access_access_id_seq; Type: SEQUENCE OWNED BY; Schema: cforum; Owner: -
--

ALTER SEQUENCE access_access_id_seq OWNED BY access.access_id;


--
-- Name: counter_table; Type: TABLE; Schema: cforum; Owner: -; Tablespace: 
--

CREATE TABLE counter_table (
    count_id bigint NOT NULL,
    table_name name NOT NULL,
    group_crit bigint,
    difference bigint NOT NULL
);


--
-- Name: counter_table_count_id_seq; Type: SEQUENCE; Schema: cforum; Owner: -
--

CREATE SEQUENCE counter_table_count_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: counter_table_count_id_seq; Type: SEQUENCE OWNED BY; Schema: cforum; Owner: -
--

ALTER SEQUENCE counter_table_count_id_seq OWNED BY counter_table.count_id;


--
-- Name: forums; Type: TABLE; Schema: cforum; Owner: -; Tablespace: 
--

CREATE TABLE forums (
    slug character varying(255) NOT NULL,
    name character varying(255),
    short_name character varying(255),
    description text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    forum_id bigint NOT NULL,
    public boolean
);


--
-- Name: forums_forum_id_seq; Type: SEQUENCE; Schema: cforum; Owner: -
--

CREATE SEQUENCE forums_forum_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: forums_forum_id_seq; Type: SEQUENCE OWNED BY; Schema: cforum; Owner: -
--

ALTER SEQUENCE forums_forum_id_seq OWNED BY forums.forum_id;


--
-- Name: messages; Type: TABLE; Schema: cforum; Owner: -; Tablespace: 
--

CREATE TABLE messages (
    thread_id bigint NOT NULL,
    mid bigint,
    subject text NOT NULL,
    content text NOT NULL,
    author text NOT NULL,
    email text,
    homepage text,
    upvotes integer DEFAULT 0 NOT NULL,
    downvotes integer DEFAULT 0 NOT NULL,
    user_id bigint,
    parent_id bigint,
    deleted boolean DEFAULT false,
    flags public.hstore,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    message_id bigint NOT NULL,
    forum_id bigint NOT NULL
);


--
-- Name: messages_message_id_seq; Type: SEQUENCE; Schema: cforum; Owner: -
--

CREATE SEQUENCE messages_message_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: messages_message_id_seq; Type: SEQUENCE OWNED BY; Schema: cforum; Owner: -
--

ALTER SEQUENCE messages_message_id_seq OWNED BY messages.message_id;


--
-- Name: moderators; Type: TABLE; Schema: cforum; Owner: -; Tablespace: 
--

CREATE TABLE moderators (
    user_id bigint,
    forum_id bigint,
    moderator_id bigint NOT NULL
);


--
-- Name: moderators_moderator_id_seq; Type: SEQUENCE; Schema: cforum; Owner: -
--

CREATE SEQUENCE moderators_moderator_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: moderators_moderator_id_seq; Type: SEQUENCE OWNED BY; Schema: cforum; Owner: -
--

ALTER SEQUENCE moderators_moderator_id_seq OWNED BY moderators.moderator_id;


--
-- Name: settings; Type: TABLE; Schema: cforum; Owner: -; Tablespace: 
--

CREATE TABLE settings (
    forum_id bigint,
    user_id bigint,
    name character varying(255) NOT NULL,
    value character varying(255),
    setting_id bigint NOT NULL
);


--
-- Name: settings_setting_id_seq; Type: SEQUENCE; Schema: cforum; Owner: -
--

CREATE SEQUENCE settings_setting_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: settings_setting_id_seq; Type: SEQUENCE OWNED BY; Schema: cforum; Owner: -
--

ALTER SEQUENCE settings_setting_id_seq OWNED BY settings.setting_id;


--
-- Name: threads; Type: TABLE; Schema: cforum; Owner: -; Tablespace: 
--

CREATE TABLE threads (
    slug character varying(255) NOT NULL,
    forum_id bigint NOT NULL,
    tid bigint,
    archived boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    thread_id bigint NOT NULL,
    message_id integer
);


--
-- Name: threads_thread_id_seq; Type: SEQUENCE; Schema: cforum; Owner: -
--

CREATE SEQUENCE threads_thread_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: threads_thread_id_seq; Type: SEQUENCE OWNED BY; Schema: cforum; Owner: -
--

ALTER SEQUENCE threads_thread_id_seq OWNED BY threads.thread_id;


--
-- Name: users; Type: TABLE; Schema: cforum; Owner: -; Tablespace: 
--

CREATE TABLE users (
    username character varying(255) NOT NULL,
    email character varying(255),
    crypted_password character varying(255),
    salt character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    last_login_at timestamp without time zone,
    last_logout_at timestamp without time zone,
    user_id bigint NOT NULL,
    admin character varying(255),
    active boolean
);


--
-- Name: users_user_id_seq; Type: SEQUENCE; Schema: cforum; Owner: -
--

CREATE SEQUENCE users_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_user_id_seq; Type: SEQUENCE OWNED BY; Schema: cforum; Owner: -
--

ALTER SEQUENCE users_user_id_seq OWNED BY users.user_id;


SET search_path = public, pg_catalog;

--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);


SET search_path = cforum, pg_catalog;

--
-- Name: access_id; Type: DEFAULT; Schema: cforum; Owner: -
--

ALTER TABLE ONLY access ALTER COLUMN access_id SET DEFAULT nextval('access_access_id_seq'::regclass);


--
-- Name: count_id; Type: DEFAULT; Schema: cforum; Owner: -
--

ALTER TABLE ONLY counter_table ALTER COLUMN count_id SET DEFAULT nextval('counter_table_count_id_seq'::regclass);


--
-- Name: forum_id; Type: DEFAULT; Schema: cforum; Owner: -
--

ALTER TABLE ONLY forums ALTER COLUMN forum_id SET DEFAULT nextval('forums_forum_id_seq'::regclass);


--
-- Name: message_id; Type: DEFAULT; Schema: cforum; Owner: -
--

ALTER TABLE ONLY messages ALTER COLUMN message_id SET DEFAULT nextval('messages_message_id_seq'::regclass);


--
-- Name: moderator_id; Type: DEFAULT; Schema: cforum; Owner: -
--

ALTER TABLE ONLY moderators ALTER COLUMN moderator_id SET DEFAULT nextval('moderators_moderator_id_seq'::regclass);


--
-- Name: setting_id; Type: DEFAULT; Schema: cforum; Owner: -
--

ALTER TABLE ONLY settings ALTER COLUMN setting_id SET DEFAULT nextval('settings_setting_id_seq'::regclass);


--
-- Name: thread_id; Type: DEFAULT; Schema: cforum; Owner: -
--

ALTER TABLE ONLY threads ALTER COLUMN thread_id SET DEFAULT nextval('threads_thread_id_seq'::regclass);


--
-- Name: user_id; Type: DEFAULT; Schema: cforum; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN user_id SET DEFAULT nextval('users_user_id_seq'::regclass);


--
-- Name: access_pkey; Type: CONSTRAINT; Schema: cforum; Owner: -; Tablespace: 
--

ALTER TABLE ONLY access
    ADD CONSTRAINT access_pkey PRIMARY KEY (access_id);


--
-- Name: counter_table_pkey; Type: CONSTRAINT; Schema: cforum; Owner: -; Tablespace: 
--

ALTER TABLE ONLY counter_table
    ADD CONSTRAINT counter_table_pkey PRIMARY KEY (count_id);


--
-- Name: forums_pkey; Type: CONSTRAINT; Schema: cforum; Owner: -; Tablespace: 
--

ALTER TABLE ONLY forums
    ADD CONSTRAINT forums_pkey PRIMARY KEY (forum_id);


--
-- Name: messages_pkey; Type: CONSTRAINT; Schema: cforum; Owner: -; Tablespace: 
--

ALTER TABLE ONLY messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (message_id);


--
-- Name: moderators_pkey; Type: CONSTRAINT; Schema: cforum; Owner: -; Tablespace: 
--

ALTER TABLE ONLY moderators
    ADD CONSTRAINT moderators_pkey PRIMARY KEY (moderator_id);


--
-- Name: settings_pkey; Type: CONSTRAINT; Schema: cforum; Owner: -; Tablespace: 
--

ALTER TABLE ONLY settings
    ADD CONSTRAINT settings_pkey PRIMARY KEY (setting_id);


--
-- Name: threads_pkey; Type: CONSTRAINT; Schema: cforum; Owner: -; Tablespace: 
--

ALTER TABLE ONLY threads
    ADD CONSTRAINT threads_pkey PRIMARY KEY (thread_id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: cforum; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- Name: counter_table_table_name_group_crit_idx; Type: INDEX; Schema: cforum; Owner: -; Tablespace: 
--

CREATE INDEX counter_table_table_name_group_crit_idx ON counter_table USING btree (table_name, group_crit);


--
-- Name: index_cforum.forums_on_slug; Type: INDEX; Schema: cforum; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX "index_cforum.forums_on_slug" ON forums USING btree (slug);


--
-- Name: index_cforum.messages_on_forum_id_and_updated_at; Type: INDEX; Schema: cforum; Owner: -; Tablespace: 
--

CREATE INDEX "index_cforum.messages_on_forum_id_and_updated_at" ON messages USING btree (forum_id, updated_at);


--
-- Name: index_cforum.messages_on_mid; Type: INDEX; Schema: cforum; Owner: -; Tablespace: 
--

CREATE INDEX "index_cforum.messages_on_mid" ON messages USING btree (mid);


--
-- Name: index_cforum.messages_on_thread_id; Type: INDEX; Schema: cforum; Owner: -; Tablespace: 
--

CREATE INDEX "index_cforum.messages_on_thread_id" ON messages USING btree (thread_id);


--
-- Name: index_cforum.settings_on_forum_id; Type: INDEX; Schema: cforum; Owner: -; Tablespace: 
--

CREATE INDEX "index_cforum.settings_on_forum_id" ON settings USING btree (forum_id);


--
-- Name: index_cforum.settings_on_name; Type: INDEX; Schema: cforum; Owner: -; Tablespace: 
--

CREATE INDEX "index_cforum.settings_on_name" ON settings USING btree (name);


--
-- Name: index_cforum.settings_on_user_id; Type: INDEX; Schema: cforum; Owner: -; Tablespace: 
--

CREATE INDEX "index_cforum.settings_on_user_id" ON settings USING btree (user_id);


--
-- Name: index_cforum.threads_on_archived; Type: INDEX; Schema: cforum; Owner: -; Tablespace: 
--

CREATE INDEX "index_cforum.threads_on_archived" ON threads USING btree (archived);


--
-- Name: index_cforum.threads_on_created_at; Type: INDEX; Schema: cforum; Owner: -; Tablespace: 
--

CREATE INDEX "index_cforum.threads_on_created_at" ON threads USING btree (created_at);


--
-- Name: index_cforum.threads_on_forum_id; Type: INDEX; Schema: cforum; Owner: -; Tablespace: 
--

CREATE INDEX "index_cforum.threads_on_forum_id" ON threads USING btree (forum_id);


--
-- Name: index_cforum.threads_on_slug; Type: INDEX; Schema: cforum; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX "index_cforum.threads_on_slug" ON threads USING btree (slug);


--
-- Name: index_cforum.threads_on_tid; Type: INDEX; Schema: cforum; Owner: -; Tablespace: 
--

CREATE INDEX "index_cforum.threads_on_tid" ON threads USING btree (tid);


--
-- Name: index_cforum.users_on_username; Type: INDEX; Schema: cforum; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX "index_cforum.users_on_username" ON users USING btree (username);


SET search_path = public, pg_catalog;

--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


SET search_path = cforum, pg_catalog;

--
-- Name: messages__count_delete_trigger; Type: TRIGGER; Schema: cforum; Owner: -
--

CREATE TRIGGER messages__count_delete_trigger AFTER DELETE ON messages FOR EACH ROW EXECUTE PROCEDURE count_messages_delete_trigger();


--
-- Name: messages__count_insert_forum_trigger; Type: TRIGGER; Schema: cforum; Owner: -
--

CREATE TRIGGER messages__count_insert_forum_trigger AFTER INSERT ON forums FOR EACH ROW EXECUTE PROCEDURE count_messages_insert_forum_trigger();


--
-- Name: messages__count_insert_trigger; Type: TRIGGER; Schema: cforum; Owner: -
--

CREATE TRIGGER messages__count_insert_trigger AFTER INSERT ON messages FOR EACH ROW EXECUTE PROCEDURE count_messages_insert_trigger();


--
-- Name: messages__count_truncate_trigger; Type: TRIGGER; Schema: cforum; Owner: -
--

CREATE TRIGGER messages__count_truncate_trigger AFTER TRUNCATE ON messages FOR EACH STATEMENT EXECUTE PROCEDURE count_messages_truncate_trigger();


--
-- Name: threads__count_delete_trigger; Type: TRIGGER; Schema: cforum; Owner: -
--

CREATE TRIGGER threads__count_delete_trigger AFTER DELETE ON threads FOR EACH ROW EXECUTE PROCEDURE count_threads_delete_trigger();


--
-- Name: threads__count_insert_forum_trigger; Type: TRIGGER; Schema: cforum; Owner: -
--

CREATE TRIGGER threads__count_insert_forum_trigger AFTER INSERT ON forums FOR EACH ROW EXECUTE PROCEDURE count_threads_insert_forum_trigger();


--
-- Name: threads__count_insert_trigger; Type: TRIGGER; Schema: cforum; Owner: -
--

CREATE TRIGGER threads__count_insert_trigger AFTER INSERT ON threads FOR EACH ROW EXECUTE PROCEDURE count_threads_insert_trigger();


--
-- Name: threads__count_truncate_trigger; Type: TRIGGER; Schema: cforum; Owner: -
--

CREATE TRIGGER threads__count_truncate_trigger AFTER TRUNCATE ON threads FOR EACH STATEMENT EXECUTE PROCEDURE count_threads_truncate_trigger();


--
-- Name: forum_id_fkey; Type: FK CONSTRAINT; Schema: cforum; Owner: -
--

ALTER TABLE ONLY threads
    ADD CONSTRAINT forum_id_fkey FOREIGN KEY (forum_id) REFERENCES forums(forum_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: forum_id_fkey; Type: FK CONSTRAINT; Schema: cforum; Owner: -
--

ALTER TABLE ONLY settings
    ADD CONSTRAINT forum_id_fkey FOREIGN KEY (forum_id) REFERENCES forums(forum_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: forum_id_fkey; Type: FK CONSTRAINT; Schema: cforum; Owner: -
--

ALTER TABLE ONLY moderators
    ADD CONSTRAINT forum_id_fkey FOREIGN KEY (forum_id) REFERENCES forums(forum_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: forum_id_fkey; Type: FK CONSTRAINT; Schema: cforum; Owner: -
--

ALTER TABLE ONLY access
    ADD CONSTRAINT forum_id_fkey FOREIGN KEY (forum_id) REFERENCES forums(forum_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: forum_id_fkey; Type: FK CONSTRAINT; Schema: cforum; Owner: -
--

ALTER TABLE ONLY messages
    ADD CONSTRAINT forum_id_fkey FOREIGN KEY (forum_id) REFERENCES forums(forum_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: message_id_fkey; Type: FK CONSTRAINT; Schema: cforum; Owner: -
--

ALTER TABLE ONLY threads
    ADD CONSTRAINT message_id_fkey FOREIGN KEY (message_id) REFERENCES messages(message_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: parent_id_fkey; Type: FK CONSTRAINT; Schema: cforum; Owner: -
--

ALTER TABLE ONLY messages
    ADD CONSTRAINT parent_id_fkey FOREIGN KEY (parent_id) REFERENCES messages(message_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: thread_id_fkey; Type: FK CONSTRAINT; Schema: cforum; Owner: -
--

ALTER TABLE ONLY messages
    ADD CONSTRAINT thread_id_fkey FOREIGN KEY (thread_id) REFERENCES threads(thread_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: user_id_fkey; Type: FK CONSTRAINT; Schema: cforum; Owner: -
--

ALTER TABLE ONLY messages
    ADD CONSTRAINT user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: user_id_fkey; Type: FK CONSTRAINT; Schema: cforum; Owner: -
--

ALTER TABLE ONLY settings
    ADD CONSTRAINT user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: user_id_fkey; Type: FK CONSTRAINT; Schema: cforum; Owner: -
--

ALTER TABLE ONLY moderators
    ADD CONSTRAINT user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: user_id_fkey; Type: FK CONSTRAINT; Schema: cforum; Owner: -
--

ALTER TABLE ONLY access
    ADD CONSTRAINT user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--



SET search_path = public, pg_catalog;

INSERT INTO schema_migrations (version) VALUES ('1');

INSERT INTO schema_migrations (version) VALUES ('10');

INSERT INTO schema_migrations (version) VALUES ('11');

INSERT INTO schema_migrations (version) VALUES ('12');

INSERT INTO schema_migrations (version) VALUES ('13');

INSERT INTO schema_migrations (version) VALUES ('14');

INSERT INTO schema_migrations (version) VALUES ('15');

INSERT INTO schema_migrations (version) VALUES ('2');

INSERT INTO schema_migrations (version) VALUES ('3');

INSERT INTO schema_migrations (version) VALUES ('4');

INSERT INTO schema_migrations (version) VALUES ('6');

INSERT INTO schema_migrations (version) VALUES ('7');

INSERT INTO schema_migrations (version) VALUES ('8');

INSERT INTO schema_migrations (version) VALUES ('9');