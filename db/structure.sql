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


SET search_path = cforum, pg_catalog;

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
-- Name: message_flags; Type: TABLE; Schema: cforum; Owner: -; Tablespace: 
--

CREATE TABLE message_flags (
    message_id bigint,
    flag character varying(255) NOT NULL,
    value character varying(255),
    flag_id bigint NOT NULL
);


--
-- Name: message_flags_flag_id_seq; Type: SEQUENCE; Schema: cforum; Owner: -
--

CREATE SEQUENCE message_flags_flag_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: message_flags_flag_id_seq; Type: SEQUENCE OWNED BY; Schema: cforum; Owner: -
--

ALTER SEQUENCE message_flags_flag_id_seq OWNED BY message_flags.flag_id;


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
-- Name: forum_id; Type: DEFAULT; Schema: cforum; Owner: -
--

ALTER TABLE ONLY forums ALTER COLUMN forum_id SET DEFAULT nextval('forums_forum_id_seq'::regclass);


--
-- Name: flag_id; Type: DEFAULT; Schema: cforum; Owner: -
--

ALTER TABLE ONLY message_flags ALTER COLUMN flag_id SET DEFAULT nextval('message_flags_flag_id_seq'::regclass);


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
-- Name: forums_pkey; Type: CONSTRAINT; Schema: cforum; Owner: -; Tablespace: 
--

ALTER TABLE ONLY forums
    ADD CONSTRAINT forums_pkey PRIMARY KEY (forum_id);


--
-- Name: message_flags_pkey; Type: CONSTRAINT; Schema: cforum; Owner: -; Tablespace: 
--

ALTER TABLE ONLY message_flags
    ADD CONSTRAINT message_flags_pkey PRIMARY KEY (flag_id);


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
-- Name: message_id_fkey; Type: FK CONSTRAINT; Schema: cforum; Owner: -
--

ALTER TABLE ONLY message_flags
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

INSERT INTO schema_migrations (version) VALUES ('2');

INSERT INTO schema_migrations (version) VALUES ('3');

INSERT INTO schema_migrations (version) VALUES ('4');

INSERT INTO schema_migrations (version) VALUES ('5');

INSERT INTO schema_migrations (version) VALUES ('6');

INSERT INTO schema_migrations (version) VALUES ('7');

INSERT INTO schema_migrations (version) VALUES ('8');

INSERT INTO schema_migrations (version) VALUES ('9');