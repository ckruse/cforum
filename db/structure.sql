SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: badge_medal_type_t; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.badge_medal_type_t AS ENUM (
    'bronze',
    'silver',
    'gold'
);


--
-- Name: cache_user_activity_delete_trigger(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cache_user_activity_delete_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF OLD.user_id IS NULL THEN
    RETURN OLD;
  END IF;

  UPDATE users
    SET activity = COALESCE((SELECT COUNT(*)
                             FROM messages
                             WHERE messages.user_id = OLD.user_id AND created_at >= NOW() - INTERVAL '30 days' AND deleted = false), 0)
    WHERE user_id = OLD.user_id;

  RETURN OLD;
END;
$$;


--
-- Name: cache_user_activity_insert_update_trigger(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cache_user_activity_insert_update_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NEW.user_id IS NULL THEN
    RETURN NEW;
  END IF;

  UPDATE users
    SET activity = COALESCE((SELECT COUNT(*)
                             FROM messages
                             WHERE messages.user_id = NEW.user_id AND created_at >= NOW() - INTERVAL '30 days' AND deleted = false), 0)
    WHERE user_id = NEW.user_id;

  RETURN NEW;
END;
$$;


--
-- Name: cache_user_score_delete_trigger(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cache_user_score_delete_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE users
    SET score = COALESCE((SELECT SUM(value) FROM scores WHERE scores.user_id = OLD.user_id), 0)
    WHERE user_id = OLD.user_id;

  RETURN NEW;
END;
$$;


--
-- Name: cache_user_score_insert_trigger(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cache_user_score_insert_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE users
    SET score = COALESCE((SELECT SUM(value) FROM scores WHERE scores.user_id = NEW.user_id), 0)
    WHERE user_id = NEW.user_id;

  RETURN NEW;
END;
$$;


--
-- Name: cache_user_score_update_trigger(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cache_user_score_update_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE users
    SET score = COALESCE((SELECT SUM(value) FROM scores WHERE scores.user_id = NEW.user_id), 0)
    WHERE user_id = NEW.user_id;

  IF NEW.user_id != OLD.user_id THEN
    UPDATE users
      SET score = COALESCE((SELECT SUM(value) FROM scores WHERE scores.user_id = OLD.user_id), 0)
      WHERE user_id = OLD.user_id;
  END IF;

  RETURN NEW;
END;
$$;


--
-- Name: count_messages_delete_trigger(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.count_messages_delete_trigger() RETURNS trigger
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

CREATE FUNCTION public.count_messages_insert_forum_trigger() RETURNS trigger
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

CREATE FUNCTION public.count_messages_insert_trigger() RETURNS trigger
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

CREATE FUNCTION public.count_messages_tag_delete_trigger() RETURNS trigger
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

CREATE FUNCTION public.count_messages_tag_insert_trigger() RETURNS trigger
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

CREATE FUNCTION public.count_messages_truncate_trigger() RETURNS trigger
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

CREATE FUNCTION public.count_messages_update_trigger() RETURNS trigger
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

CREATE FUNCTION public.count_threads_delete_trigger() RETURNS trigger
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

CREATE FUNCTION public.count_threads_insert_forum_trigger() RETURNS trigger
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

CREATE FUNCTION public.count_threads_insert_trigger() RETURNS trigger
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

CREATE FUNCTION public.count_threads_truncate_trigger() RETURNS trigger
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

CREATE FUNCTION public.count_threads_update_trigger() RETURNS trigger
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

CREATE FUNCTION public.counter_table_get_count(v_table_name name, v_group_crit bigint) RETURNS bigint
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

CREATE FUNCTION public.gen_forum_stats(p_forum_id integer) RETURNS integer
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

CREATE FUNCTION public.messages__thread_set_latest_insert() RETURNS trigger
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

CREATE FUNCTION public.messages__thread_set_latest_update_delete() RETURNS trigger
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

CREATE FUNCTION public.search_document_before_insert() RETURNS trigger
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

CREATE FUNCTION public.settings_unique_check__insert() RETURNS trigger
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

CREATE FUNCTION public.settings_unique_check__update() RETURNS trigger
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


--
-- Name: timestamp2local(timestamp without time zone, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.timestamp2local(ts_p timestamp without time zone, tz_p character varying) RETURNS timestamp with time zone
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN (SELECT (ts_p AT TIME ZONE 'UTC') AT TIME ZONE tz_p);
END;
$$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: attendees; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.attendees (
    attendee_id integer NOT NULL,
    event_id integer NOT NULL,
    user_id bigint,
    name text NOT NULL,
    comment text,
    starts_at text,
    planned_start timestamp without time zone,
    planned_arrival timestamp without time zone NOT NULL,
    seats integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    planned_leave timestamp without time zone
);


--
-- Name: attendees_attendee_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.attendees_attendee_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: attendees_attendee_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.attendees_attendee_id_seq OWNED BY public.attendees.attendee_id;


--
-- Name: auditing; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auditing (
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

CREATE SEQUENCE public.auditing_auditing_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: auditing_auditing_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.auditing_auditing_id_seq OWNED BY public.auditing.auditing_id;


--
-- Name: badge_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.badge_groups (
    badge_group_id integer NOT NULL,
    name text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: badge_groups_badge_group_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.badge_groups_badge_group_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: badge_groups_badge_group_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.badge_groups_badge_group_id_seq OWNED BY public.badge_groups.badge_group_id;


--
-- Name: badges; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.badges (
    badge_id integer NOT NULL,
    score_needed integer,
    name character varying NOT NULL,
    description text,
    slug character varying NOT NULL,
    badge_medal_type public.badge_medal_type_t DEFAULT 'bronze'::public.badge_medal_type_t NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    badge_type character varying(250) NOT NULL,
    "order" integer DEFAULT 0 NOT NULL
);


--
-- Name: badges_badge_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.badges_badge_groups (
    badges_badge_group_id integer NOT NULL,
    badge_group_id integer NOT NULL,
    badge_id integer NOT NULL
);


--
-- Name: badges_badge_groups_badges_badge_group_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.badges_badge_groups_badges_badge_group_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: badges_badge_groups_badges_badge_group_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.badges_badge_groups_badges_badge_group_id_seq OWNED BY public.badges_badge_groups.badges_badge_group_id;


--
-- Name: badges_badge_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.badges_badge_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: badges_badge_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.badges_badge_id_seq OWNED BY public.badges.badge_id;


--
-- Name: badges_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.badges_users (
    badge_user_id bigint NOT NULL,
    user_id integer NOT NULL,
    badge_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: badges_users_badge_user_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.badges_users_badge_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: badges_users_badge_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.badges_users_badge_user_id_seq OWNED BY public.badges_users.badge_user_id;


--
-- Name: cites; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cites (
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

CREATE SEQUENCE public.cites_cite_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cites_cite_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cites_cite_id_seq OWNED BY public.cites.cite_id;


--
-- Name: cites_votes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cites_votes (
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

CREATE SEQUENCE public.cites_votes_cite_vote_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cites_votes_cite_vote_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cites_votes_cite_vote_id_seq OWNED BY public.cites_votes.cite_vote_id;


--
-- Name: close_votes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.close_votes (
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

CREATE SEQUENCE public.close_votes_close_vote_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: close_votes_close_vote_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.close_votes_close_vote_id_seq OWNED BY public.close_votes.close_vote_id;


--
-- Name: close_votes_voters; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.close_votes_voters (
    close_votes_voter_id bigint NOT NULL,
    close_vote_id bigint NOT NULL,
    user_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: close_votes_voters_close_votes_voter_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.close_votes_voters_close_votes_voter_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: close_votes_voters_close_votes_voter_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.close_votes_voters_close_votes_voter_id_seq OWNED BY public.close_votes_voters.close_votes_voter_id;


--
-- Name: counter_table; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.counter_table (
    count_id bigint NOT NULL,
    table_name name NOT NULL,
    group_crit bigint,
    difference bigint NOT NULL
);


--
-- Name: counter_table_count_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.counter_table_count_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: counter_table_count_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.counter_table_count_id_seq OWNED BY public.counter_table.count_id;


--
-- Name: events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.events (
    event_id integer NOT NULL,
    name text NOT NULL,
    description text NOT NULL,
    location text,
    maps_link text,
    start_date date NOT NULL,
    end_date date NOT NULL,
    visible boolean NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: events_event_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.events_event_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: events_event_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.events_event_id_seq OWNED BY public.events.event_id;


--
-- Name: forum_stats; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.forum_stats (
    forum_stat_id integer NOT NULL,
    forum_id integer NOT NULL,
    moment date NOT NULL,
    messages integer NOT NULL,
    threads integer NOT NULL
);


--
-- Name: forum_stats_forum_stat_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.forum_stats_forum_stat_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: forum_stats_forum_stat_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.forum_stats_forum_stat_id_seq OWNED BY public.forum_stats.forum_stat_id;


--
-- Name: forums; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.forums (
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

CREATE SEQUENCE public.forums_forum_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: forums_forum_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.forums_forum_id_seq OWNED BY public.forums.forum_id;


--
-- Name: forums_groups_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.forums_groups_permissions (
    forum_group_permission_id bigint NOT NULL,
    permission character varying(50) NOT NULL,
    group_id bigint NOT NULL,
    forum_id bigint NOT NULL
);


--
-- Name: forums_groups_permissions_forum_group_permission_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.forums_groups_permissions_forum_group_permission_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: forums_groups_permissions_forum_group_permission_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.forums_groups_permissions_forum_group_permission_id_seq OWNED BY public.forums_groups_permissions.forum_group_permission_id;


--
-- Name: groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.groups (
    group_id bigint NOT NULL,
    name character varying(255) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: groups_group_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.groups_group_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: groups_group_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.groups_group_id_seq OWNED BY public.groups.group_id;


--
-- Name: groups_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.groups_users (
    group_user_id bigint NOT NULL,
    group_id bigint NOT NULL,
    user_id bigint NOT NULL
);


--
-- Name: groups_users_group_user_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.groups_users_group_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: groups_users_group_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.groups_users_group_user_id_seq OWNED BY public.groups_users.group_user_id;


--
-- Name: interesting_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.interesting_messages (
    interesting_message_id bigint NOT NULL,
    message_id bigint NOT NULL,
    user_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: interesting_messages_interesting_message_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.interesting_messages_interesting_message_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: interesting_messages_interesting_message_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.interesting_messages_interesting_message_id_seq OWNED BY public.interesting_messages.interesting_message_id;


--
-- Name: invisible_threads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.invisible_threads (
    invisible_thread_id bigint NOT NULL,
    user_id integer NOT NULL,
    thread_id bigint NOT NULL
);


--
-- Name: invisible_threads_invisible_thread_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.invisible_threads_invisible_thread_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: invisible_threads_invisible_thread_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.invisible_threads_invisible_thread_id_seq OWNED BY public.invisible_threads.invisible_thread_id;


--
-- Name: media; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.media (
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

CREATE SEQUENCE public.media_medium_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: media_medium_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.media_medium_id_seq OWNED BY public.media.medium_id;


--
-- Name: message_references; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.message_references (
    message_reference_id bigint NOT NULL,
    src_message_id bigint NOT NULL,
    dst_message_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: message_references_message_reference_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.message_references_message_reference_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: message_references_message_reference_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.message_references_message_reference_id_seq OWNED BY public.message_references.message_reference_id;


--
-- Name: message_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.message_versions (
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

CREATE SEQUENCE public.message_versions_message_version_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: message_versions_message_version_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.message_versions_message_version_id_seq OWNED BY public.message_versions.message_version_id;


--
-- Name: messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messages (
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
    flags jsonb,
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

CREATE SEQUENCE public.messages_message_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: messages_message_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.messages_message_id_seq OWNED BY public.messages.message_id;


--
-- Name: messages_tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messages_tags (
    message_tag_id bigint NOT NULL,
    message_id bigint NOT NULL,
    tag_id bigint NOT NULL
);


--
-- Name: messages_tags_message_tag_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.messages_tags_message_tag_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: messages_tags_message_tag_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.messages_tags_message_tag_id_seq OWNED BY public.messages_tags.message_tag_id;


--
-- Name: moderation_queue; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.moderation_queue (
    moderation_queue_entry_id bigint NOT NULL,
    message_id bigint NOT NULL,
    cleared boolean DEFAULT false NOT NULL,
    reported integer NOT NULL,
    reason character varying NOT NULL,
    duplicate_url character varying,
    custom_reason character varying,
    resolution text,
    resolution_action character varying(250),
    closer_name character varying(255),
    closer_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: moderation_queue_moderation_queue_entry_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.moderation_queue_moderation_queue_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: moderation_queue_moderation_queue_entry_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.moderation_queue_moderation_queue_entry_id_seq OWNED BY public.moderation_queue.moderation_queue_entry_id;


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notifications (
    notification_id bigint NOT NULL,
    recipient_id bigint NOT NULL,
    is_read boolean DEFAULT false NOT NULL,
    subject character varying(250) NOT NULL,
    path character varying(250) NOT NULL,
    icon character varying(250),
    oid bigint NOT NULL,
    otype character varying(100) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    description text
);


--
-- Name: notifications_notification_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notifications_notification_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notifications_notification_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notifications_notification_id_seq OWNED BY public.notifications.notification_id;


--
-- Name: opened_closed_threads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.opened_closed_threads (
    opened_closed_thread_id bigint NOT NULL,
    user_id integer NOT NULL,
    thread_id bigint NOT NULL,
    state character varying(10) NOT NULL
);


--
-- Name: opened_closed_threads_opened_closed_thread_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.opened_closed_threads_opened_closed_thread_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: opened_closed_threads_opened_closed_thread_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.opened_closed_threads_opened_closed_thread_id_seq OWNED BY public.opened_closed_threads.opened_closed_thread_id;


--
-- Name: priv_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.priv_messages (
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
    recipient_name character varying NOT NULL,
    thread_id bigint NOT NULL
);


--
-- Name: priv_messages_priv_message_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.priv_messages_priv_message_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: priv_messages_priv_message_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.priv_messages_priv_message_id_seq OWNED BY public.priv_messages.priv_message_id;


--
-- Name: priv_messages_thread_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.priv_messages_thread_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: priv_messages_thread_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.priv_messages_thread_id_seq OWNED BY public.priv_messages.thread_id;


--
-- Name: read_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.read_messages (
    read_message_id bigint NOT NULL,
    user_id integer NOT NULL,
    message_id bigint NOT NULL
);


--
-- Name: read_messages_read_message_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.read_messages_read_message_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: read_messages_read_message_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.read_messages_read_message_id_seq OWNED BY public.read_messages.read_message_id;


--
-- Name: redirections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.redirections (
    redirection_id bigint NOT NULL,
    path character varying NOT NULL,
    destination character varying NOT NULL,
    http_status integer NOT NULL,
    comment text
);


--
-- Name: redirections_redirection_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.redirections_redirection_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: redirections_redirection_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.redirections_redirection_id_seq OWNED BY public.redirections.redirection_id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: scores; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.scores (
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

CREATE SEQUENCE public.scores_score_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scores_score_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.scores_score_id_seq OWNED BY public.scores.score_id;


--
-- Name: search_documents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.search_documents (
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

CREATE SEQUENCE public.search_documents_search_document_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: search_documents_search_document_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.search_documents_search_document_id_seq OWNED BY public.search_documents.search_document_id;


--
-- Name: search_sections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.search_sections (
    search_section_id integer NOT NULL,
    name text NOT NULL,
    "position" integer NOT NULL,
    active_by_default boolean DEFAULT false NOT NULL,
    forum_id bigint
);


--
-- Name: search_sections_search_section_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.search_sections_search_section_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: search_sections_search_section_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.search_sections_search_section_id_seq OWNED BY public.search_sections.search_section_id;


--
-- Name: settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.settings (
    setting_id bigint NOT NULL,
    forum_id bigint,
    user_id bigint,
    options jsonb
);


--
-- Name: settings_setting_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.settings_setting_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: settings_setting_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.settings_setting_id_seq OWNED BY public.settings.setting_id;


--
-- Name: subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.subscriptions (
    subscription_id integer NOT NULL,
    user_id integer,
    message_id integer
);


--
-- Name: subscriptions_subscription_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.subscriptions_subscription_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: subscriptions_subscription_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.subscriptions_subscription_id_seq OWNED BY public.subscriptions.subscription_id;


--
-- Name: tag_synonyms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tag_synonyms (
    tag_synonym_id bigint NOT NULL,
    tag_id bigint NOT NULL,
    forum_id bigint NOT NULL,
    synonym character varying(250) NOT NULL
);


--
-- Name: tag_synonyms_tag_synonym_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tag_synonyms_tag_synonym_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tag_synonyms_tag_synonym_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tag_synonyms_tag_synonym_id_seq OWNED BY public.tag_synonyms.tag_synonym_id;


--
-- Name: tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tags (
    tag_id bigint NOT NULL,
    tag_name character varying NOT NULL,
    slug character varying NOT NULL,
    forum_id bigint NOT NULL,
    num_messages bigint DEFAULT 0 NOT NULL,
    suggest boolean DEFAULT true NOT NULL
)
WITH (fillfactor='90');


--
-- Name: tags_tag_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tags_tag_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tags_tag_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tags_tag_id_seq OWNED BY public.tags.tag_id;


--
-- Name: threads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.threads (
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
    flags jsonb,
    latest_message timestamp without time zone NOT NULL
);


--
-- Name: threads_thread_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.threads_thread_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: threads_thread_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.threads_thread_id_seq OWNED BY public.threads.thread_id;


--
-- Name: twitter_authorizations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.twitter_authorizations (
    twitter_authorization_id integer NOT NULL,
    user_id integer,
    token text NOT NULL,
    secret text NOT NULL
);


--
-- Name: twitter_authorizations_twitter_authorization_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.twitter_authorizations_twitter_authorization_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: twitter_authorizations_twitter_authorization_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.twitter_authorizations_twitter_authorization_id_seq OWNED BY public.twitter_authorizations.twitter_authorization_id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
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
    score integer DEFAULT 0 NOT NULL,
    activity integer DEFAULT 0 NOT NULL
);


--
-- Name: users_user_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_user_id_seq OWNED BY public.users.user_id;


--
-- Name: votes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.votes (
    vote_id bigint NOT NULL,
    user_id bigint NOT NULL,
    message_id bigint NOT NULL,
    vtype character varying(50) NOT NULL
);


--
-- Name: votes_vote_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.votes_vote_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: votes_vote_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.votes_vote_id_seq OWNED BY public.votes.vote_id;


--
-- Name: attendees attendee_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attendees ALTER COLUMN attendee_id SET DEFAULT nextval('public.attendees_attendee_id_seq'::regclass);


--
-- Name: auditing auditing_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditing ALTER COLUMN auditing_id SET DEFAULT nextval('public.auditing_auditing_id_seq'::regclass);


--
-- Name: badge_groups badge_group_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.badge_groups ALTER COLUMN badge_group_id SET DEFAULT nextval('public.badge_groups_badge_group_id_seq'::regclass);


--
-- Name: badges badge_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.badges ALTER COLUMN badge_id SET DEFAULT nextval('public.badges_badge_id_seq'::regclass);


--
-- Name: badges_badge_groups badges_badge_group_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.badges_badge_groups ALTER COLUMN badges_badge_group_id SET DEFAULT nextval('public.badges_badge_groups_badges_badge_group_id_seq'::regclass);


--
-- Name: badges_users badge_user_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.badges_users ALTER COLUMN badge_user_id SET DEFAULT nextval('public.badges_users_badge_user_id_seq'::regclass);


--
-- Name: cites cite_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cites ALTER COLUMN cite_id SET DEFAULT nextval('public.cites_cite_id_seq'::regclass);


--
-- Name: cites_votes cite_vote_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cites_votes ALTER COLUMN cite_vote_id SET DEFAULT nextval('public.cites_votes_cite_vote_id_seq'::regclass);


--
-- Name: close_votes close_vote_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.close_votes ALTER COLUMN close_vote_id SET DEFAULT nextval('public.close_votes_close_vote_id_seq'::regclass);


--
-- Name: close_votes_voters close_votes_voter_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.close_votes_voters ALTER COLUMN close_votes_voter_id SET DEFAULT nextval('public.close_votes_voters_close_votes_voter_id_seq'::regclass);


--
-- Name: counter_table count_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.counter_table ALTER COLUMN count_id SET DEFAULT nextval('public.counter_table_count_id_seq'::regclass);


--
-- Name: events event_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events ALTER COLUMN event_id SET DEFAULT nextval('public.events_event_id_seq'::regclass);


--
-- Name: forum_stats forum_stat_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.forum_stats ALTER COLUMN forum_stat_id SET DEFAULT nextval('public.forum_stats_forum_stat_id_seq'::regclass);


--
-- Name: forums forum_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.forums ALTER COLUMN forum_id SET DEFAULT nextval('public.forums_forum_id_seq'::regclass);


--
-- Name: forums_groups_permissions forum_group_permission_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.forums_groups_permissions ALTER COLUMN forum_group_permission_id SET DEFAULT nextval('public.forums_groups_permissions_forum_group_permission_id_seq'::regclass);


--
-- Name: groups group_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups ALTER COLUMN group_id SET DEFAULT nextval('public.groups_group_id_seq'::regclass);


--
-- Name: groups_users group_user_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups_users ALTER COLUMN group_user_id SET DEFAULT nextval('public.groups_users_group_user_id_seq'::regclass);


--
-- Name: interesting_messages interesting_message_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.interesting_messages ALTER COLUMN interesting_message_id SET DEFAULT nextval('public.interesting_messages_interesting_message_id_seq'::regclass);


--
-- Name: invisible_threads invisible_thread_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invisible_threads ALTER COLUMN invisible_thread_id SET DEFAULT nextval('public.invisible_threads_invisible_thread_id_seq'::regclass);


--
-- Name: media medium_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media ALTER COLUMN medium_id SET DEFAULT nextval('public.media_medium_id_seq'::regclass);


--
-- Name: message_references message_reference_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_references ALTER COLUMN message_reference_id SET DEFAULT nextval('public.message_references_message_reference_id_seq'::regclass);


--
-- Name: message_versions message_version_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_versions ALTER COLUMN message_version_id SET DEFAULT nextval('public.message_versions_message_version_id_seq'::regclass);


--
-- Name: messages message_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages ALTER COLUMN message_id SET DEFAULT nextval('public.messages_message_id_seq'::regclass);


--
-- Name: messages_tags message_tag_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages_tags ALTER COLUMN message_tag_id SET DEFAULT nextval('public.messages_tags_message_tag_id_seq'::regclass);


--
-- Name: moderation_queue moderation_queue_entry_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.moderation_queue ALTER COLUMN moderation_queue_entry_id SET DEFAULT nextval('public.moderation_queue_moderation_queue_entry_id_seq'::regclass);


--
-- Name: notifications notification_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications ALTER COLUMN notification_id SET DEFAULT nextval('public.notifications_notification_id_seq'::regclass);


--
-- Name: opened_closed_threads opened_closed_thread_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.opened_closed_threads ALTER COLUMN opened_closed_thread_id SET DEFAULT nextval('public.opened_closed_threads_opened_closed_thread_id_seq'::regclass);


--
-- Name: priv_messages priv_message_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.priv_messages ALTER COLUMN priv_message_id SET DEFAULT nextval('public.priv_messages_priv_message_id_seq'::regclass);


--
-- Name: priv_messages thread_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.priv_messages ALTER COLUMN thread_id SET DEFAULT nextval('public.priv_messages_thread_id_seq'::regclass);


--
-- Name: read_messages read_message_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.read_messages ALTER COLUMN read_message_id SET DEFAULT nextval('public.read_messages_read_message_id_seq'::regclass);


--
-- Name: redirections redirection_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.redirections ALTER COLUMN redirection_id SET DEFAULT nextval('public.redirections_redirection_id_seq'::regclass);


--
-- Name: scores score_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scores ALTER COLUMN score_id SET DEFAULT nextval('public.scores_score_id_seq'::regclass);


--
-- Name: search_documents search_document_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.search_documents ALTER COLUMN search_document_id SET DEFAULT nextval('public.search_documents_search_document_id_seq'::regclass);


--
-- Name: search_sections search_section_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.search_sections ALTER COLUMN search_section_id SET DEFAULT nextval('public.search_sections_search_section_id_seq'::regclass);


--
-- Name: settings setting_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settings ALTER COLUMN setting_id SET DEFAULT nextval('public.settings_setting_id_seq'::regclass);


--
-- Name: subscriptions subscription_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions ALTER COLUMN subscription_id SET DEFAULT nextval('public.subscriptions_subscription_id_seq'::regclass);


--
-- Name: tag_synonyms tag_synonym_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tag_synonyms ALTER COLUMN tag_synonym_id SET DEFAULT nextval('public.tag_synonyms_tag_synonym_id_seq'::regclass);


--
-- Name: tags tag_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags ALTER COLUMN tag_id SET DEFAULT nextval('public.tags_tag_id_seq'::regclass);


--
-- Name: threads thread_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.threads ALTER COLUMN thread_id SET DEFAULT nextval('public.threads_thread_id_seq'::regclass);


--
-- Name: twitter_authorizations twitter_authorization_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.twitter_authorizations ALTER COLUMN twitter_authorization_id SET DEFAULT nextval('public.twitter_authorizations_twitter_authorization_id_seq'::regclass);


--
-- Name: users user_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN user_id SET DEFAULT nextval('public.users_user_id_seq'::regclass);


--
-- Name: votes vote_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.votes ALTER COLUMN vote_id SET DEFAULT nextval('public.votes_vote_id_seq'::regclass);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: attendees attendees_event_id_user_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attendees
    ADD CONSTRAINT attendees_event_id_user_id_key UNIQUE (event_id, user_id);


--
-- Name: attendees attendees_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attendees
    ADD CONSTRAINT attendees_pkey PRIMARY KEY (attendee_id);


--
-- Name: auditing auditing_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditing
    ADD CONSTRAINT auditing_pkey PRIMARY KEY (auditing_id);


--
-- Name: badge_groups badge_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.badge_groups
    ADD CONSTRAINT badge_groups_pkey PRIMARY KEY (badge_group_id);


--
-- Name: badges_badge_groups badges_badge_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.badges_badge_groups
    ADD CONSTRAINT badges_badge_groups_pkey PRIMARY KEY (badges_badge_group_id);


--
-- Name: badges badges_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.badges
    ADD CONSTRAINT badges_pkey PRIMARY KEY (badge_id);


--
-- Name: badges badges_slug_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.badges
    ADD CONSTRAINT badges_slug_key UNIQUE (slug);


--
-- Name: badges_users badges_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.badges_users
    ADD CONSTRAINT badges_users_pkey PRIMARY KEY (badge_user_id);


--
-- Name: cites cites_old_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cites
    ADD CONSTRAINT cites_old_id_key UNIQUE (old_id);


--
-- Name: cites cites_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cites
    ADD CONSTRAINT cites_pkey PRIMARY KEY (cite_id);


--
-- Name: cites_votes cites_votes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cites_votes
    ADD CONSTRAINT cites_votes_pkey PRIMARY KEY (cite_vote_id);


--
-- Name: close_votes close_votes_message_id_vote_type_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.close_votes
    ADD CONSTRAINT close_votes_message_id_vote_type_key UNIQUE (message_id, vote_type);


--
-- Name: close_votes close_votes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.close_votes
    ADD CONSTRAINT close_votes_pkey PRIMARY KEY (close_vote_id);


--
-- Name: close_votes_voters close_votes_voters_close_vote_id_user_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.close_votes_voters
    ADD CONSTRAINT close_votes_voters_close_vote_id_user_id_key UNIQUE (close_vote_id, user_id);


--
-- Name: close_votes_voters close_votes_voters_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.close_votes_voters
    ADD CONSTRAINT close_votes_voters_pkey PRIMARY KEY (close_votes_voter_id);


--
-- Name: counter_table counter_table_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.counter_table
    ADD CONSTRAINT counter_table_pkey PRIMARY KEY (count_id);


--
-- Name: events events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_pkey PRIMARY KEY (event_id);


--
-- Name: forum_stats forum_stats_forum_id_moment_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.forum_stats
    ADD CONSTRAINT forum_stats_forum_id_moment_key UNIQUE (forum_id, moment);


--
-- Name: forum_stats forum_stats_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.forum_stats
    ADD CONSTRAINT forum_stats_pkey PRIMARY KEY (forum_stat_id);


--
-- Name: forums_groups_permissions forums_groups_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.forums_groups_permissions
    ADD CONSTRAINT forums_groups_permissions_pkey PRIMARY KEY (forum_group_permission_id);


--
-- Name: forums forums_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.forums
    ADD CONSTRAINT forums_pkey PRIMARY KEY (forum_id);


--
-- Name: groups groups_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT groups_name_key UNIQUE (name);


--
-- Name: groups groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT groups_pkey PRIMARY KEY (group_id);


--
-- Name: groups_users groups_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups_users
    ADD CONSTRAINT groups_users_pkey PRIMARY KEY (group_user_id);


--
-- Name: interesting_messages interesting_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.interesting_messages
    ADD CONSTRAINT interesting_messages_pkey PRIMARY KEY (interesting_message_id);


--
-- Name: invisible_threads invisible_threads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invisible_threads
    ADD CONSTRAINT invisible_threads_pkey PRIMARY KEY (invisible_thread_id);


--
-- Name: media media_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media
    ADD CONSTRAINT media_pkey PRIMARY KEY (medium_id);


--
-- Name: message_references message_references_dst_message_id_src_message_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_references
    ADD CONSTRAINT message_references_dst_message_id_src_message_id_key UNIQUE (dst_message_id, src_message_id);


--
-- Name: message_references message_references_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_references
    ADD CONSTRAINT message_references_pkey PRIMARY KEY (message_reference_id);


--
-- Name: message_versions message_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_versions
    ADD CONSTRAINT message_versions_pkey PRIMARY KEY (message_version_id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (message_id);


--
-- Name: messages_tags messages_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages_tags
    ADD CONSTRAINT messages_tags_pkey PRIMARY KEY (message_tag_id);


--
-- Name: moderation_queue moderation_queue_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.moderation_queue
    ADD CONSTRAINT moderation_queue_pkey PRIMARY KEY (moderation_queue_entry_id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (notification_id);


--
-- Name: opened_closed_threads opened_closed_threads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.opened_closed_threads
    ADD CONSTRAINT opened_closed_threads_pkey PRIMARY KEY (opened_closed_thread_id);


--
-- Name: priv_messages priv_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.priv_messages
    ADD CONSTRAINT priv_messages_pkey PRIMARY KEY (priv_message_id);


--
-- Name: read_messages read_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.read_messages
    ADD CONSTRAINT read_messages_pkey PRIMARY KEY (read_message_id);


--
-- Name: redirections redirections_path_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.redirections
    ADD CONSTRAINT redirections_path_key UNIQUE (path);


--
-- Name: redirections redirections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.redirections
    ADD CONSTRAINT redirections_pkey PRIMARY KEY (redirection_id);


--
-- Name: scores scores_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scores
    ADD CONSTRAINT scores_pkey PRIMARY KEY (score_id);


--
-- Name: search_documents search_documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.search_documents
    ADD CONSTRAINT search_documents_pkey PRIMARY KEY (search_document_id);


--
-- Name: search_documents search_documents_reference_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.search_documents
    ADD CONSTRAINT search_documents_reference_id_key UNIQUE (reference_id);


--
-- Name: search_documents search_documents_url_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.search_documents
    ADD CONSTRAINT search_documents_url_key UNIQUE (url);


--
-- Name: search_sections search_sections_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.search_sections
    ADD CONSTRAINT search_sections_name_key UNIQUE (name);


--
-- Name: search_sections search_sections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.search_sections
    ADD CONSTRAINT search_sections_pkey PRIMARY KEY (search_section_id);


--
-- Name: settings settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settings
    ADD CONSTRAINT settings_pkey PRIMARY KEY (setting_id);


--
-- Name: subscriptions subscriptions_message_id_user_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_message_id_user_id_key UNIQUE (message_id, user_id);


--
-- Name: subscriptions subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_pkey PRIMARY KEY (subscription_id);


--
-- Name: tag_synonyms tag_synonyms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tag_synonyms
    ADD CONSTRAINT tag_synonyms_pkey PRIMARY KEY (tag_synonym_id);


--
-- Name: tags tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (tag_id);


--
-- Name: threads threads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.threads
    ADD CONSTRAINT threads_pkey PRIMARY KEY (thread_id);


--
-- Name: twitter_authorizations twitter_authorizations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.twitter_authorizations
    ADD CONSTRAINT twitter_authorizations_pkey PRIMARY KEY (twitter_authorization_id);


--
-- Name: twitter_authorizations twitter_authorizations_user_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.twitter_authorizations
    ADD CONSTRAINT twitter_authorizations_user_id_key UNIQUE (user_id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- Name: votes votes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.votes
    ADD CONSTRAINT votes_pkey PRIMARY KEY (vote_id);


--
-- Name: badge_groups_lower_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX badge_groups_lower_idx ON public.badge_groups USING btree (lower(name));


--
-- Name: badges_badge_type_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX badges_badge_type_idx ON public.badges USING btree (badge_type) WHERE ((badge_type)::text <> 'custom'::text);


--
-- Name: cites_votes_cite_id_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX cites_votes_cite_id_user_id_idx ON public.cites_votes USING btree (cite_id, user_id);


--
-- Name: counter_table_table_name_group_crit_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX counter_table_table_name_group_crit_idx ON public.counter_table USING btree (table_name, group_crit);


--
-- Name: events_lower_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX events_lower_idx ON public.events USING btree (lower(name));


--
-- Name: forums_slug_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX forums_slug_idx ON public.forums USING btree (slug);


--
-- Name: invisible_threads_thread_id_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX invisible_threads_thread_id_user_id_idx ON public.invisible_threads USING btree (thread_id, user_id);


--
-- Name: messages_editor_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messages_editor_id_idx ON public.messages USING btree (editor_id);


--
-- Name: messages_forum_id_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messages_forum_id_created_at_idx ON public.messages USING btree (forum_id, created_at);


--
-- Name: messages_mid_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messages_mid_idx ON public.messages USING btree (mid);


--
-- Name: messages_parent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messages_parent_id_idx ON public.messages USING btree (parent_id);


--
-- Name: messages_tags_message_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messages_tags_message_id_idx ON public.messages_tags USING btree (message_id);


--
-- Name: messages_tags_tag_id_message_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messages_tags_tag_id_message_id_idx ON public.messages_tags USING btree (tag_id, message_id);


--
-- Name: messages_thread_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messages_thread_id_idx ON public.messages USING btree (thread_id);


--
-- Name: messages_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messages_updated_at_idx ON public.messages USING btree (updated_at);


--
-- Name: messages_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messages_user_id_idx ON public.messages USING btree (user_id);


--
-- Name: moderation_queue_message_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX moderation_queue_message_id_idx ON public.moderation_queue USING btree (message_id) WHERE (cleared = true);


--
-- Name: notifications_recipient_id_oid_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX notifications_recipient_id_oid_idx ON public.notifications USING btree (recipient_id, oid);


--
-- Name: opened_closed_threads_thread_id_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX opened_closed_threads_thread_id_user_id_idx ON public.opened_closed_threads USING btree (thread_id, user_id);


--
-- Name: priv_messages_owner_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX priv_messages_owner_id_idx ON public.priv_messages USING btree (owner_id);


--
-- Name: priv_messages_recipient_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX priv_messages_recipient_id_idx ON public.priv_messages USING btree (recipient_id);


--
-- Name: priv_messages_sender_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX priv_messages_sender_id_idx ON public.priv_messages USING btree (sender_id);


--
-- Name: read_messages_message_id_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX read_messages_message_id_user_id_idx ON public.read_messages USING btree (message_id, user_id);


--
-- Name: read_messages_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX read_messages_user_id_idx ON public.read_messages USING btree (user_id);


--
-- Name: scores_user_id_message_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX scores_user_id_message_id_idx ON public.scores USING btree (user_id, message_id) WHERE (message_id IS NOT NULL);


--
-- Name: scores_user_id_vote_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX scores_user_id_vote_id_idx ON public.scores USING btree (user_id, vote_id) WHERE (vote_id IS NOT NULL);


--
-- Name: search_documents_author_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX search_documents_author_idx ON public.search_documents USING gin (ts_author);


--
-- Name: search_documents_content_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX search_documents_content_idx ON public.search_documents USING gin (ts_content);


--
-- Name: search_documents_document_created_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX search_documents_document_created_idx ON public.search_documents USING btree (document_created);


--
-- Name: search_documents_document_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX search_documents_document_idx ON public.search_documents USING gin (ts_document);


--
-- Name: search_documents_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX search_documents_tags_idx ON public.search_documents USING gin (tags);


--
-- Name: search_documents_title_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX search_documents_title_idx ON public.search_documents USING gin (ts_title);


--
-- Name: search_documents_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX search_documents_user_id_idx ON public.search_documents USING btree (user_id);


--
-- Name: settings_forum_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX settings_forum_id_idx ON public.settings USING btree (forum_id);


--
-- Name: settings_forum_id_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX settings_forum_id_user_id_idx ON public.settings USING btree (forum_id, user_id);


--
-- Name: settings_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX settings_user_id_idx ON public.settings USING btree (user_id);


--
-- Name: tag_synonyms_forum_id_synonym_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX tag_synonyms_forum_id_synonym_idx ON public.tag_synonyms USING btree (forum_id, synonym);


--
-- Name: tag_synonyms_synonym_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tag_synonyms_synonym_idx ON public.tag_synonyms USING btree (synonym);


--
-- Name: tag_synonyms_tag_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tag_synonyms_tag_id_idx ON public.tag_synonyms USING btree (tag_id);


--
-- Name: tags_forum_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tags_forum_id_idx ON public.tags USING btree (forum_id);


--
-- Name: tags_tag_name_forum_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX tags_tag_name_forum_id_idx ON public.tags USING btree (tag_name, forum_id);


--
-- Name: threads_archived_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX threads_archived_idx ON public.threads USING btree (archived);


--
-- Name: threads_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX threads_created_at_idx ON public.threads USING btree (created_at);


--
-- Name: threads_forum_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX threads_forum_id_idx ON public.threads USING btree (forum_id);


--
-- Name: threads_message_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX threads_message_id_idx ON public.threads USING btree (message_id);


--
-- Name: threads_slug_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX threads_slug_idx ON public.threads USING btree (slug);


--
-- Name: threads_sticky_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX threads_sticky_created_at_idx ON public.threads USING btree (sticky, created_at);


--
-- Name: threads_tid_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX threads_tid_idx ON public.threads USING btree (tid);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_schema_migrations ON public.schema_migrations USING btree (version);


--
-- Name: users_authentication_token_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_authentication_token_idx ON public.users USING btree (authentication_token);


--
-- Name: users_confirmation_token_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_confirmation_token_idx ON public.users USING btree (confirmation_token);


--
-- Name: users_email_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_email_idx ON public.users USING btree (lower((email)::text));


--
-- Name: users_reset_password_token_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_reset_password_token_idx ON public.users USING btree (reset_password_token);


--
-- Name: users_username_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_username_idx ON public.users USING btree (lower((username)::text));


--
-- Name: votes_user_id_message_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX votes_user_id_message_id_idx ON public.votes USING btree (user_id, message_id);


--
-- Name: messages messages__cache_activity_delete_trg; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER messages__cache_activity_delete_trg AFTER DELETE ON public.messages FOR EACH ROW EXECUTE PROCEDURE public.cache_user_activity_delete_trigger();


--
-- Name: messages messages__cache_activity_insert_update_trg; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER messages__cache_activity_insert_update_trg AFTER INSERT OR UPDATE ON public.messages FOR EACH ROW EXECUTE PROCEDURE public.cache_user_activity_insert_update_trigger();


--
-- Name: messages messages__count_delete_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER messages__count_delete_trigger AFTER DELETE ON public.messages FOR EACH ROW EXECUTE PROCEDURE public.count_messages_delete_trigger();


--
-- Name: forums messages__count_insert_forum_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER messages__count_insert_forum_trigger AFTER INSERT ON public.forums FOR EACH ROW EXECUTE PROCEDURE public.count_messages_insert_forum_trigger();


--
-- Name: messages messages__count_insert_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER messages__count_insert_trigger AFTER INSERT ON public.messages FOR EACH ROW EXECUTE PROCEDURE public.count_messages_insert_trigger();


--
-- Name: messages messages__count_truncate_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER messages__count_truncate_trigger AFTER TRUNCATE ON public.messages FOR EACH STATEMENT EXECUTE PROCEDURE public.count_messages_truncate_trigger();


--
-- Name: messages messages__count_update_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER messages__count_update_trigger AFTER UPDATE ON public.messages FOR EACH ROW EXECUTE PROCEDURE public.count_messages_update_trigger();


--
-- Name: messages messages__thread_set_latest_trigger_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER messages__thread_set_latest_trigger_insert AFTER INSERT ON public.messages FOR EACH ROW EXECUTE PROCEDURE public.messages__thread_set_latest_insert();


--
-- Name: messages messages__thread_set_latest_trigger_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER messages__thread_set_latest_trigger_update AFTER DELETE OR UPDATE ON public.messages FOR EACH ROW EXECUTE PROCEDURE public.messages__thread_set_latest_update_delete();


--
-- Name: messages_tags messages_tags__count_delete_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER messages_tags__count_delete_trigger AFTER DELETE ON public.messages_tags FOR EACH ROW EXECUTE PROCEDURE public.count_messages_tag_delete_trigger();


--
-- Name: messages_tags messages_tags__count_insert_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER messages_tags__count_insert_trigger AFTER INSERT ON public.messages_tags FOR EACH ROW EXECUTE PROCEDURE public.count_messages_tag_insert_trigger();


--
-- Name: scores scores__cache_scores_delete_trg; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER scores__cache_scores_delete_trg AFTER DELETE ON public.scores FOR EACH ROW EXECUTE PROCEDURE public.cache_user_score_delete_trigger();


--
-- Name: scores scores__cache_scores_insert_trg; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER scores__cache_scores_insert_trg AFTER INSERT ON public.scores FOR EACH ROW EXECUTE PROCEDURE public.cache_user_score_insert_trigger();


--
-- Name: scores scores__cache_scores_update_trg; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER scores__cache_scores_update_trg AFTER UPDATE ON public.scores FOR EACH ROW EXECUTE PROCEDURE public.cache_user_score_update_trigger();


--
-- Name: search_documents search_documents__before_insert_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER search_documents__before_insert_trigger BEFORE INSERT ON public.search_documents FOR EACH ROW EXECUTE PROCEDURE public.search_document_before_insert();


--
-- Name: search_documents search_documents__before_update_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER search_documents__before_update_trigger BEFORE UPDATE ON public.search_documents FOR EACH ROW EXECUTE PROCEDURE public.search_document_before_insert();


--
-- Name: settings settings_unique_check_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER settings_unique_check_insert BEFORE INSERT ON public.settings FOR EACH ROW EXECUTE PROCEDURE public.settings_unique_check__insert();


--
-- Name: settings settings_unique_check_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER settings_unique_check_update BEFORE UPDATE ON public.settings FOR EACH ROW EXECUTE PROCEDURE public.settings_unique_check__update();


--
-- Name: threads threads__count_delete_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER threads__count_delete_trigger AFTER DELETE ON public.threads FOR EACH ROW EXECUTE PROCEDURE public.count_threads_delete_trigger();


--
-- Name: forums threads__count_insert_forum_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER threads__count_insert_forum_trigger AFTER INSERT ON public.forums FOR EACH ROW EXECUTE PROCEDURE public.count_threads_insert_forum_trigger();


--
-- Name: threads threads__count_insert_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER threads__count_insert_trigger AFTER INSERT ON public.threads FOR EACH ROW EXECUTE PROCEDURE public.count_threads_insert_trigger();


--
-- Name: threads threads__count_truncate_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER threads__count_truncate_trigger AFTER TRUNCATE ON public.threads FOR EACH STATEMENT EXECUTE PROCEDURE public.count_threads_truncate_trigger();


--
-- Name: threads threads__count_update_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER threads__count_update_trigger AFTER UPDATE ON public.threads FOR EACH ROW EXECUTE PROCEDURE public.count_threads_update_trigger();


--
-- Name: attendees attendees_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attendees
    ADD CONSTRAINT attendees_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(event_id);


--
-- Name: attendees attendees_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attendees
    ADD CONSTRAINT attendees_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: auditing auditing_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditing
    ADD CONSTRAINT auditing_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: badges_badge_groups badges_badge_groups_badge_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.badges_badge_groups
    ADD CONSTRAINT badges_badge_groups_badge_group_id_fkey FOREIGN KEY (badge_group_id) REFERENCES public.badge_groups(badge_group_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: badges_badge_groups badges_badge_groups_badge_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.badges_badge_groups
    ADD CONSTRAINT badges_badge_groups_badge_id_fkey FOREIGN KEY (badge_id) REFERENCES public.badges(badge_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: badges_users badges_users_badge_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.badges_users
    ADD CONSTRAINT badges_users_badge_id_fkey FOREIGN KEY (badge_id) REFERENCES public.badges(badge_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: badges_users badges_users_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.badges_users
    ADD CONSTRAINT badges_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: cites cites_creator_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cites
    ADD CONSTRAINT cites_creator_user_id_fkey FOREIGN KEY (creator_user_id) REFERENCES public.users(user_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: cites cites_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cites
    ADD CONSTRAINT cites_message_id_fkey FOREIGN KEY (message_id) REFERENCES public.messages(message_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: cites cites_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cites
    ADD CONSTRAINT cites_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: cites_votes cites_votes_cite_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cites_votes
    ADD CONSTRAINT cites_votes_cite_id_fkey FOREIGN KEY (cite_id) REFERENCES public.cites(cite_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: cites_votes cites_votes_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cites_votes
    ADD CONSTRAINT cites_votes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: close_votes close_votes_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.close_votes
    ADD CONSTRAINT close_votes_message_id_fkey FOREIGN KEY (message_id) REFERENCES public.messages(message_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: close_votes_voters close_votes_voters_close_vote_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.close_votes_voters
    ADD CONSTRAINT close_votes_voters_close_vote_id_fkey FOREIGN KEY (close_vote_id) REFERENCES public.close_votes(close_vote_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: forum_stats forum_stats_forum_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.forum_stats
    ADD CONSTRAINT forum_stats_forum_id_fkey FOREIGN KEY (forum_id) REFERENCES public.forums(forum_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: forums_groups_permissions forums_groups_permissions_forum_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.forums_groups_permissions
    ADD CONSTRAINT forums_groups_permissions_forum_id_fkey FOREIGN KEY (forum_id) REFERENCES public.forums(forum_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: forums_groups_permissions forums_groups_permissions_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.forums_groups_permissions
    ADD CONSTRAINT forums_groups_permissions_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.groups(group_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: groups_users groups_users_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups_users
    ADD CONSTRAINT groups_users_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.groups(group_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: groups_users groups_users_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups_users
    ADD CONSTRAINT groups_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: interesting_messages interesting_messages_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.interesting_messages
    ADD CONSTRAINT interesting_messages_message_id_fkey FOREIGN KEY (message_id) REFERENCES public.messages(message_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: interesting_messages interesting_messages_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.interesting_messages
    ADD CONSTRAINT interesting_messages_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: invisible_threads invisible_threads_thread_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invisible_threads
    ADD CONSTRAINT invisible_threads_thread_id_fkey FOREIGN KEY (thread_id) REFERENCES public.threads(thread_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: invisible_threads invisible_threads_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invisible_threads
    ADD CONSTRAINT invisible_threads_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: media media_owner_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media
    ADD CONSTRAINT media_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.users(user_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: message_references message_references_dst_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_references
    ADD CONSTRAINT message_references_dst_message_id_fkey FOREIGN KEY (dst_message_id) REFERENCES public.messages(message_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: message_references message_references_src_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_references
    ADD CONSTRAINT message_references_src_message_id_fkey FOREIGN KEY (src_message_id) REFERENCES public.messages(message_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: message_versions message_versions_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_versions
    ADD CONSTRAINT message_versions_message_id_fkey FOREIGN KEY (message_id) REFERENCES public.messages(message_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: message_versions message_versions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_versions
    ADD CONSTRAINT message_versions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: messages messages_editor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_editor_id_fkey FOREIGN KEY (editor_id) REFERENCES public.users(user_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: messages messages_forum_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_forum_id_fkey FOREIGN KEY (forum_id) REFERENCES public.forums(forum_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: messages messages_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.messages(message_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: messages_tags messages_tags_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages_tags
    ADD CONSTRAINT messages_tags_message_id_fkey FOREIGN KEY (message_id) REFERENCES public.messages(message_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: messages_tags messages_tags_tag_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages_tags
    ADD CONSTRAINT messages_tags_tag_id_fkey FOREIGN KEY (tag_id) REFERENCES public.tags(tag_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: messages messages_thread_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_thread_id_fkey FOREIGN KEY (thread_id) REFERENCES public.threads(thread_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: messages messages_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: moderation_queue moderation_queue_closer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.moderation_queue
    ADD CONSTRAINT moderation_queue_closer_id_fkey FOREIGN KEY (closer_id) REFERENCES public.users(user_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: moderation_queue moderation_queue_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.moderation_queue
    ADD CONSTRAINT moderation_queue_message_id_fkey FOREIGN KEY (message_id) REFERENCES public.messages(message_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: notifications notifications_recipient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_recipient_id_fkey FOREIGN KEY (recipient_id) REFERENCES public.users(user_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: opened_closed_threads opened_closed_threads_thread_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.opened_closed_threads
    ADD CONSTRAINT opened_closed_threads_thread_id_fkey FOREIGN KEY (thread_id) REFERENCES public.threads(thread_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: opened_closed_threads opened_closed_threads_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.opened_closed_threads
    ADD CONSTRAINT opened_closed_threads_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: priv_messages priv_messages_owner_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.priv_messages
    ADD CONSTRAINT priv_messages_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.users(user_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: priv_messages priv_messages_recipient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.priv_messages
    ADD CONSTRAINT priv_messages_recipient_id_fkey FOREIGN KEY (recipient_id) REFERENCES public.users(user_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: priv_messages priv_messages_sender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.priv_messages
    ADD CONSTRAINT priv_messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.users(user_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: read_messages read_messages_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.read_messages
    ADD CONSTRAINT read_messages_message_id_fkey FOREIGN KEY (message_id) REFERENCES public.messages(message_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: read_messages read_messages_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.read_messages
    ADD CONSTRAINT read_messages_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: scores scores_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scores
    ADD CONSTRAINT scores_message_id_fkey FOREIGN KEY (message_id) REFERENCES public.messages(message_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: scores scores_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scores
    ADD CONSTRAINT scores_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: scores scores_vote_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scores
    ADD CONSTRAINT scores_vote_id_fkey FOREIGN KEY (vote_id) REFERENCES public.votes(vote_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: search_documents search_documents_forum_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.search_documents
    ADD CONSTRAINT search_documents_forum_id_fkey FOREIGN KEY (forum_id) REFERENCES public.forums(forum_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: search_documents search_documents_search_section_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.search_documents
    ADD CONSTRAINT search_documents_search_section_id_fkey FOREIGN KEY (search_section_id) REFERENCES public.search_sections(search_section_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: search_documents search_documents_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.search_documents
    ADD CONSTRAINT search_documents_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: search_sections search_sections_forum_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.search_sections
    ADD CONSTRAINT search_sections_forum_id_fkey FOREIGN KEY (forum_id) REFERENCES public.forums(forum_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: settings settings_forum_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settings
    ADD CONSTRAINT settings_forum_id_fkey FOREIGN KEY (forum_id) REFERENCES public.forums(forum_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: settings settings_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settings
    ADD CONSTRAINT settings_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: subscriptions subscriptions_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_message_id_fkey FOREIGN KEY (message_id) REFERENCES public.messages(message_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: subscriptions subscriptions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tag_synonyms tag_synonyms_forum_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tag_synonyms
    ADD CONSTRAINT tag_synonyms_forum_id_fkey FOREIGN KEY (forum_id) REFERENCES public.forums(forum_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tag_synonyms tag_synonyms_tag_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tag_synonyms
    ADD CONSTRAINT tag_synonyms_tag_id_fkey FOREIGN KEY (tag_id) REFERENCES public.tags(tag_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tags tags_forum_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT tags_forum_id_fkey FOREIGN KEY (forum_id) REFERENCES public.forums(forum_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: threads threads_forum_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.threads
    ADD CONSTRAINT threads_forum_id_fkey FOREIGN KEY (forum_id) REFERENCES public.forums(forum_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: threads threads_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.threads
    ADD CONSTRAINT threads_message_id_fkey FOREIGN KEY (message_id) REFERENCES public.messages(message_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: twitter_authorizations twitter_authorizations_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.twitter_authorizations
    ADD CONSTRAINT twitter_authorizations_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: votes votes_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.votes
    ADD CONSTRAINT votes_message_id_fkey FOREIGN KEY (message_id) REFERENCES public.messages(message_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: votes votes_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.votes
    ADD CONSTRAINT votes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('1'),
('10'),
('100'),
('101'),
('102'),
('103'),
('104'),
('105'),
('106'),
('107'),
('11'),
('12'),
('13'),
('14'),
('15'),
('16'),
('17'),
('18'),
('19'),
('2'),
('20'),
('20180426071152'),
('21'),
('22'),
('23'),
('24'),
('25'),
('26'),
('27'),
('28'),
('29'),
('3'),
('30'),
('31'),
('32'),
('33'),
('34'),
('35'),
('36'),
('37'),
('38'),
('39'),
('4'),
('40'),
('41'),
('42'),
('43'),
('44'),
('45'),
('46'),
('47'),
('48'),
('49'),
('5'),
('50'),
('51'),
('52'),
('53'),
('54'),
('55'),
('56'),
('57'),
('58'),
('59'),
('6'),
('60'),
('61'),
('62'),
('63'),
('64'),
('65'),
('66'),
('67'),
('68'),
('69'),
('7'),
('70'),
('71'),
('72'),
('73'),
('74'),
('75'),
('76'),
('77'),
('78'),
('79'),
('8'),
('80'),
('81'),
('82'),
('83'),
('84'),
('85'),
('86'),
('87'),
('88'),
('89'),
('9'),
('90'),
('91'),
('92'),
('93'),
('94'),
('95'),
('96'),
('97'),
('98'),
('99');


