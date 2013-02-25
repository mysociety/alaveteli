--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
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


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: acts_as_xapian_jobs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE acts_as_xapian_jobs (
    id integer NOT NULL,
    model character varying(255) NOT NULL,
    model_id integer NOT NULL,
    action character varying(255) NOT NULL
);


--
-- Name: acts_as_xapian_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE acts_as_xapian_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: acts_as_xapian_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE acts_as_xapian_jobs_id_seq OWNED BY acts_as_xapian_jobs.id;


--
-- Name: censor_rules; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE censor_rules (
    id integer NOT NULL,
    info_request_id integer,
    user_id integer,
    public_body_id integer,
    text text NOT NULL,
    replacement text NOT NULL,
    last_edit_editor character varying(255) NOT NULL,
    last_edit_comment text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    regexp boolean
);


--
-- Name: censor_rules_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE censor_rules_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: censor_rules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE censor_rules_id_seq OWNED BY censor_rules.id;


--
-- Name: comments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE comments (
    id integer NOT NULL,
    user_id integer NOT NULL,
    comment_type character varying(255) DEFAULT 'internal_error'::character varying NOT NULL,
    info_request_id integer,
    body text NOT NULL,
    visible boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    locale text DEFAULT ''::text NOT NULL
);


--
-- Name: comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE comments_id_seq OWNED BY comments.id;


--
-- Name: mail_server_log_dones; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE mail_server_log_dones (
    id integer NOT NULL,
    filename text NOT NULL,
    last_stat timestamp without time zone NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: exim_log_dones_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE exim_log_dones_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: exim_log_dones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE exim_log_dones_id_seq OWNED BY mail_server_log_dones.id;


--
-- Name: mail_server_logs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE mail_server_logs (
    id integer NOT NULL,
    mail_server_log_done_id integer,
    info_request_id integer,
    "order" integer NOT NULL,
    line text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: exim_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE exim_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: exim_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE exim_logs_id_seq OWNED BY mail_server_logs.id;


--
-- Name: foi_attachments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE foi_attachments (
    id integer NOT NULL,
    content_type text,
    filename text,
    charset text,
    display_size text,
    url_part_number integer,
    within_rfc822_subject text,
    incoming_message_id integer,
    hexdigest character varying(32)
);


--
-- Name: foi_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE foi_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: foi_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE foi_attachments_id_seq OWNED BY foi_attachments.id;


--
-- Name: has_tag_string_tags; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE has_tag_string_tags (
    id integer NOT NULL,
    model_id integer NOT NULL,
    name text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    value text,
    model character varying(255) NOT NULL
);


--
-- Name: holidays; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE holidays (
    id integer NOT NULL,
    day date,
    description text
);


--
-- Name: holidays_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE holidays_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: holidays_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE holidays_id_seq OWNED BY holidays.id;


--
-- Name: incoming_messages; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE incoming_messages (
    id integer NOT NULL,
    info_request_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    raw_email_id integer NOT NULL,
    cached_attachment_text_clipped text,
    cached_main_body_text_folded text,
    cached_main_body_text_unfolded text,
    subject text,
    mail_from_domain text,
    valid_to_reply_to boolean,
    last_parsed timestamp without time zone,
    mail_from text,
    sent_at timestamp without time zone
);


--
-- Name: incoming_messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE incoming_messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: incoming_messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE incoming_messages_id_seq OWNED BY incoming_messages.id;


--
-- Name: info_request_events; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE info_request_events (
    id integer NOT NULL,
    info_request_id integer NOT NULL,
    event_type text NOT NULL,
    params_yaml text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    described_state character varying(255),
    calculated_state character varying(255) DEFAULT NULL::character varying,
    last_described_at timestamp without time zone,
    incoming_message_id integer,
    outgoing_message_id integer,
    comment_id integer,
    prominence character varying(255) DEFAULT 'normal'::character varying NOT NULL
);


--
-- Name: info_request_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE info_request_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: info_request_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE info_request_events_id_seq OWNED BY info_request_events.id;


--
-- Name: info_requests; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE info_requests (
    id integer NOT NULL,
    title text NOT NULL,
    user_id integer,
    public_body_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    described_state character varying(255) NOT NULL,
    awaiting_description boolean DEFAULT false NOT NULL,
    prominence character varying(255) DEFAULT 'normal'::character varying NOT NULL,
    url_title text NOT NULL,
    law_used character varying(255) DEFAULT 'foi'::character varying NOT NULL,
    allow_new_responses_from character varying(255) DEFAULT 'anybody'::character varying NOT NULL,
    handle_rejected_responses character varying(255) DEFAULT 'bounce'::character varying NOT NULL,
    idhash character varying(255) NOT NULL,
    external_user_name character varying(255),
    external_url character varying(255),
    attention_requested boolean DEFAULT false,
    comments_allowed boolean DEFAULT true NOT NULL,
    CONSTRAINT info_requests_external_ck CHECK ((((user_id IS NULL) = (external_url IS NOT NULL)) AND ((external_url IS NOT NULL) OR (external_user_name IS NULL))))
);


--
-- Name: info_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE info_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: info_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE info_requests_id_seq OWNED BY info_requests.id;


--
-- Name: outgoing_messages; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE outgoing_messages (
    id integer NOT NULL,
    info_request_id integer NOT NULL,
    body text NOT NULL,
    status character varying(255) NOT NULL,
    message_type character varying(255) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    last_sent_at timestamp without time zone,
    incoming_message_followup_id integer,
    what_doing character varying(255) NOT NULL
);


--
-- Name: outgoing_messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE outgoing_messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: outgoing_messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE outgoing_messages_id_seq OWNED BY outgoing_messages.id;


--
-- Name: post_redirects; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE post_redirects (
    id integer NOT NULL,
    token text NOT NULL,
    uri text NOT NULL,
    post_params_yaml text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    email_token text NOT NULL,
    reason_params_yaml text,
    user_id integer,
    circumstance text DEFAULT 'normal'::text NOT NULL
);


--
-- Name: post_redirects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE post_redirects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: post_redirects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE post_redirects_id_seq OWNED BY post_redirects.id;


--
-- Name: profile_photos; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE profile_photos (
    id integer NOT NULL,
    data bytea NOT NULL,
    user_id integer,
    draft boolean DEFAULT false NOT NULL
);


--
-- Name: profile_photos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE profile_photos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: profile_photos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE profile_photos_id_seq OWNED BY profile_photos.id;


--
-- Name: public_bodies; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE public_bodies (
    id integer NOT NULL,
    name text NOT NULL,
    short_name text NOT NULL,
    request_email text NOT NULL,
    version integer NOT NULL,
    last_edit_editor character varying(255) NOT NULL,
    last_edit_comment text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    url_name text NOT NULL,
    home_page text DEFAULT ''::text NOT NULL,
    notes text DEFAULT ''::text NOT NULL,
    first_letter character varying(255) NOT NULL,
    publication_scheme text DEFAULT ''::text NOT NULL,
    api_key character varying(255) NOT NULL,
    info_requests_count integer DEFAULT 0 NOT NULL,
    disclosure_log text DEFAULT ''::text NOT NULL
);


--
-- Name: public_bodies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public_bodies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: public_bodies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public_bodies_id_seq OWNED BY public_bodies.id;


--
-- Name: public_body_tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public_body_tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: public_body_tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public_body_tags_id_seq OWNED BY has_tag_string_tags.id;


--
-- Name: public_body_translations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE public_body_translations (
    id integer NOT NULL,
    public_body_id integer,
    locale character varying(255),
    short_name text,
    publication_scheme text,
    url_name text,
    first_letter character varying(255),
    notes text,
    name text,
    request_email text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    disclosure_log text
);


--
-- Name: public_body_translations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public_body_translations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: public_body_translations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public_body_translations_id_seq OWNED BY public_body_translations.id;


--
-- Name: public_body_versions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE public_body_versions (
    id integer NOT NULL,
    public_body_id integer,
    version integer,
    name text,
    short_name text,
    request_email text,
    updated_at timestamp without time zone,
    last_edit_editor character varying(255),
    last_edit_comment text,
    url_name text,
    home_page text,
    notes text,
    publication_scheme text DEFAULT ''::text NOT NULL,
    charity_number text DEFAULT ''::text NOT NULL,
    disclosure_log text DEFAULT ''::text NOT NULL
);


--
-- Name: public_body_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public_body_versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: public_body_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public_body_versions_id_seq OWNED BY public_body_versions.id;


--
-- Name: purge_requests; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE purge_requests (
    id integer NOT NULL,
    url character varying(255),
    created_at timestamp without time zone NOT NULL,
    model character varying(255) NOT NULL,
    model_id integer NOT NULL
);


--
-- Name: purge_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE purge_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: purge_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE purge_requests_id_seq OWNED BY purge_requests.id;


--
-- Name: raw_emails; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE raw_emails (
    id integer NOT NULL
);


--
-- Name: raw_emails_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE raw_emails_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: raw_emails_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE raw_emails_id_seq OWNED BY raw_emails.id;


--
-- Name: request_classifications; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE request_classifications (
    id integer NOT NULL,
    user_id integer,
    info_request_event_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: request_classifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE request_classifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: request_classifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE request_classifications_id_seq OWNED BY request_classifications.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: track_things; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE track_things (
    id integer NOT NULL,
    tracking_user_id integer NOT NULL,
    track_query character varying(255) NOT NULL,
    info_request_id integer,
    tracked_user_id integer,
    public_body_id integer,
    track_medium character varying(255) NOT NULL,
    track_type character varying(255) DEFAULT 'internal_error'::character varying NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: track_things_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE track_things_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: track_things_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE track_things_id_seq OWNED BY track_things.id;


--
-- Name: track_things_sent_emails; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE track_things_sent_emails (
    id integer NOT NULL,
    track_thing_id integer NOT NULL,
    info_request_event_id integer,
    user_id integer,
    public_body_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: track_things_sent_emails_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE track_things_sent_emails_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: track_things_sent_emails_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE track_things_sent_emails_id_seq OWNED BY track_things_sent_emails.id;


--
-- Name: user_info_request_sent_alerts; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE user_info_request_sent_alerts (
    id integer NOT NULL,
    user_id integer NOT NULL,
    info_request_id integer NOT NULL,
    alert_type character varying(255) NOT NULL,
    info_request_event_id integer
);


--
-- Name: user_info_request_sent_alerts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE user_info_request_sent_alerts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_info_request_sent_alerts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE user_info_request_sent_alerts_id_seq OWNED BY user_info_request_sent_alerts.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    id integer NOT NULL,
    email character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    hashed_password character varying(255) NOT NULL,
    salt character varying(255) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    email_confirmed boolean DEFAULT false NOT NULL,
    url_name text NOT NULL,
    last_daily_track_email timestamp without time zone DEFAULT '2000-01-01 00:00:00'::timestamp without time zone,
    admin_level character varying(255) DEFAULT 'none'::character varying NOT NULL,
    ban_text text DEFAULT ''::text NOT NULL,
    about_me text DEFAULT ''::text NOT NULL,
    locale character varying(255),
    email_bounced_at timestamp without time zone,
    email_bounce_message text DEFAULT ''::text NOT NULL,
    no_limit boolean DEFAULT false NOT NULL,
    receive_email_alerts boolean DEFAULT true NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY acts_as_xapian_jobs ALTER COLUMN id SET DEFAULT nextval('acts_as_xapian_jobs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY censor_rules ALTER COLUMN id SET DEFAULT nextval('censor_rules_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY comments ALTER COLUMN id SET DEFAULT nextval('comments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY foi_attachments ALTER COLUMN id SET DEFAULT nextval('foi_attachments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY has_tag_string_tags ALTER COLUMN id SET DEFAULT nextval('public_body_tags_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY holidays ALTER COLUMN id SET DEFAULT nextval('holidays_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY incoming_messages ALTER COLUMN id SET DEFAULT nextval('incoming_messages_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY info_request_events ALTER COLUMN id SET DEFAULT nextval('info_request_events_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY info_requests ALTER COLUMN id SET DEFAULT nextval('info_requests_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY mail_server_log_dones ALTER COLUMN id SET DEFAULT nextval('exim_log_dones_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY mail_server_logs ALTER COLUMN id SET DEFAULT nextval('exim_logs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY outgoing_messages ALTER COLUMN id SET DEFAULT nextval('outgoing_messages_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY post_redirects ALTER COLUMN id SET DEFAULT nextval('post_redirects_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY profile_photos ALTER COLUMN id SET DEFAULT nextval('profile_photos_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public_bodies ALTER COLUMN id SET DEFAULT nextval('public_bodies_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public_body_translations ALTER COLUMN id SET DEFAULT nextval('public_body_translations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public_body_versions ALTER COLUMN id SET DEFAULT nextval('public_body_versions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY purge_requests ALTER COLUMN id SET DEFAULT nextval('purge_requests_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY raw_emails ALTER COLUMN id SET DEFAULT nextval('raw_emails_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY request_classifications ALTER COLUMN id SET DEFAULT nextval('request_classifications_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY track_things ALTER COLUMN id SET DEFAULT nextval('track_things_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY track_things_sent_emails ALTER COLUMN id SET DEFAULT nextval('track_things_sent_emails_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_info_request_sent_alerts ALTER COLUMN id SET DEFAULT nextval('user_info_request_sent_alerts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: acts_as_xapian_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY acts_as_xapian_jobs
    ADD CONSTRAINT acts_as_xapian_jobs_pkey PRIMARY KEY (id);


--
-- Name: censor_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY censor_rules
    ADD CONSTRAINT censor_rules_pkey PRIMARY KEY (id);


--
-- Name: comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY comments
    ADD CONSTRAINT comments_pkey PRIMARY KEY (id);


--
-- Name: exim_log_dones_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY mail_server_log_dones
    ADD CONSTRAINT exim_log_dones_pkey PRIMARY KEY (id);


--
-- Name: exim_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY mail_server_logs
    ADD CONSTRAINT exim_logs_pkey PRIMARY KEY (id);


--
-- Name: foi_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY foi_attachments
    ADD CONSTRAINT foi_attachments_pkey PRIMARY KEY (id);


--
-- Name: holidays_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY holidays
    ADD CONSTRAINT holidays_pkey PRIMARY KEY (id);


--
-- Name: incoming_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY incoming_messages
    ADD CONSTRAINT incoming_messages_pkey PRIMARY KEY (id);


--
-- Name: info_request_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY info_request_events
    ADD CONSTRAINT info_request_events_pkey PRIMARY KEY (id);


--
-- Name: info_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY info_requests
    ADD CONSTRAINT info_requests_pkey PRIMARY KEY (id);


--
-- Name: outgoing_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY outgoing_messages
    ADD CONSTRAINT outgoing_messages_pkey PRIMARY KEY (id);


--
-- Name: post_redirects_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY post_redirects
    ADD CONSTRAINT post_redirects_pkey PRIMARY KEY (id);


--
-- Name: profile_photos_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY profile_photos
    ADD CONSTRAINT profile_photos_pkey PRIMARY KEY (id);


--
-- Name: public_bodies_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY public_bodies
    ADD CONSTRAINT public_bodies_pkey PRIMARY KEY (id);


--
-- Name: public_body_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY has_tag_string_tags
    ADD CONSTRAINT public_body_tags_pkey PRIMARY KEY (id);


--
-- Name: public_body_translations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY public_body_translations
    ADD CONSTRAINT public_body_translations_pkey PRIMARY KEY (id);


--
-- Name: public_body_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY public_body_versions
    ADD CONSTRAINT public_body_versions_pkey PRIMARY KEY (id);


--
-- Name: purge_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY purge_requests
    ADD CONSTRAINT purge_requests_pkey PRIMARY KEY (id);


--
-- Name: raw_emails_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY raw_emails
    ADD CONSTRAINT raw_emails_pkey PRIMARY KEY (id);


--
-- Name: request_classifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY request_classifications
    ADD CONSTRAINT request_classifications_pkey PRIMARY KEY (id);


--
-- Name: track_things_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY track_things
    ADD CONSTRAINT track_things_pkey PRIMARY KEY (id);


--
-- Name: track_things_sent_emails_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY track_things_sent_emails
    ADD CONSTRAINT track_things_sent_emails_pkey PRIMARY KEY (id);


--
-- Name: user_info_request_sent_alerts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY user_info_request_sent_alerts
    ADD CONSTRAINT user_info_request_sent_alerts_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: by_model_and_model_id_and_name_and_value; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX by_model_and_model_id_and_name_and_value ON has_tag_string_tags USING btree (model, model_id, name, value);


--
-- Name: index_acts_as_xapian_jobs_on_model_and_model_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_acts_as_xapian_jobs_on_model_and_model_id ON acts_as_xapian_jobs USING btree (model, model_id);


--
-- Name: index_censor_rules_on_info_request_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_censor_rules_on_info_request_id ON censor_rules USING btree (info_request_id);


--
-- Name: index_censor_rules_on_public_body_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_censor_rules_on_public_body_id ON censor_rules USING btree (public_body_id);


--
-- Name: index_censor_rules_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_censor_rules_on_user_id ON censor_rules USING btree (user_id);


--
-- Name: index_exim_log_dones_on_last_stat; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_exim_log_dones_on_last_stat ON mail_server_log_dones USING btree (last_stat);


--
-- Name: index_exim_logs_on_exim_log_done_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_exim_logs_on_exim_log_done_id ON mail_server_logs USING btree (mail_server_log_done_id);


--
-- Name: index_exim_logs_on_info_request_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_exim_logs_on_info_request_id ON mail_server_logs USING btree (info_request_id);


--
-- Name: index_foi_attachments_on_incoming_message_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_foi_attachments_on_incoming_message_id ON foi_attachments USING btree (incoming_message_id);


--
-- Name: index_has_tag_string_tags_on_model_and_model_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_has_tag_string_tags_on_model_and_model_id ON has_tag_string_tags USING btree (model, model_id);


--
-- Name: index_has_tag_string_tags_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_has_tag_string_tags_on_name ON has_tag_string_tags USING btree (name);


--
-- Name: index_holidays_on_day; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_holidays_on_day ON holidays USING btree (day);


--
-- Name: index_incoming_messages_on_info_request_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_incoming_messages_on_info_request_id ON incoming_messages USING btree (info_request_id);


--
-- Name: index_incoming_messages_on_raw_email_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_incoming_messages_on_raw_email_id ON incoming_messages USING btree (raw_email_id);


--
-- Name: index_info_request_events_on_comment_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_info_request_events_on_comment_id ON info_request_events USING btree (comment_id);


--
-- Name: index_info_request_events_on_created_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_info_request_events_on_created_at ON info_request_events USING btree (created_at);


--
-- Name: index_info_request_events_on_incoming_message_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_info_request_events_on_incoming_message_id ON info_request_events USING btree (incoming_message_id);


--
-- Name: index_info_request_events_on_info_request_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_info_request_events_on_info_request_id ON info_request_events USING btree (info_request_id);


--
-- Name: index_info_request_events_on_outgoing_message_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_info_request_events_on_outgoing_message_id ON info_request_events USING btree (outgoing_message_id);


--
-- Name: index_info_requests_on_created_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_info_requests_on_created_at ON info_requests USING btree (created_at);


--
-- Name: index_info_requests_on_public_body_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_info_requests_on_public_body_id ON info_requests USING btree (public_body_id);


--
-- Name: index_info_requests_on_title; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_info_requests_on_title ON info_requests USING btree (title);


--
-- Name: index_info_requests_on_url_title; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_info_requests_on_url_title ON info_requests USING btree (url_title);


--
-- Name: index_info_requests_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_info_requests_on_user_id ON info_requests USING btree (user_id);


--
-- Name: index_outgoing_messages_on_incoming_message_followup_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_outgoing_messages_on_incoming_message_followup_id ON outgoing_messages USING btree (incoming_message_followup_id);


--
-- Name: index_outgoing_messages_on_info_request_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_outgoing_messages_on_info_request_id ON outgoing_messages USING btree (info_request_id);


--
-- Name: index_outgoing_messages_on_what_doing; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_outgoing_messages_on_what_doing ON outgoing_messages USING btree (what_doing);


--
-- Name: index_post_redirects_on_email_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_post_redirects_on_email_token ON post_redirects USING btree (email_token);


--
-- Name: index_post_redirects_on_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_post_redirects_on_token ON post_redirects USING btree (token);


--
-- Name: index_post_redirects_on_updated_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_post_redirects_on_updated_at ON post_redirects USING btree (updated_at);


--
-- Name: index_post_redirects_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_post_redirects_on_user_id ON post_redirects USING btree (user_id);


--
-- Name: index_public_bodies_on_first_letter; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_public_bodies_on_first_letter ON public_bodies USING btree (first_letter);


--
-- Name: index_public_bodies_on_url_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_public_bodies_on_url_name ON public_bodies USING btree (url_name);


--
-- Name: index_public_body_translations_on_public_body_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_public_body_translations_on_public_body_id ON public_body_translations USING btree (public_body_id);


--
-- Name: index_public_body_versions_on_updated_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_public_body_versions_on_updated_at ON public_body_versions USING btree (updated_at);


--
-- Name: index_request_classifications_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_request_classifications_on_user_id ON request_classifications USING btree (user_id);


--
-- Name: index_track_things_on_tracking_user_id_and_track_query; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_track_things_on_tracking_user_id_and_track_query ON track_things USING btree (tracking_user_id, track_query);


--
-- Name: index_track_things_sent_emails_on_created_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_track_things_sent_emails_on_created_at ON track_things_sent_emails USING btree (created_at);


--
-- Name: index_track_things_sent_emails_on_info_request_event_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_track_things_sent_emails_on_info_request_event_id ON track_things_sent_emails USING btree (info_request_event_id);


--
-- Name: index_track_things_sent_emails_on_track_thing_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_track_things_sent_emails_on_track_thing_id ON track_things_sent_emails USING btree (track_thing_id);


--
-- Name: index_user_info_request_sent_alerts_on_info_request_event_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_user_info_request_sent_alerts_on_info_request_event_id ON user_info_request_sent_alerts USING btree (info_request_event_id);


--
-- Name: index_users_on_url_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_url_name ON users USING btree (url_name);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: user_info_request_sent_alerts_unique_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX user_info_request_sent_alerts_unique_index ON user_info_request_sent_alerts USING btree (user_id, info_request_id, alert_type, (COALESCE(info_request_event_id, (-1))));


--
-- Name: users_email_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX users_email_index ON users USING btree (lower((email)::text));


--
-- Name: users_lower_email_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX users_lower_email_index ON users USING btree (lower((email)::text));


--
-- Name: fk_censor_rules_info_request; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY censor_rules
    ADD CONSTRAINT fk_censor_rules_info_request FOREIGN KEY (info_request_id) REFERENCES info_requests(id);


--
-- Name: fk_censor_rules_public_body; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY censor_rules
    ADD CONSTRAINT fk_censor_rules_public_body FOREIGN KEY (public_body_id) REFERENCES public_bodies(id);


--
-- Name: fk_censor_rules_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY censor_rules
    ADD CONSTRAINT fk_censor_rules_user FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_comments_info_request; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY comments
    ADD CONSTRAINT fk_comments_info_request FOREIGN KEY (info_request_id) REFERENCES info_requests(id);


--
-- Name: fk_comments_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY comments
    ADD CONSTRAINT fk_comments_user FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_exim_log_done; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mail_server_logs
    ADD CONSTRAINT fk_exim_log_done FOREIGN KEY (mail_server_log_done_id) REFERENCES mail_server_log_dones(id);


--
-- Name: fk_exim_log_info_request; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mail_server_logs
    ADD CONSTRAINT fk_exim_log_info_request FOREIGN KEY (info_request_id) REFERENCES info_requests(id);


--
-- Name: fk_incoming_message_followup_info_request; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY outgoing_messages
    ADD CONSTRAINT fk_incoming_message_followup_info_request FOREIGN KEY (incoming_message_followup_id) REFERENCES incoming_messages(id);


--
-- Name: fk_incoming_messages_info_request; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY incoming_messages
    ADD CONSTRAINT fk_incoming_messages_info_request FOREIGN KEY (info_request_id) REFERENCES info_requests(id);


--
-- Name: fk_incoming_messages_raw_email; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY incoming_messages
    ADD CONSTRAINT fk_incoming_messages_raw_email FOREIGN KEY (raw_email_id) REFERENCES raw_emails(id);


--
-- Name: fk_info_request_events_comment_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY info_request_events
    ADD CONSTRAINT fk_info_request_events_comment_id FOREIGN KEY (comment_id) REFERENCES comments(id);


--
-- Name: fk_info_request_events_incoming_message_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY info_request_events
    ADD CONSTRAINT fk_info_request_events_incoming_message_id FOREIGN KEY (incoming_message_id) REFERENCES incoming_messages(id);


--
-- Name: fk_info_request_events_info_request; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY info_request_events
    ADD CONSTRAINT fk_info_request_events_info_request FOREIGN KEY (info_request_id) REFERENCES info_requests(id);


--
-- Name: fk_info_request_events_outgoing_message_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY info_request_events
    ADD CONSTRAINT fk_info_request_events_outgoing_message_id FOREIGN KEY (outgoing_message_id) REFERENCES outgoing_messages(id);


--
-- Name: fk_info_request_sent_alerts_info_request; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_info_request_sent_alerts
    ADD CONSTRAINT fk_info_request_sent_alerts_info_request FOREIGN KEY (info_request_id) REFERENCES info_requests(id);


--
-- Name: fk_info_request_sent_alerts_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_info_request_sent_alerts
    ADD CONSTRAINT fk_info_request_sent_alerts_user FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_info_requests_public_body; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY info_requests
    ADD CONSTRAINT fk_info_requests_public_body FOREIGN KEY (public_body_id) REFERENCES public_bodies(id);


--
-- Name: fk_info_requests_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY info_requests
    ADD CONSTRAINT fk_info_requests_user FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_outgoing_messages_info_request; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY outgoing_messages
    ADD CONSTRAINT fk_outgoing_messages_info_request FOREIGN KEY (info_request_id) REFERENCES info_requests(id);


--
-- Name: fk_post_redirects_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY post_redirects
    ADD CONSTRAINT fk_post_redirects_user FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_profile_photos_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY profile_photos
    ADD CONSTRAINT fk_profile_photos_user FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_public_body_versions_public_body; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public_body_versions
    ADD CONSTRAINT fk_public_body_versions_public_body FOREIGN KEY (public_body_id) REFERENCES public_bodies(id);


--
-- Name: fk_track_request_info_request; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY track_things
    ADD CONSTRAINT fk_track_request_info_request FOREIGN KEY (info_request_id) REFERENCES info_requests(id);


--
-- Name: fk_track_request_info_request_event; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY track_things_sent_emails
    ADD CONSTRAINT fk_track_request_info_request_event FOREIGN KEY (info_request_event_id) REFERENCES info_request_events(id);


--
-- Name: fk_track_request_public_body; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY track_things
    ADD CONSTRAINT fk_track_request_public_body FOREIGN KEY (public_body_id) REFERENCES public_bodies(id);


--
-- Name: fk_track_request_public_body; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY track_things_sent_emails
    ADD CONSTRAINT fk_track_request_public_body FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_track_request_tracked_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY track_things
    ADD CONSTRAINT fk_track_request_tracked_user FOREIGN KEY (tracked_user_id) REFERENCES users(id);


--
-- Name: fk_track_request_tracking_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY track_things
    ADD CONSTRAINT fk_track_request_tracking_user FOREIGN KEY (tracking_user_id) REFERENCES users(id);


--
-- Name: fk_track_request_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY track_things_sent_emails
    ADD CONSTRAINT fk_track_request_user FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_user_info_request_sent_alert_info_request_event; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_info_request_sent_alerts
    ADD CONSTRAINT fk_user_info_request_sent_alert_info_request_event FOREIGN KEY (info_request_event_id) REFERENCES info_request_events(id);


--
-- PostgreSQL database dump complete
--

INSERT INTO schema_migrations (version) VALUES ('1');

INSERT INTO schema_migrations (version) VALUES ('2');

INSERT INTO schema_migrations (version) VALUES ('4');

INSERT INTO schema_migrations (version) VALUES ('5');

INSERT INTO schema_migrations (version) VALUES ('6');

INSERT INTO schema_migrations (version) VALUES ('7');

INSERT INTO schema_migrations (version) VALUES ('8');

INSERT INTO schema_migrations (version) VALUES ('9');

INSERT INTO schema_migrations (version) VALUES ('10');

INSERT INTO schema_migrations (version) VALUES ('11');

INSERT INTO schema_migrations (version) VALUES ('12');

INSERT INTO schema_migrations (version) VALUES ('13');

INSERT INTO schema_migrations (version) VALUES ('14');

INSERT INTO schema_migrations (version) VALUES ('15');

INSERT INTO schema_migrations (version) VALUES ('16');

INSERT INTO schema_migrations (version) VALUES ('17');

INSERT INTO schema_migrations (version) VALUES ('18');

INSERT INTO schema_migrations (version) VALUES ('21');

INSERT INTO schema_migrations (version) VALUES ('22');

INSERT INTO schema_migrations (version) VALUES ('23');

INSERT INTO schema_migrations (version) VALUES ('24');

INSERT INTO schema_migrations (version) VALUES ('25');

INSERT INTO schema_migrations (version) VALUES ('26');

INSERT INTO schema_migrations (version) VALUES ('27');

INSERT INTO schema_migrations (version) VALUES ('28');

INSERT INTO schema_migrations (version) VALUES ('29');

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

INSERT INTO schema_migrations (version) VALUES ('80');

INSERT INTO schema_migrations (version) VALUES ('81');

INSERT INTO schema_migrations (version) VALUES ('82');

INSERT INTO schema_migrations (version) VALUES ('83');

INSERT INTO schema_migrations (version) VALUES ('84');

INSERT INTO schema_migrations (version) VALUES ('85');

INSERT INTO schema_migrations (version) VALUES ('86');

INSERT INTO schema_migrations (version) VALUES ('87');

INSERT INTO schema_migrations (version) VALUES ('88');

INSERT INTO schema_migrations (version) VALUES ('89');

INSERT INTO schema_migrations (version) VALUES ('90');

INSERT INTO schema_migrations (version) VALUES ('91');

INSERT INTO schema_migrations (version) VALUES ('92');

INSERT INTO schema_migrations (version) VALUES ('93');

INSERT INTO schema_migrations (version) VALUES ('94');

INSERT INTO schema_migrations (version) VALUES ('95');

INSERT INTO schema_migrations (version) VALUES ('96');

INSERT INTO schema_migrations (version) VALUES ('97');

INSERT INTO schema_migrations (version) VALUES ('98');

INSERT INTO schema_migrations (version) VALUES ('99');

INSERT INTO schema_migrations (version) VALUES ('100');

INSERT INTO schema_migrations (version) VALUES ('101');

INSERT INTO schema_migrations (version) VALUES ('102');

INSERT INTO schema_migrations (version) VALUES ('103');

INSERT INTO schema_migrations (version) VALUES ('104');

INSERT INTO schema_migrations (version) VALUES ('105');

INSERT INTO schema_migrations (version) VALUES ('106');

INSERT INTO schema_migrations (version) VALUES ('107');

INSERT INTO schema_migrations (version) VALUES ('108');

INSERT INTO schema_migrations (version) VALUES ('109');

INSERT INTO schema_migrations (version) VALUES ('110');

INSERT INTO schema_migrations (version) VALUES ('111');

INSERT INTO schema_migrations (version) VALUES ('112');

INSERT INTO schema_migrations (version) VALUES ('113');

INSERT INTO schema_migrations (version) VALUES ('114');

INSERT INTO schema_migrations (version) VALUES ('115');

INSERT INTO schema_migrations (version) VALUES ('116');

INSERT INTO schema_migrations (version) VALUES ('117');

INSERT INTO schema_migrations (version) VALUES ('118');

INSERT INTO schema_migrations (version) VALUES ('20120822145640');

INSERT INTO schema_migrations (version) VALUES ('20120910153022');

INSERT INTO schema_migrations (version) VALUES ('20120912111713');

INSERT INTO schema_migrations (version) VALUES ('20120912112036');

INSERT INTO schema_migrations (version) VALUES ('20120912112312');

INSERT INTO schema_migrations (version) VALUES ('20120912112655');

INSERT INTO schema_migrations (version) VALUES ('20120912113004');

INSERT INTO schema_migrations (version) VALUES ('20120912113720');

INSERT INTO schema_migrations (version) VALUES ('20120912114022');

INSERT INTO schema_migrations (version) VALUES ('20120912170035');

INSERT INTO schema_migrations (version) VALUES ('20120913074940');

INSERT INTO schema_migrations (version) VALUES ('20120913080807');

INSERT INTO schema_migrations (version) VALUES ('20120913081136');

INSERT INTO schema_migrations (version) VALUES ('20120913135745');

INSERT INTO schema_migrations (version) VALUES ('20120919140404');

INSERT INTO schema_migrations (version) VALUES ('20121010214348');

INSERT INTO schema_migrations (version) VALUES ('20121022031914');