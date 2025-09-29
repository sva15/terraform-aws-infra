--
-- PostgreSQL database dump
--

\restrict s0CNfHgieVGhBXfQdKRu4ZM6BEbr6CKcp6fLXeceapQeAemjyniTDw73VckOwID

-- Dumped from database version 15.14 (Debian 15.14-1.pgdg13+1)
-- Dumped by pg_dump version 15.14 (Debian 15.14-1.pgdg13+1)

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

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: companies; Type: TABLE; Schema: public; Owner: ifrs_user
--

CREATE TABLE public.companies (
    id integer NOT NULL,
    company_name character varying(255) NOT NULL,
    industry character varying(100),
    country character varying(100),
    revenue numeric(15,2),
    established_year integer
);


ALTER TABLE public.companies OWNER TO ifrs_user;

--
-- Name: companies_id_seq; Type: SEQUENCE; Schema: public; Owner: ifrs_user
--

CREATE SEQUENCE public.companies_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.companies_id_seq OWNER TO ifrs_user;

--
-- Name: companies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ifrs_user
--

ALTER SEQUENCE public.companies_id_seq OWNED BY public.companies.id;


--
-- Name: financial_instruments; Type: TABLE; Schema: public; Owner: ifrs_user
--

CREATE TABLE public.financial_instruments (
    id integer NOT NULL,
    instrument_name character varying(255) NOT NULL,
    instrument_type character varying(100) NOT NULL,
    value numeric(15,2),
    acquisition_date date,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.financial_instruments OWNER TO ifrs_user;

--
-- Name: financial_instruments_id_seq; Type: SEQUENCE; Schema: public; Owner: ifrs_user
--

CREATE SEQUENCE public.financial_instruments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.financial_instruments_id_seq OWNER TO ifrs_user;

--
-- Name: financial_instruments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ifrs_user
--

ALTER SEQUENCE public.financial_instruments_id_seq OWNED BY public.financial_instruments.id;


--
-- Name: companies id; Type: DEFAULT; Schema: public; Owner: ifrs_user
--

ALTER TABLE ONLY public.companies ALTER COLUMN id SET DEFAULT nextval('public.companies_id_seq'::regclass);


--
-- Name: financial_instruments id; Type: DEFAULT; Schema: public; Owner: ifrs_user
--

ALTER TABLE ONLY public.financial_instruments ALTER COLUMN id SET DEFAULT nextval('public.financial_instruments_id_seq'::regclass);


--
-- Data for Name: companies; Type: TABLE DATA; Schema: public; Owner: ifrs_user
--

COPY public.companies (id, company_name, industry, country, revenue, established_year) FROM stdin;
1	Global Tech Inc	Technology	USA	5000000.00	2005
2	Euro Manufacturing	Industrial	Germany	3200000.00	1998
3	Asia Finance Group	Financial Services	Japan	7500000.00	1985
4	Energy Solutions Ltd	Energy	UK	4200000.00	2000
5	Pharma Innovations	Healthcare	Switzerland	6800000.00	1990
\.


--
-- Data for Name: financial_instruments; Type: TABLE DATA; Schema: public; Owner: ifrs_user
--

COPY public.financial_instruments (id, instrument_name, instrument_type, value, acquisition_date, created_at) FROM stdin;
1	Corporate Bond A	Bond	50000.00	2024-01-15	2025-09-28 14:38:16.382656
2	Government Bond B	Bond	75000.00	2024-02-20	2025-09-28 14:38:16.382656
3	Equity Stock X	Equity	120000.00	2024-01-10	2025-09-28 14:38:16.382656
4	Derivative Contract Y	Derivative	35000.00	2024-03-05	2025-09-28 14:38:16.382656
5	Treasury Bill Z	T-Bill	25000.00	2024-02-28	2025-09-28 14:38:16.382656
\.


--
-- Name: companies_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ifrs_user
--

SELECT pg_catalog.setval('public.companies_id_seq', 5, true);


--
-- Name: financial_instruments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ifrs_user
--

SELECT pg_catalog.setval('public.financial_instruments_id_seq', 5, true);


--
-- Name: companies companies_pkey; Type: CONSTRAINT; Schema: public; Owner: ifrs_user
--

ALTER TABLE ONLY public.companies
    ADD CONSTRAINT companies_pkey PRIMARY KEY (id);


--
-- Name: financial_instruments financial_instruments_pkey; Type: CONSTRAINT; Schema: public; Owner: ifrs_user
--

ALTER TABLE ONLY public.financial_instruments
    ADD CONSTRAINT financial_instruments_pkey PRIMARY KEY (id);


--
-- Name: idx_company_industry; Type: INDEX; Schema: public; Owner: ifrs_user
--

CREATE INDEX idx_company_industry ON public.companies USING btree (industry);


--
-- Name: idx_instrument_type; Type: INDEX; Schema: public; Owner: ifrs_user
--

CREATE INDEX idx_instrument_type ON public.financial_instruments USING btree (instrument_type);


--
-- PostgreSQL database dump complete
--

\unrestrict s0CNfHgieVGhBXfQdKRu4ZM6BEbr6CKcp6fLXeceapQeAemjyniTDw73VckOwID

