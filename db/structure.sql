--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

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


SET search_path = public, pg_catalog;

--
-- Name: badge_medal_type_t; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE badge_medal_type_t AS ENUM (
    'bronze',
    'silver',
    'gold'
);


--
-- Name: count_messages_delete_trigger(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION count_messages_delete_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO
    counter_table (table_name, difference, group_crit)
  VALUES
    ('messages', -1, OLD.forum_id);

  RETURN NULL;
END;
$$;


--
-- Name: count_messages_insert_forum_trigger(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION count_messages_insert_forum_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO
    counter_table (table_name, group_crit, difference)
    VALUES ('messages', NEW.forum_id, 0);

  RETURN NULL;
END;
$$;


--
-- Name: count_messages_insert_trigger(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION count_messages_insert_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO
    counter_table (table_name, difference, group_crit)
  VALUES
    ('messages', +1, NEW.forum_id);

  RETURN NULL;
END;
$$;


--
-- Name: count_messages_tag_delete_trigger(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION count_messages_tag_delete_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE tags SET num_messages = num_messages - 1 WHERE tag_id = OLD.tag_id;
  RETURN NULL;
END;
$$;


--
-- Name: count_messages_tag_insert_trigger(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION count_messages_tag_insert_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE tags SET num_messages = num_messages + 1 WHERE tag_id = NEW.tag_id;
  RETURN NEW;
END;
$$;


--
-- Name: count_messages_truncate_trigger(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION count_messages_truncate_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  DELETE FROM
    counter_table
  WHERE
    table_name = 'messages';

  INSERT INTO counter_table (table_name, difference, group_crit)
    SELECT 'messages', 0, forum_id FROM forums;

  RETURN NULL;
END;
$$;


--
-- Name: count_messages_update_trigger(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION count_messages_update_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  is_del_thread BOOLEAN;
BEGIN
  IF OLD.deleted = false AND NEW.deleted = true THEN
    INSERT INTO
      counter_table (table_name, difference, group_crit)
    VALUES
      ('messages', -1, NEW.forum_id);
  END IF;

  IF OLD.deleted = true AND NEW.deleted = false THEN
    INSERT INTO
      counter_table (table_name, difference, group_crit)
    VALUES
      ('messages', +1, NEW.forum_id);
  END IF;

  IF OLD.forum_id != NEW.forum_id THEN
    INSERT INTO
      counter_table (table_name, difference, group_crit)
    VALUES
      ('messages', -1, OLD.forum_id);

    INSERT INTO
      counter_table (table_name, difference, group_crit)
    VALUES
      ('messages', +1, NEW.forum_id);
  END IF;

  SELECT EXISTS(SELECT message_id FROM messages WHERE thread_id = NEW.thread_id AND deleted = false) INTO is_del_thread;
  IF is_del_thread THEN
    UPDATE threads SET deleted = false WHERE thread_id = NEW.thread_id;
  ELSE
    UPDATE threads SET deleted = true WHERE thread_id = NEW.thread_id;
  END IF;

  RETURN NULL;
END;
$$;


--
-- Name: count_threads_delete_trigger(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION count_threads_delete_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO
    counter_table (table_name, difference, group_crit)
  VALUES
    (TG_TABLE_NAME, -1, OLD.forum_id);

  RETURN NULL;
END;
$$;


--
-- Name: count_threads_insert_forum_trigger(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION count_threads_insert_forum_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO
    counter_table (table_name, group_crit, difference)
    VALUES ('threads', NEW.forum_id, 0);

  RETURN NULL;
END;
$$;


--
-- Name: count_threads_insert_trigger(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION count_threads_insert_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO
    counter_table (table_name, difference, group_crit)
  VALUES
    (TG_TABLE_NAME, +1, NEW.forum_id);

  RETURN NULL;
END;
$$;


--
-- Name: count_threads_truncate_trigger(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION count_threads_truncate_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  DELETE FROM
    counter_table
  WHERE
    table_name = 'threads';

  INSERT INTO counter_table (table_name, difference, group_crit)
    SELECT 'threads', 0, forum_id FROM forums;

  RETURN NULL;
END;
$$;


--
-- Name: count_threads_update_trigger(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION count_threads_update_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF OLD.deleted = false AND NEW.deleted = true THEN
    INSERT INTO
      counter_table (table_name, difference, group_crit)
    VALUES
      ('threads', -1, NEW.forum_id);
  END IF;

  IF OLD.deleted = true AND NEW.deleted = false THEN
    INSERT INTO
      counter_table (table_name, difference, group_crit)
    VALUES
      ('threads', +1, NEW.forum_id);
  END IF;

  IF OLD.forum_id != NEW.forum_id THEN
    INSERT INTO
      counter_table (table_name, difference, group_crit)
    VALUES
      ('threads', -1, OLD.forum_id);

    INSERT INTO
      counter_table (table_name, difference, group_crit)
    VALUES
      ('threads', +1, NEW.forum_id);
  END IF;

  RETURN NULL;
END;
$$;


--
-- Name: counter_table_get_count(name, bigint); Type: FUNCTION; Schema: public; Owner: -
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
    counter_table
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
          counter_table
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
          DELETE FROM counter_table WHERE count_id = ANY(v_delete_ids);
          v_delete_ids = '{}';
        END IF;

      END LOOP;

      DELETE FROM counter_table WHERE count_id = ANY(v_delete_ids);
      INSERT INTO counter_table(table_name, group_crit, difference) VALUES(v_table_name, v_group_crit, v_new_sum);

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


--
-- Name: gen_forum_stats(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gen_forum_stats(p_forum_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_min TIMESTAMP WITHOUT TIME ZONE;
  v_max TIMESTAMP WITHOUT TIME ZONE;
  v_now TIMESTAMP WITHOUT TIME ZONE;
BEGIN
  DELETE FROM forum_stats WHERE forum_id = p_forum_id;

  v_min := (SELECT MIN(DATE_TRUNC('day', created_at)) FROM messages WHERE forum_id = p_forum_id);
  v_max := (SELECT NOW());

  v_now := v_min;
  while v_now < v_max LOOP
    INSERT INTO forum_stats (forum_id, moment, messages, threads)
      VALUES (p_forum_id, v_now,
              (SELECT COUNT(*) FROM messages WHERE forum_id = p_forum_id AND deleted = false AND created_at BETWEEN v_now AND ((v_now + interval '1 day') - interval '1 second')),
              (SELECT COUNT(*) FROM threads WHERE forum_id = p_forum_id AND deleted = false AND created_at BETWEEN v_now AND ((v_now + interval '1 day') - interval '1 second')));
    v_now := v_now + INTERVAL '1 day';
  END LOOP;

  RETURN 0;
END;
$$;


--
-- Name: messages__thread_set_latest_insert(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION messages__thread_set_latest_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE threads SET latest_message = COALESCE((SELECT MAX(created_at) FROM messages WHERE thread_id = threads.thread_id AND deleted = false), '1970-01-01 00:00:00') WHERE thread_id = NEW.thread_id;
  RETURN NULL;
END;
$$;


--
-- Name: messages__thread_set_latest_update_delete(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION messages__thread_set_latest_update_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE threads SET latest_message = COALESCE((SELECT MAX(created_at) FROM messages WHERE thread_id = threads.thread_id AND deleted = false), '1970-01-01 00:00:00') WHERE thread_id = OLD.thread_id;
  RETURN NULL;
END;
$$;


--
-- Name: search_document_before_insert(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION search_document_before_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.ts_author = to_tsvector('simple', NEW.author);
  NEW.ts_title = to_tsvector(NEW.lang::regconfig, NEW.title);
  NEW.ts_content = to_tsvector(NEW.lang::regconfig, NEW.content);
  NEW.ts_document = setweight(to_tsvector(NEW.lang::regconfig, NEW.author), 'A')  || setweight(to_tsvector(NEW.lang::regconfig, NEW.title), 'B') || setweight(to_tsvector(NEW.lang::regconfig, NEW.content), 'B');

  RETURN NEW;
END;
$$;


--
-- Name: settings_unique_check__insert(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION settings_unique_check__insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NEW.user_id IS NOT NULL AND NEW.forum_id IS NULL THEN
    IF NEW.user_id IN (
        SELECT user_id FROM settings WHERE user_id = NEW.user_id AND forum_id IS NULL
      ) THEN
      RAISE EXCEPTION 'Uniqueness violation on column id (%)', NEW.setting_id;
    END IF;
  END IF;

  IF NEW.user_id IS NULL AND NEW.forum_id IS NOT NULL THEN
    IF NEW.forum_id IN (
        SELECT forum_id FROM settings WHERE forum_id = NEW.forum_id AND user_id IS NULL
      ) THEN
      RAISE EXCEPTION 'Uniqueness violation on column id (%)', NEW.setting_id;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;


--
-- Name: settings_unique_check__update(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION settings_unique_check__update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NEW.user_id IS NOT NULL AND NEW.forum_id IS NULL AND NEW.user_id != OLD.user_id THEN
    IF NEW.user_id IN (
        SELECT user_id FROM settings WHERE user_id = NEW.user_id AND forum_id IS NULL
      ) THEN
      RAISE EXCEPTION 'Uniqueness violation on column id (%)', NEW.setting_id;
    END IF;
  END IF;

  IF NEW.user_id IS NULL AND NEW.forum_id IS NOT NULL AND NEW.forum_id != OLD.forum_id THEN
    IF NEW.forum_id IN (
        SELECT forum_id FROM settings WHERE forum_id = NEW.forum_id AND user_id IS NULL
      ) THEN
      RAISE EXCEPTION 'Uniqueness violation on column id (%)', NEW.setting_id;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: auditing; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE auditing (
    auditing_id bigint NOT NULL,
    relation character varying(120) NOT NULL,
    relid bigint NOT NULL,
    act text NOT NULL,
    contents json NOT NULL,
    user_id integer,
    created_at timestamp without time zone NOT NULL
);


--
-- Name: auditing_auditing_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE auditing_auditing_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: auditing_auditing_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE auditing_auditing_id_seq OWNED BY auditing.auditing_id;


--
-- Name: badges; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE badges (
    badge_id integer NOT NULL,
    score_needed integer NOT NULL,
    name character varying NOT NULL,
    description text,
    slug character varying NOT NULL,
    badge_medal_type badge_medal_type_t DEFAULT 'bronze'::badge_medal_type_t NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    badge_type character varying(250) NOT NULL
);


--
-- Name: badges_badge_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE badges_badge_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: badges_badge_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE badges_badge_id_seq OWNED BY badges.badge_id;


--
-- Name: badges_users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE badges_users (
    badge_user_id bigint NOT NULL,
    user_id integer NOT NULL,
    badge_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: badges_users_badge_user_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE badges_users_badge_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: badges_users_badge_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE badges_users_badge_user_id_seq OWNED BY badges_users.badge_user_id;


--
-- Name: cites; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE cites (
    cite_id bigint NOT NULL,
    old_id integer,
    user_id integer,
    message_id integer,
    url text NOT NULL,
    author text NOT NULL,
    creator text,
    cite text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    cite_date timestamp without time zone NOT NULL,
    archived boolean DEFAULT false NOT NULL,
    creator_user_id integer
);


--
-- Name: cites_cite_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE cites_cite_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cites_cite_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE cites_cite_id_seq OWNED BY cites.cite_id;


--
-- Name: cites_votes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE cites_votes (
    cite_vote_id bigint NOT NULL,
    cite_id bigint NOT NULL,
    user_id integer NOT NULL,
    vote_type integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: cites_votes_cite_vote_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE cites_votes_cite_vote_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cites_votes_cite_vote_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE cites_votes_cite_vote_id_seq OWNED BY cites_votes.cite_vote_id;


--
-- Name: close_votes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE close_votes (
    close_vote_id bigint NOT NULL,
    message_id bigint NOT NULL,
    reason character varying(20) NOT NULL,
    duplicate_slug character varying(255),
    custom_reason character varying(255),
    finished boolean DEFAULT false NOT NULL,
    vote_type boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: close_votes_close_vote_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE close_votes_close_vote_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: close_votes_close_vote_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE close_votes_close_vote_id_seq OWNED BY close_votes.close_vote_id;


--
-- Name: close_votes_voters; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE close_votes_voters (
    close_votes_voter_id bigint NOT NULL,
    close_vote_id bigint NOT NULL,
    user_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: close_votes_voters_close_votes_voter_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE close_votes_voters_close_votes_voter_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: close_votes_voters_close_votes_voter_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE close_votes_voters_close_votes_voter_id_seq OWNED BY close_votes_voters.close_votes_voter_id;


--
-- Name: counter_table; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE counter_table (
    count_id bigint NOT NULL,
    table_name name NOT NULL,
    group_crit bigint,
    difference bigint NOT NULL
);


--
-- Name: counter_table_count_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE counter_table_count_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: counter_table_count_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE counter_table_count_id_seq OWNED BY counter_table.count_id;


--
-- Name: forum_stats; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE forum_stats (
    forum_stat_id integer NOT NULL,
    forum_id integer NOT NULL,
    moment date NOT NULL,
    messages integer NOT NULL,
    threads integer NOT NULL
);


--
-- Name: forum_stats_forum_stat_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE forum_stats_forum_stat_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: forum_stats_forum_stat_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE forum_stats_forum_stat_id_seq OWNED BY forum_stats.forum_stat_id;


--
-- Name: forums; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE forums (
    forum_id bigint NOT NULL,
    slug character varying(255) NOT NULL,
    short_name character varying(255) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    name character varying NOT NULL,
    description character varying,
    standard_permission character varying(50) DEFAULT 'private'::character varying NOT NULL,
    keywords character varying(255),
    "position" integer DEFAULT 0 NOT NULL
);


--
-- Name: forums_forum_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE forums_forum_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: forums_forum_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE forums_forum_id_seq OWNED BY forums.forum_id;


--
-- Name: forums_groups_permissions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE forums_groups_permissions (
    forum_group_permission_id bigint NOT NULL,
    permission character varying(50) NOT NULL,
    group_id bigint NOT NULL,
    forum_id bigint NOT NULL
);


--
-- Name: forums_groups_permissions_forum_group_permission_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE forums_groups_permissions_forum_group_permission_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: forums_groups_permissions_forum_group_permission_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE forums_groups_permissions_forum_group_permission_id_seq OWNED BY forums_groups_permissions.forum_group_permission_id;


--
-- Name: groups; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE groups (
    group_id bigint NOT NULL,
    name character varying(255) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: groups_group_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE groups_group_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: groups_group_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE groups_group_id_seq OWNED BY groups.group_id;


--
-- Name: groups_users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE groups_users (
    group_user_id bigint NOT NULL,
    group_id bigint NOT NULL,
    user_id bigint NOT NULL
);


--
-- Name: groups_users_group_user_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE groups_users_group_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: groups_users_group_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE groups_users_group_user_id_seq OWNED BY groups_users.group_user_id;


--
-- Name: interesting_messages; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE interesting_messages (
    interesting_message_id bigint NOT NULL,
    message_id bigint NOT NULL,
    user_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: interesting_messages_interesting_message_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE interesting_messages_interesting_message_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: interesting_messages_interesting_message_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE interesting_messages_interesting_message_id_seq OWNED BY interesting_messages.interesting_message_id;


--
-- Name: invisible_threads; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE invisible_threads (
    invisible_thread_id bigint NOT NULL,
    user_id integer NOT NULL,
    thread_id bigint NOT NULL
);


--
-- Name: invisible_threads_invisible_thread_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE invisible_threads_invisible_thread_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: invisible_threads_invisible_thread_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE invisible_threads_invisible_thread_id_seq OWNED BY invisible_threads.invisible_thread_id;


--
-- Name: media; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE media (
    medium_id bigint NOT NULL,
    filename character varying NOT NULL,
    orig_name character varying NOT NULL,
    content_type character varying NOT NULL,
    owner_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: media_medium_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE media_medium_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: media_medium_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE media_medium_id_seq OWNED BY media.medium_id;


--
-- Name: message_references; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE message_references (
    message_reference_id bigint NOT NULL,
    src_message_id bigint NOT NULL,
    dst_message_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: message_references_message_reference_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE message_references_message_reference_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: message_references_message_reference_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE message_references_message_reference_id_seq OWNED BY message_references.message_reference_id;


--
-- Name: message_versions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE message_versions (
    message_version_id bigint NOT NULL,
    message_id bigint NOT NULL,
    subject text NOT NULL,
    content text NOT NULL,
    user_id bigint,
    created_at timestamp without time zone NOT NULL,
    author text NOT NULL
);


--
-- Name: message_versions_message_version_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE message_versions_message_version_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: message_versions_message_version_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE message_versions_message_version_id_seq OWNED BY message_versions.message_version_id;


--
-- Name: messages; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE messages (
    message_id bigint NOT NULL,
    thread_id bigint NOT NULL,
    forum_id bigint NOT NULL,
    upvotes integer DEFAULT 0 NOT NULL,
    downvotes integer DEFAULT 0 NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    mid bigint,
    user_id bigint,
    parent_id bigint,
    author character varying NOT NULL,
    email character varying,
    homepage character varying,
    subject character varying NOT NULL,
    content character varying NOT NULL,
    flags hstore,
    uuid character varying(250),
    ip character varying(255),
    editor_id bigint,
    format character varying(100) DEFAULT 'markdown'::character varying NOT NULL,
    edit_author text,
    problematic_site character varying
);


--
-- Name: messages_message_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE messages_message_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: messages_message_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE messages_message_id_seq OWNED BY messages.message_id;


--
-- Name: messages_tags; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE messages_tags (
    message_tag_id bigint NOT NULL,
    message_id bigint NOT NULL,
    tag_id bigint NOT NULL
);


--
-- Name: messages_tags_message_tag_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE messages_tags_message_tag_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: messages_tags_message_tag_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE messages_tags_message_tag_id_seq OWNED BY messages_tags.message_tag_id;


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE notifications (
    notification_id bigint NOT NULL,
    recipient_id bigint NOT NULL,
    is_read boolean DEFAULT false NOT NULL,
    subject character varying(250) NOT NULL,
    path character varying(250) NOT NULL,
    icon character varying(250),
    oid bigint NOT NULL,
    otype character varying(100) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: notifications_notification_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE notifications_notification_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notifications_notification_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE notifications_notification_id_seq OWNED BY notifications.notification_id;


--
-- Name: opened_closed_threads; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE opened_closed_threads (
    opened_closed_thread_id bigint NOT NULL,
    user_id integer NOT NULL,
    thread_id bigint NOT NULL,
    state character varying(10) NOT NULL
);


--
-- Name: opened_closed_threads_opened_closed_thread_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE opened_closed_threads_opened_closed_thread_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: opened_closed_threads_opened_closed_thread_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE opened_closed_threads_opened_closed_thread_id_seq OWNED BY opened_closed_threads.opened_closed_thread_id;


--
-- Name: peon_jobs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE peon_jobs (
    peon_job_id bigint NOT NULL,
    queue_name character varying(255) NOT NULL,
    max_tries integer DEFAULT 0 NOT NULL,
    tries integer DEFAULT 0 NOT NULL,
    work_done boolean DEFAULT false NOT NULL,
    class_name character varying(250) NOT NULL,
    arguments character varying NOT NULL,
    errstr character varying,
    stacktrace character varying
);


--
-- Name: peon_jobs_peon_job_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE peon_jobs_peon_job_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: peon_jobs_peon_job_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE peon_jobs_peon_job_id_seq OWNED BY peon_jobs.peon_job_id;


--
-- Name: priv_messages; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE priv_messages (
    priv_message_id bigint NOT NULL,
    sender_id bigint,
    recipient_id bigint,
    owner_id bigint,
    is_read boolean DEFAULT false NOT NULL,
    subject character varying(250) NOT NULL,
    body text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    sender_name character varying NOT NULL,
    recipient_name character varying NOT NULL
);


--
-- Name: priv_messages_priv_message_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE priv_messages_priv_message_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: priv_messages_priv_message_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE priv_messages_priv_message_id_seq OWNED BY priv_messages.priv_message_id;


--
-- Name: read_messages; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE read_messages (
    read_message_id bigint NOT NULL,
    user_id integer NOT NULL,
    message_id bigint NOT NULL
);


--
-- Name: read_messages_read_message_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE read_messages_read_message_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: read_messages_read_message_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE read_messages_read_message_id_seq OWNED BY read_messages.read_message_id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: scores; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE scores (
    score_id bigint NOT NULL,
    user_id bigint NOT NULL,
    vote_id bigint,
    value integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    message_id bigint
);


--
-- Name: scores_score_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE scores_score_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scores_score_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE scores_score_id_seq OWNED BY scores.score_id;


--
-- Name: search_documents; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE search_documents (
    search_document_id bigint NOT NULL,
    search_section_id integer NOT NULL,
    reference_id bigint,
    forum_id bigint,
    user_id bigint,
    url text NOT NULL,
    relevance double precision NOT NULL,
    author text NOT NULL,
    title text NOT NULL,
    content text NOT NULL,
    ts_title tsvector NOT NULL,
    ts_content tsvector NOT NULL,
    ts_document tsvector NOT NULL,
    document_created timestamp without time zone,
    lang text NOT NULL,
    tags text[] NOT NULL,
    ts_author tsvector NOT NULL
);


--
-- Name: search_documents_search_document_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE search_documents_search_document_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: search_documents_search_document_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE search_documents_search_document_id_seq OWNED BY search_documents.search_document_id;


--
-- Name: search_sections; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE search_sections (
    search_section_id integer NOT NULL,
    name text NOT NULL,
    "position" integer NOT NULL,
    active_by_default boolean DEFAULT false NOT NULL,
    forum_id bigint
);


--
-- Name: search_sections_search_section_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE search_sections_search_section_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: search_sections_search_section_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE search_sections_search_section_id_seq OWNED BY search_sections.search_section_id;


--
-- Name: settings; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE settings (
    setting_id bigint NOT NULL,
    forum_id bigint,
    user_id bigint,
    options hstore
);


--
-- Name: settings_setting_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE settings_setting_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: settings_setting_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE settings_setting_id_seq OWNED BY settings.setting_id;


--
-- Name: tag_synonyms; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tag_synonyms (
    tag_synonym_id bigint NOT NULL,
    tag_id bigint NOT NULL,
    forum_id bigint NOT NULL,
    synonym character varying(250) NOT NULL
);


--
-- Name: tag_synonyms_tag_synonym_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tag_synonyms_tag_synonym_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tag_synonyms_tag_synonym_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tag_synonyms_tag_synonym_id_seq OWNED BY tag_synonyms.tag_synonym_id;


--
-- Name: tags; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tags (
    tag_id bigint NOT NULL,
    tag_name character varying NOT NULL,
    slug character varying NOT NULL,
    forum_id bigint NOT NULL,
    num_messages bigint DEFAULT 0 NOT NULL,
    suggest boolean DEFAULT true NOT NULL
)
WITH (fillfactor=90);


--
-- Name: tags_tag_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tags_tag_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tags_tag_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tags_tag_id_seq OWNED BY tags.tag_id;


--
-- Name: threads; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE threads (
    thread_id bigint NOT NULL,
    slug character varying(255) NOT NULL,
    forum_id bigint NOT NULL,
    archived boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    tid bigint,
    message_id bigint,
    deleted boolean DEFAULT false NOT NULL,
    sticky boolean DEFAULT false NOT NULL,
    flags hstore,
    latest_message timestamp without time zone NOT NULL
);


--
-- Name: threads_thread_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE threads_thread_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: threads_thread_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE threads_thread_id_seq OWNED BY threads.thread_id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    user_id bigint NOT NULL,
    username character varying(255) NOT NULL,
    email character varying(255),
    unconfirmed_email character varying(255),
    admin boolean,
    active boolean DEFAULT true NOT NULL,
    encrypted_password character varying(255) DEFAULT ''::character varying NOT NULL,
    remember_created_at timestamp without time zone,
    reset_password_token character varying(255),
    reset_password_sent_at timestamp without time zone,
    confirmation_token character varying(255),
    confirmed_at timestamp without time zone,
    confirmation_sent_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    authentication_token character varying(255),
    last_sign_in_at timestamp without time zone,
    current_sign_in_at timestamp without time zone,
    last_sign_in_ip character varying,
    current_sign_in_ip character varying,
    sign_in_count integer,
    avatar_file_name character varying(255),
    avatar_content_type character varying(255),
    avatar_file_size integer,
    avatar_updated_at timestamp without time zone,
    websocket_token character varying(250)
);


--
-- Name: users_user_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_user_id_seq OWNED BY users.user_id;


--
-- Name: votes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE votes (
    vote_id bigint NOT NULL,
    user_id bigint NOT NULL,
    message_id bigint NOT NULL,
    vtype character varying(50) NOT NULL
);


--
-- Name: votes_vote_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE votes_vote_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: votes_vote_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE votes_vote_id_seq OWNED BY votes.vote_id;


--
-- Name: auditing_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY auditing ALTER COLUMN auditing_id SET DEFAULT nextval('auditing_auditing_id_seq'::regclass);


--
-- Name: badge_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY badges ALTER COLUMN badge_id SET DEFAULT nextval('badges_badge_id_seq'::regclass);


--
-- Name: badge_user_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY badges_users ALTER COLUMN badge_user_id SET DEFAULT nextval('badges_users_badge_user_id_seq'::regclass);


--
-- Name: cite_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY cites ALTER COLUMN cite_id SET DEFAULT nextval('cites_cite_id_seq'::regclass);


--
-- Name: cite_vote_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY cites_votes ALTER COLUMN cite_vote_id SET DEFAULT nextval('cites_votes_cite_vote_id_seq'::regclass);


--
-- Name: close_vote_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY close_votes ALTER COLUMN close_vote_id SET DEFAULT nextval('close_votes_close_vote_id_seq'::regclass);


--
-- Name: close_votes_voter_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY close_votes_voters ALTER COLUMN close_votes_voter_id SET DEFAULT nextval('close_votes_voters_close_votes_voter_id_seq'::regclass);


--
-- Name: count_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY counter_table ALTER COLUMN count_id SET DEFAULT nextval('counter_table_count_id_seq'::regclass);


--
-- Name: forum_stat_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY forum_stats ALTER COLUMN forum_stat_id SET DEFAULT nextval('forum_stats_forum_stat_id_seq'::regclass);


--
-- Name: forum_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY forums ALTER COLUMN forum_id SET DEFAULT nextval('forums_forum_id_seq'::regclass);


--
-- Name: forum_group_permission_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY forums_groups_permissions ALTER COLUMN forum_group_permission_id SET DEFAULT nextval('forums_groups_permissions_forum_group_permission_id_seq'::regclass);


--
-- Name: group_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY groups ALTER COLUMN group_id SET DEFAULT nextval('groups_group_id_seq'::regclass);


--
-- Name: group_user_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY groups_users ALTER COLUMN group_user_id SET DEFAULT nextval('groups_users_group_user_id_seq'::regclass);


--
-- Name: interesting_message_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY interesting_messages ALTER COLUMN interesting_message_id SET DEFAULT nextval('interesting_messages_interesting_message_id_seq'::regclass);


--
-- Name: invisible_thread_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY invisible_threads ALTER COLUMN invisible_thread_id SET DEFAULT nextval('invisible_threads_invisible_thread_id_seq'::regclass);


--
-- Name: medium_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY media ALTER COLUMN medium_id SET DEFAULT nextval('media_medium_id_seq'::regclass);


--
-- Name: message_reference_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY message_references ALTER COLUMN message_reference_id SET DEFAULT nextval('message_references_message_reference_id_seq'::regclass);


--
-- Name: message_version_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY message_versions ALTER COLUMN message_version_id SET DEFAULT nextval('message_versions_message_version_id_seq'::regclass);


--
-- Name: message_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY messages ALTER COLUMN message_id SET DEFAULT nextval('messages_message_id_seq'::regclass);


--
-- Name: message_tag_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY messages_tags ALTER COLUMN message_tag_id SET DEFAULT nextval('messages_tags_message_tag_id_seq'::regclass);


--
-- Name: notification_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY notifications ALTER COLUMN notification_id SET DEFAULT nextval('notifications_notification_id_seq'::regclass);


--
-- Name: opened_closed_thread_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY opened_closed_threads ALTER COLUMN opened_closed_thread_id SET DEFAULT nextval('opened_closed_threads_opened_closed_thread_id_seq'::regclass);


--
-- Name: peon_job_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY peon_jobs ALTER COLUMN peon_job_id SET DEFAULT nextval('peon_jobs_peon_job_id_seq'::regclass);


--
-- Name: priv_message_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY priv_messages ALTER COLUMN priv_message_id SET DEFAULT nextval('priv_messages_priv_message_id_seq'::regclass);


--
-- Name: read_message_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY read_messages ALTER COLUMN read_message_id SET DEFAULT nextval('read_messages_read_message_id_seq'::regclass);


--
-- Name: score_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY scores ALTER COLUMN score_id SET DEFAULT nextval('scores_score_id_seq'::regclass);


--
-- Name: search_document_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY search_documents ALTER COLUMN search_document_id SET DEFAULT nextval('search_documents_search_document_id_seq'::regclass);


--
-- Name: search_section_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY search_sections ALTER COLUMN search_section_id SET DEFAULT nextval('search_sections_search_section_id_seq'::regclass);


--
-- Name: setting_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY settings ALTER COLUMN setting_id SET DEFAULT nextval('settings_setting_id_seq'::regclass);


--
-- Name: tag_synonym_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tag_synonyms ALTER COLUMN tag_synonym_id SET DEFAULT nextval('tag_synonyms_tag_synonym_id_seq'::regclass);


--
-- Name: tag_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tags ALTER COLUMN tag_id SET DEFAULT nextval('tags_tag_id_seq'::regclass);


--
-- Name: thread_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY threads ALTER COLUMN thread_id SET DEFAULT nextval('threads_thread_id_seq'::regclass);


--
-- Name: user_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN user_id SET DEFAULT nextval('users_user_id_seq'::regclass);


--
-- Name: vote_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY votes ALTER COLUMN vote_id SET DEFAULT nextval('votes_vote_id_seq'::regclass);


--
-- Name: auditing_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY auditing
    ADD CONSTRAINT auditing_pkey PRIMARY KEY (auditing_id);


--
-- Name: badges_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY badges
    ADD CONSTRAINT badges_pkey PRIMARY KEY (badge_id);


--
-- Name: badges_slug_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY badges
    ADD CONSTRAINT badges_slug_key UNIQUE (slug);


--
-- Name: badges_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY badges_users
    ADD CONSTRAINT badges_users_pkey PRIMARY KEY (badge_user_id);


--
-- Name: badges_users_user_id_badge_id_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY badges_users
    ADD CONSTRAINT badges_users_user_id_badge_id_key UNIQUE (user_id, badge_id);


--
-- Name: cites_old_id_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cites
    ADD CONSTRAINT cites_old_id_key UNIQUE (old_id);


--
-- Name: cites_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cites
    ADD CONSTRAINT cites_pkey PRIMARY KEY (cite_id);


--
-- Name: cites_votes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cites_votes
    ADD CONSTRAINT cites_votes_pkey PRIMARY KEY (cite_vote_id);


--
-- Name: close_votes_message_id_vote_type_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY close_votes
    ADD CONSTRAINT close_votes_message_id_vote_type_key UNIQUE (message_id, vote_type);


--
-- Name: close_votes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY close_votes
    ADD CONSTRAINT close_votes_pkey PRIMARY KEY (close_vote_id);


--
-- Name: close_votes_voters_close_vote_id_user_id_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY close_votes_voters
    ADD CONSTRAINT close_votes_voters_close_vote_id_user_id_key UNIQUE (close_vote_id, user_id);


--
-- Name: close_votes_voters_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY close_votes_voters
    ADD CONSTRAINT close_votes_voters_pkey PRIMARY KEY (close_votes_voter_id);


--
-- Name: counter_table_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY counter_table
    ADD CONSTRAINT counter_table_pkey PRIMARY KEY (count_id);


--
-- Name: forum_stats_forum_id_moment_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY forum_stats
    ADD CONSTRAINT forum_stats_forum_id_moment_key UNIQUE (forum_id, moment);


--
-- Name: forum_stats_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY forum_stats
    ADD CONSTRAINT forum_stats_pkey PRIMARY KEY (forum_stat_id);


--
-- Name: forums_groups_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY forums_groups_permissions
    ADD CONSTRAINT forums_groups_permissions_pkey PRIMARY KEY (forum_group_permission_id);


--
-- Name: forums_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY forums
    ADD CONSTRAINT forums_pkey PRIMARY KEY (forum_id);


--
-- Name: groups_name_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY groups
    ADD CONSTRAINT groups_name_key UNIQUE (name);


--
-- Name: groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY groups
    ADD CONSTRAINT groups_pkey PRIMARY KEY (group_id);


--
-- Name: groups_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY groups_users
    ADD CONSTRAINT groups_users_pkey PRIMARY KEY (group_user_id);


--
-- Name: interesting_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY interesting_messages
    ADD CONSTRAINT interesting_messages_pkey PRIMARY KEY (interesting_message_id);


--
-- Name: invisible_threads_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY invisible_threads
    ADD CONSTRAINT invisible_threads_pkey PRIMARY KEY (invisible_thread_id);


--
-- Name: media_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY media
    ADD CONSTRAINT media_pkey PRIMARY KEY (medium_id);


--
-- Name: message_references_dst_message_id_src_message_id_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY message_references
    ADD CONSTRAINT message_references_dst_message_id_src_message_id_key UNIQUE (dst_message_id, src_message_id);


--
-- Name: message_references_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY message_references
    ADD CONSTRAINT message_references_pkey PRIMARY KEY (message_reference_id);


--
-- Name: message_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY message_versions
    ADD CONSTRAINT message_versions_pkey PRIMARY KEY (message_version_id);


--
-- Name: messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (message_id);


--
-- Name: messages_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY messages_tags
    ADD CONSTRAINT messages_tags_pkey PRIMARY KEY (message_tag_id);


--
-- Name: notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (notification_id);


--
-- Name: opened_closed_threads_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY opened_closed_threads
    ADD CONSTRAINT opened_closed_threads_pkey PRIMARY KEY (opened_closed_thread_id);


--
-- Name: peon_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY peon_jobs
    ADD CONSTRAINT peon_jobs_pkey PRIMARY KEY (peon_job_id);


--
-- Name: priv_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY priv_messages
    ADD CONSTRAINT priv_messages_pkey PRIMARY KEY (priv_message_id);


--
-- Name: read_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY read_messages
    ADD CONSTRAINT read_messages_pkey PRIMARY KEY (read_message_id);


--
-- Name: scores_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY scores
    ADD CONSTRAINT scores_pkey PRIMARY KEY (score_id);


--
-- Name: search_documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY search_documents
    ADD CONSTRAINT search_documents_pkey PRIMARY KEY (search_document_id);


--
-- Name: search_documents_reference_id_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY search_documents
    ADD CONSTRAINT search_documents_reference_id_key UNIQUE (reference_id);


--
-- Name: search_documents_url_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY search_documents
    ADD CONSTRAINT search_documents_url_key UNIQUE (url);


--
-- Name: search_sections_name_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY search_sections
    ADD CONSTRAINT search_sections_name_key UNIQUE (name);


--
-- Name: search_sections_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY search_sections
    ADD CONSTRAINT search_sections_pkey PRIMARY KEY (search_section_id);


--
-- Name: settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY settings
    ADD CONSTRAINT settings_pkey PRIMARY KEY (setting_id);


--
-- Name: tag_synonyms_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tag_synonyms
    ADD CONSTRAINT tag_synonyms_pkey PRIMARY KEY (tag_synonym_id);


--
-- Name: tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (tag_id);


--
-- Name: threads_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY threads
    ADD CONSTRAINT threads_pkey PRIMARY KEY (thread_id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- Name: users_websocket_token_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_websocket_token_key UNIQUE (websocket_token);


--
-- Name: votes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY votes
    ADD CONSTRAINT votes_pkey PRIMARY KEY (vote_id);


--
-- Name: counter_table_table_name_group_crit_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX counter_table_table_name_group_crit_idx ON counter_table USING btree (table_name, group_crit);


--
-- Name: forums_slug_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX forums_slug_idx ON forums USING btree (slug);


--
-- Name: invisible_threads_thread_id_user_id_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX invisible_threads_thread_id_user_id_idx ON invisible_threads USING btree (thread_id, user_id);


--
-- Name: messages_editor_id_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX messages_editor_id_idx ON messages USING btree (editor_id);


--
-- Name: messages_forum_id_created_at_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX messages_forum_id_created_at_idx ON messages USING btree (forum_id, created_at);


--
-- Name: messages_mid_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX messages_mid_idx ON messages USING btree (mid);


--
-- Name: messages_parent_id_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX messages_parent_id_idx ON messages USING btree (parent_id);


--
-- Name: messages_tags_message_id_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX messages_tags_message_id_idx ON messages_tags USING btree (message_id);


--
-- Name: messages_tags_tag_id_message_id_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX messages_tags_tag_id_message_id_idx ON messages_tags USING btree (tag_id, message_id);


--
-- Name: messages_thread_id_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX messages_thread_id_idx ON messages USING btree (thread_id);


--
-- Name: messages_updated_at_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX messages_updated_at_idx ON messages USING btree (updated_at);


--
-- Name: messages_user_id_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX messages_user_id_idx ON messages USING btree (user_id);


--
-- Name: notifications_recipient_id_oid_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX notifications_recipient_id_oid_idx ON notifications USING btree (recipient_id, oid);


--
-- Name: opened_closed_threads_thread_id_user_id_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX opened_closed_threads_thread_id_user_id_idx ON opened_closed_threads USING btree (thread_id, user_id);


--
-- Name: peon_jobs_work_done_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX peon_jobs_work_done_idx ON peon_jobs USING btree (work_done);


--
-- Name: priv_messages_owner_id_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX priv_messages_owner_id_idx ON priv_messages USING btree (owner_id);


--
-- Name: priv_messages_recipient_id_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX priv_messages_recipient_id_idx ON priv_messages USING btree (recipient_id);


--
-- Name: priv_messages_sender_id_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX priv_messages_sender_id_idx ON priv_messages USING btree (sender_id);


--
-- Name: read_messages_message_id_user_id_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX read_messages_message_id_user_id_idx ON read_messages USING btree (message_id, user_id);


--
-- Name: read_messages_user_id_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX read_messages_user_id_idx ON read_messages USING btree (user_id);


--
-- Name: scores_user_id_message_id_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX scores_user_id_message_id_idx ON scores USING btree (user_id, message_id) WHERE (message_id IS NOT NULL);


--
-- Name: scores_user_id_vote_id_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX scores_user_id_vote_id_idx ON scores USING btree (user_id, vote_id) WHERE (vote_id IS NOT NULL);


--
-- Name: search_documents_author_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX search_documents_author_idx ON search_documents USING gin (ts_author);


--
-- Name: search_documents_content_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX search_documents_content_idx ON search_documents USING gin (ts_content);


--
-- Name: search_documents_document_created_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX search_documents_document_created_idx ON search_documents USING btree (document_created);


--
-- Name: search_documents_document_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX search_documents_document_idx ON search_documents USING gin (ts_document);


--
-- Name: search_documents_tags_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX search_documents_tags_idx ON search_documents USING gin (tags);


--
-- Name: search_documents_title_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX search_documents_title_idx ON search_documents USING gin (ts_title);


--
-- Name: search_documents_user_id_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX search_documents_user_id_idx ON search_documents USING btree (user_id);


--
-- Name: settings_forum_id_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX settings_forum_id_idx ON settings USING btree (forum_id);


--
-- Name: settings_forum_id_user_id_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX settings_forum_id_user_id_idx ON settings USING btree (forum_id, user_id);


--
-- Name: settings_user_id_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX settings_user_id_idx ON settings USING btree (user_id);


--
-- Name: tag_synonyms_forum_id_synonym_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX tag_synonyms_forum_id_synonym_idx ON tag_synonyms USING btree (forum_id, synonym);


--
-- Name: tag_synonyms_synonym_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX tag_synonyms_synonym_idx ON tag_synonyms USING btree (synonym);


--
-- Name: tag_synonyms_tag_id_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX tag_synonyms_tag_id_idx ON tag_synonyms USING btree (tag_id);


--
-- Name: tags_forum_id_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX tags_forum_id_idx ON tags USING btree (forum_id);


--
-- Name: tags_tag_name_forum_id_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX tags_tag_name_forum_id_idx ON tags USING btree (tag_name, forum_id);


--
-- Name: threads_archived_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX threads_archived_idx ON threads USING btree (archived);


--
-- Name: threads_created_at_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX threads_created_at_idx ON threads USING btree (created_at);


--
-- Name: threads_forum_id_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX threads_forum_id_idx ON threads USING btree (forum_id);


--
-- Name: threads_message_id_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX threads_message_id_idx ON threads USING btree (message_id);


--
-- Name: threads_slug_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX threads_slug_idx ON threads USING btree (slug);


--
-- Name: threads_sticky_created_at_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX threads_sticky_created_at_idx ON threads USING btree (sticky, created_at);


--
-- Name: threads_tid_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX threads_tid_idx ON threads USING btree (tid);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: users_authentication_token_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX users_authentication_token_idx ON users USING btree (authentication_token);


--
-- Name: users_confirmation_token_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX users_confirmation_token_idx ON users USING btree (confirmation_token);


--
-- Name: users_email_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX users_email_idx ON users USING btree (lower((email)::text));


--
-- Name: users_reset_password_token_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX users_reset_password_token_idx ON users USING btree (reset_password_token);


--
-- Name: users_username_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX users_username_idx ON users USING btree (lower((username)::text));


--
-- Name: votes_user_id_message_id_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX votes_user_id_message_id_idx ON votes USING btree (user_id, message_id);


--
-- Name: messages__count_delete_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER messages__count_delete_trigger AFTER DELETE ON messages FOR EACH ROW EXECUTE PROCEDURE count_messages_delete_trigger();


--
-- Name: messages__count_insert_forum_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER messages__count_insert_forum_trigger AFTER INSERT ON forums FOR EACH ROW EXECUTE PROCEDURE count_messages_insert_forum_trigger();


--
-- Name: messages__count_insert_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER messages__count_insert_trigger AFTER INSERT ON messages FOR EACH ROW EXECUTE PROCEDURE count_messages_insert_trigger();


--
-- Name: messages__count_truncate_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER messages__count_truncate_trigger AFTER TRUNCATE ON messages FOR EACH STATEMENT EXECUTE PROCEDURE count_messages_truncate_trigger();


--
-- Name: messages__count_update_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER messages__count_update_trigger AFTER UPDATE ON messages FOR EACH ROW EXECUTE PROCEDURE count_messages_update_trigger();


--
-- Name: messages__thread_set_latest_trigger_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER messages__thread_set_latest_trigger_insert AFTER INSERT ON messages FOR EACH ROW EXECUTE PROCEDURE messages__thread_set_latest_insert();


--
-- Name: messages__thread_set_latest_trigger_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER messages__thread_set_latest_trigger_update AFTER DELETE OR UPDATE ON messages FOR EACH ROW EXECUTE PROCEDURE messages__thread_set_latest_update_delete();


--
-- Name: messages_tags__count_delete_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER messages_tags__count_delete_trigger AFTER DELETE ON messages_tags FOR EACH ROW EXECUTE PROCEDURE count_messages_tag_delete_trigger();


--
-- Name: messages_tags__count_insert_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER messages_tags__count_insert_trigger AFTER INSERT ON messages_tags FOR EACH ROW EXECUTE PROCEDURE count_messages_tag_insert_trigger();


--
-- Name: search_documents__before_insert_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER search_documents__before_insert_trigger BEFORE INSERT ON search_documents FOR EACH ROW EXECUTE PROCEDURE search_document_before_insert();


--
-- Name: search_documents__before_update_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER search_documents__before_update_trigger BEFORE UPDATE ON search_documents FOR EACH ROW EXECUTE PROCEDURE search_document_before_insert();


--
-- Name: settings_unique_check_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER settings_unique_check_insert BEFORE INSERT ON settings FOR EACH ROW EXECUTE PROCEDURE settings_unique_check__insert();


--
-- Name: settings_unique_check_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER settings_unique_check_update BEFORE UPDATE ON settings FOR EACH ROW EXECUTE PROCEDURE settings_unique_check__update();


--
-- Name: threads__count_delete_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER threads__count_delete_trigger AFTER DELETE ON threads FOR EACH ROW EXECUTE PROCEDURE count_threads_delete_trigger();


--
-- Name: threads__count_insert_forum_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER threads__count_insert_forum_trigger AFTER INSERT ON forums FOR EACH ROW EXECUTE PROCEDURE count_threads_insert_forum_trigger();


--
-- Name: threads__count_insert_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER threads__count_insert_trigger AFTER INSERT ON threads FOR EACH ROW EXECUTE PROCEDURE count_threads_insert_trigger();


--
-- Name: threads__count_truncate_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER threads__count_truncate_trigger AFTER TRUNCATE ON threads FOR EACH STATEMENT EXECUTE PROCEDURE count_threads_truncate_trigger();


--
-- Name: threads__count_update_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER threads__count_update_trigger AFTER UPDATE ON threads FOR EACH ROW EXECUTE PROCEDURE count_threads_update_trigger();


--
-- Name: auditing_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY auditing
    ADD CONSTRAINT auditing_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: badges_users_badge_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY badges_users
    ADD CONSTRAINT badges_users_badge_id_fkey FOREIGN KEY (badge_id) REFERENCES badges(badge_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: badges_users_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY badges_users
    ADD CONSTRAINT badges_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: cites_creator_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cites
    ADD CONSTRAINT cites_creator_user_id_fkey FOREIGN KEY (creator_user_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: cites_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cites
    ADD CONSTRAINT cites_message_id_fkey FOREIGN KEY (message_id) REFERENCES messages(message_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: cites_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cites
    ADD CONSTRAINT cites_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: cites_votes_cite_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cites_votes
    ADD CONSTRAINT cites_votes_cite_id_fkey FOREIGN KEY (cite_id) REFERENCES cites(cite_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: cites_votes_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cites_votes
    ADD CONSTRAINT cites_votes_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: close_votes_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY close_votes
    ADD CONSTRAINT close_votes_message_id_fkey FOREIGN KEY (message_id) REFERENCES messages(message_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: close_votes_voters_close_vote_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY close_votes_voters
    ADD CONSTRAINT close_votes_voters_close_vote_id_fkey FOREIGN KEY (close_vote_id) REFERENCES close_votes(close_vote_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: forum_stats_forum_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY forum_stats
    ADD CONSTRAINT forum_stats_forum_id_fkey FOREIGN KEY (forum_id) REFERENCES forums(forum_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: forums_groups_permissions_forum_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY forums_groups_permissions
    ADD CONSTRAINT forums_groups_permissions_forum_id_fkey FOREIGN KEY (forum_id) REFERENCES forums(forum_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: forums_groups_permissions_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY forums_groups_permissions
    ADD CONSTRAINT forums_groups_permissions_group_id_fkey FOREIGN KEY (group_id) REFERENCES groups(group_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: groups_users_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY groups_users
    ADD CONSTRAINT groups_users_group_id_fkey FOREIGN KEY (group_id) REFERENCES groups(group_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: groups_users_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY groups_users
    ADD CONSTRAINT groups_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: interesting_messages_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY interesting_messages
    ADD CONSTRAINT interesting_messages_message_id_fkey FOREIGN KEY (message_id) REFERENCES messages(message_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: interesting_messages_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY interesting_messages
    ADD CONSTRAINT interesting_messages_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: invisible_threads_thread_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY invisible_threads
    ADD CONSTRAINT invisible_threads_thread_id_fkey FOREIGN KEY (thread_id) REFERENCES threads(thread_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: invisible_threads_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY invisible_threads
    ADD CONSTRAINT invisible_threads_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: media_owner_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY media
    ADD CONSTRAINT media_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: message_references_dst_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY message_references
    ADD CONSTRAINT message_references_dst_message_id_fkey FOREIGN KEY (dst_message_id) REFERENCES messages(message_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: message_references_src_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY message_references
    ADD CONSTRAINT message_references_src_message_id_fkey FOREIGN KEY (src_message_id) REFERENCES messages(message_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: message_versions_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY message_versions
    ADD CONSTRAINT message_versions_message_id_fkey FOREIGN KEY (message_id) REFERENCES messages(message_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: message_versions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY message_versions
    ADD CONSTRAINT message_versions_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: messages_editor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY messages
    ADD CONSTRAINT messages_editor_id_fkey FOREIGN KEY (editor_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: messages_forum_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY messages
    ADD CONSTRAINT messages_forum_id_fkey FOREIGN KEY (forum_id) REFERENCES forums(forum_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: messages_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY messages
    ADD CONSTRAINT messages_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES messages(message_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: messages_tags_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY messages_tags
    ADD CONSTRAINT messages_tags_message_id_fkey FOREIGN KEY (message_id) REFERENCES messages(message_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: messages_tags_tag_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY messages_tags
    ADD CONSTRAINT messages_tags_tag_id_fkey FOREIGN KEY (tag_id) REFERENCES tags(tag_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: messages_thread_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY messages
    ADD CONSTRAINT messages_thread_id_fkey FOREIGN KEY (thread_id) REFERENCES threads(thread_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: messages_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY messages
    ADD CONSTRAINT messages_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: notifications_recipient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY notifications
    ADD CONSTRAINT notifications_recipient_id_fkey FOREIGN KEY (recipient_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: opened_closed_threads_thread_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY opened_closed_threads
    ADD CONSTRAINT opened_closed_threads_thread_id_fkey FOREIGN KEY (thread_id) REFERENCES threads(thread_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: opened_closed_threads_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY opened_closed_threads
    ADD CONSTRAINT opened_closed_threads_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: priv_messages_owner_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY priv_messages
    ADD CONSTRAINT priv_messages_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: priv_messages_recipient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY priv_messages
    ADD CONSTRAINT priv_messages_recipient_id_fkey FOREIGN KEY (recipient_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: priv_messages_sender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY priv_messages
    ADD CONSTRAINT priv_messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: read_messages_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY read_messages
    ADD CONSTRAINT read_messages_message_id_fkey FOREIGN KEY (message_id) REFERENCES messages(message_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: read_messages_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY read_messages
    ADD CONSTRAINT read_messages_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: scores_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY scores
    ADD CONSTRAINT scores_message_id_fkey FOREIGN KEY (message_id) REFERENCES messages(message_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: scores_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY scores
    ADD CONSTRAINT scores_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: scores_vote_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY scores
    ADD CONSTRAINT scores_vote_id_fkey FOREIGN KEY (vote_id) REFERENCES votes(vote_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: search_documents_forum_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY search_documents
    ADD CONSTRAINT search_documents_forum_id_fkey FOREIGN KEY (forum_id) REFERENCES forums(forum_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: search_documents_search_section_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY search_documents
    ADD CONSTRAINT search_documents_search_section_id_fkey FOREIGN KEY (search_section_id) REFERENCES search_sections(search_section_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: search_documents_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY search_documents
    ADD CONSTRAINT search_documents_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: search_sections_forum_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY search_sections
    ADD CONSTRAINT search_sections_forum_id_fkey FOREIGN KEY (forum_id) REFERENCES forums(forum_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: settings_forum_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY settings
    ADD CONSTRAINT settings_forum_id_fkey FOREIGN KEY (forum_id) REFERENCES forums(forum_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: settings_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY settings
    ADD CONSTRAINT settings_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tag_synonyms_forum_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tag_synonyms
    ADD CONSTRAINT tag_synonyms_forum_id_fkey FOREIGN KEY (forum_id) REFERENCES forums(forum_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tag_synonyms_tag_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tag_synonyms
    ADD CONSTRAINT tag_synonyms_tag_id_fkey FOREIGN KEY (tag_id) REFERENCES tags(tag_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tags_forum_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tags
    ADD CONSTRAINT tags_forum_id_fkey FOREIGN KEY (forum_id) REFERENCES forums(forum_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: threads_forum_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY threads
    ADD CONSTRAINT threads_forum_id_fkey FOREIGN KEY (forum_id) REFERENCES forums(forum_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: threads_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY threads
    ADD CONSTRAINT threads_message_id_fkey FOREIGN KEY (message_id) REFERENCES messages(message_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: votes_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY votes
    ADD CONSTRAINT votes_message_id_fkey FOREIGN KEY (message_id) REFERENCES messages(message_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: votes_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY votes
    ADD CONSTRAINT votes_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user",public;

INSERT INTO schema_migrations (version) VALUES ('1');

INSERT INTO schema_migrations (version) VALUES ('10');

INSERT INTO schema_migrations (version) VALUES ('11');

INSERT INTO schema_migrations (version) VALUES ('12');

INSERT INTO schema_migrations (version) VALUES ('13');

INSERT INTO schema_migrations (version) VALUES ('14');

INSERT INTO schema_migrations (version) VALUES ('15');

INSERT INTO schema_migrations (version) VALUES ('16');

INSERT INTO schema_migrations (version) VALUES ('17');

INSERT INTO schema_migrations (version) VALUES ('18');

INSERT INTO schema_migrations (version) VALUES ('19');

INSERT INTO schema_migrations (version) VALUES ('2');

INSERT INTO schema_migrations (version) VALUES ('20');

INSERT INTO schema_migrations (version) VALUES ('21');

INSERT INTO schema_migrations (version) VALUES ('22');

INSERT INTO schema_migrations (version) VALUES ('23');

INSERT INTO schema_migrations (version) VALUES ('24');

INSERT INTO schema_migrations (version) VALUES ('25');

INSERT INTO schema_migrations (version) VALUES ('26');

INSERT INTO schema_migrations (version) VALUES ('27');

INSERT INTO schema_migrations (version) VALUES ('28');

INSERT INTO schema_migrations (version) VALUES ('29');

INSERT INTO schema_migrations (version) VALUES ('3');

INSERT INTO schema_migrations (version) VALUES ('30');

INSERT INTO schema_migrations (version) VALUES ('31');

INSERT INTO schema_migrations (version) VALUES ('32');

INSERT INTO schema_migrations (version) VALUES ('33');

INSERT INTO schema_migrations (version) VALUES ('34');

INSERT INTO schema_migrations (version) VALUES ('35');

INSERT INTO schema_migrations (version) VALUES ('36');

INSERT INTO schema_migrations (version) VALUES ('37');

INSERT INTO schema_migrations (version) VALUES ('38');

INSERT INTO schema_migrations (version) VALUES ('39');

INSERT INTO schema_migrations (version) VALUES ('4');

INSERT INTO schema_migrations (version) VALUES ('40');

INSERT INTO schema_migrations (version) VALUES ('41');

INSERT INTO schema_migrations (version) VALUES ('42');

INSERT INTO schema_migrations (version) VALUES ('43');

INSERT INTO schema_migrations (version) VALUES ('44');

INSERT INTO schema_migrations (version) VALUES ('45');

INSERT INTO schema_migrations (version) VALUES ('46');

INSERT INTO schema_migrations (version) VALUES ('47');

INSERT INTO schema_migrations (version) VALUES ('48');

INSERT INTO schema_migrations (version) VALUES ('49');

INSERT INTO schema_migrations (version) VALUES ('5');

INSERT INTO schema_migrations (version) VALUES ('50');

INSERT INTO schema_migrations (version) VALUES ('51');

INSERT INTO schema_migrations (version) VALUES ('52');

INSERT INTO schema_migrations (version) VALUES ('53');

INSERT INTO schema_migrations (version) VALUES ('54');

INSERT INTO schema_migrations (version) VALUES ('55');

INSERT INTO schema_migrations (version) VALUES ('56');

INSERT INTO schema_migrations (version) VALUES ('57');

INSERT INTO schema_migrations (version) VALUES ('58');

INSERT INTO schema_migrations (version) VALUES ('59');

INSERT INTO schema_migrations (version) VALUES ('6');

INSERT INTO schema_migrations (version) VALUES ('60');

INSERT INTO schema_migrations (version) VALUES ('61');

INSERT INTO schema_migrations (version) VALUES ('62');

INSERT INTO schema_migrations (version) VALUES ('63');

INSERT INTO schema_migrations (version) VALUES ('64');

INSERT INTO schema_migrations (version) VALUES ('65');

INSERT INTO schema_migrations (version) VALUES ('66');

INSERT INTO schema_migrations (version) VALUES ('67');

INSERT INTO schema_migrations (version) VALUES ('68');

INSERT INTO schema_migrations (version) VALUES ('69');

INSERT INTO schema_migrations (version) VALUES ('7');

INSERT INTO schema_migrations (version) VALUES ('70');

INSERT INTO schema_migrations (version) VALUES ('71');

INSERT INTO schema_migrations (version) VALUES ('72');

INSERT INTO schema_migrations (version) VALUES ('73');

INSERT INTO schema_migrations (version) VALUES ('74');

INSERT INTO schema_migrations (version) VALUES ('75');

INSERT INTO schema_migrations (version) VALUES ('76');

INSERT INTO schema_migrations (version) VALUES ('77');

INSERT INTO schema_migrations (version) VALUES ('78');

INSERT INTO schema_migrations (version) VALUES ('79');

INSERT INTO schema_migrations (version) VALUES ('8');

INSERT INTO schema_migrations (version) VALUES ('80');

INSERT INTO schema_migrations (version) VALUES ('81');

INSERT INTO schema_migrations (version) VALUES ('82');

INSERT INTO schema_migrations (version) VALUES ('83');

INSERT INTO schema_migrations (version) VALUES ('84');

INSERT INTO schema_migrations (version) VALUES ('85');

INSERT INTO schema_migrations (version) VALUES ('86');

INSERT INTO schema_migrations (version) VALUES ('9');

