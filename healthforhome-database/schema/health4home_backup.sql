--
-- PostgreSQL database dump
--

-- Dumped from database version 17.5
-- Dumped by pg_dump version 17.5

-- Started on 2025-12-03 11:53:12

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
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
-- TOC entry 229 (class 1259 OID 107305)
-- Name: admins; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.admins (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    email character varying(255) NOT NULL,
    password_hash character varying(255) NOT NULL,
    role character varying(20) DEFAULT 'support'::character varying,
    full_name character varying(200),
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_login_at timestamp without time zone,
    CONSTRAINT admins_role_check CHECK (((role)::text = ANY ((ARRAY['super_admin'::character varying, 'support'::character varying, 'verifier'::character varying])::text[])))
);


ALTER TABLE public.admins OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 107213)
-- Name: appointments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.appointments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    client_id uuid,
    specialist_id uuid,
    specialist_service_id uuid,
    appointment_status character varying(20) DEFAULT 'pending'::character varying,
    scheduled_start timestamp without time zone NOT NULL,
    scheduled_end timestamp without time zone NOT NULL,
    total_price numeric(10,2),
    client_address text,
    client_notes text,
    specialist_notes text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    cancelled_at timestamp without time zone,
    CONSTRAINT appointments_appointment_status_check CHECK (((appointment_status)::text = ANY ((ARRAY['pending'::character varying, 'confirmed'::character varying, 'in_progress'::character varying, 'completed'::character varying, 'cancelled'::character varying, 'no_show'::character varying])::text[])))
);


ALTER TABLE public.appointments OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 107198)
-- Name: booked_slots; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.booked_slots (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    specialist_id uuid,
    start_datetime timestamp without time zone NOT NULL,
    end_datetime timestamp without time zone NOT NULL,
    is_blocked boolean DEFAULT true,
    notes text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.booked_slots OWNER TO postgres;

--
-- TOC entry 218 (class 1259 OID 107090)
-- Name: clients; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.clients (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    first_name character varying(100) NOT NULL,
    last_name character varying(100) NOT NULL,
    date_of_birth date,
    address text,
    emergency_contact text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.clients OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 107285)
-- Name: payments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.payments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    appointment_id uuid,
    payment_method character varying(10) DEFAULT 'cash'::character varying,
    payment_status character varying(20) DEFAULT 'pending'::character varying,
    cash_received boolean DEFAULT false,
    received_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT payments_payment_method_check CHECK (((payment_method)::text = 'cash'::text)),
    CONSTRAINT payments_payment_status_check CHECK (((payment_status)::text = ANY ((ARRAY['pending'::character varying, 'completed'::character varying, 'cancelled'::character varying, 'no_show'::character varying])::text[])))
);


ALTER TABLE public.payments OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 107240)
-- Name: reviews; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reviews (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    appointment_id uuid,
    client_id uuid,
    specialist_id uuid,
    rating integer NOT NULL,
    comment text,
    is_verified boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT reviews_rating_check CHECK (((rating >= 1) AND (rating <= 5)))
);


ALTER TABLE public.reviews OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 107170)
-- Name: service_areas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.service_areas (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    specialist_id uuid,
    city character varying(100) NOT NULL,
    postal_code character varying(10),
    max_distance_km integer DEFAULT 20,
    is_primary boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.service_areas OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 107140)
-- Name: service_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.service_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(100) NOT NULL,
    category character varying(50) NOT NULL,
    default_duration integer,
    description text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT service_types_category_check CHECK (((category)::text = ANY ((ARRAY['nursing'::character varying, 'physiotherapy'::character varying])::text[])))
);


ALTER TABLE public.service_types OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 107184)
-- Name: specialist_availability; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.specialist_availability (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    specialist_id uuid,
    date date NOT NULL,
    start_time time without time zone NOT NULL,
    end_time time without time zone NOT NULL,
    is_available boolean DEFAULT true,
    recurrence_pattern character varying(20),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT specialist_availability_recurrence_pattern_check CHECK (((recurrence_pattern)::text = ANY ((ARRAY['once'::character varying, 'daily'::character varying, 'weekly'::character varying, 'monthly'::character varying])::text[])))
);


ALTER TABLE public.specialist_availability OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 107267)
-- Name: specialist_qualifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.specialist_qualifications (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    specialist_id uuid,
    profession character varying(50) NOT NULL,
    license_number character varying(100) NOT NULL,
    license_photo_url text,
    id_card_photo_url text,
    verification_notes text,
    verified_by_admin_id uuid,
    verified_at timestamp without time zone,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT specialist_qualifications_profession_check CHECK (((profession)::text = ANY ((ARRAY['nurse'::character varying, 'physiotherapist'::character varying])::text[])))
);


ALTER TABLE public.specialist_qualifications OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 107150)
-- Name: specialist_services; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.specialist_services (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    specialist_id uuid,
    service_type_id uuid,
    duration_minutes integer NOT NULL,
    price numeric(10,2) NOT NULL,
    description text,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.specialist_services OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 107121)
-- Name: specialists; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.specialists (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    first_name character varying(100) NOT NULL,
    last_name character varying(100) NOT NULL,
    professional_title character varying(200),
    bio text,
    hourly_rate numeric(10,2),
    is_verified boolean DEFAULT false,
    verification_status character varying(20) DEFAULT 'pending'::character varying,
    average_rating numeric(3,2) DEFAULT 0.00,
    total_reviews integer DEFAULT 0,
    verified_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT specialists_verification_status_check CHECK (((verification_status)::text = ANY ((ARRAY['pending'::character varying, 'approved'::character varying, 'rejected'::character varying, 'needs_revision'::character varying])::text[])))
);


ALTER TABLE public.specialists OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 107076)
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    email character varying(255) NOT NULL,
    password_hash character varying(255) NOT NULL,
    user_type character varying(20) NOT NULL,
    phone_number character varying(20),
    avatar_url text,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_login_at timestamp without time zone,
    CONSTRAINT users_user_type_check CHECK (((user_type)::text = ANY ((ARRAY['client'::character varying, 'specialist'::character varying])::text[])))
);


ALTER TABLE public.users OWNER TO postgres;

--
-- TOC entry 230 (class 1259 OID 107319)
-- Name: verification_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.verification_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    specialist_id uuid,
    admin_id uuid,
    action character varying(50) NOT NULL,
    notes text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT verification_logs_action_check CHECK (((action)::text = ANY ((ARRAY['submitted'::character varying, 'approved'::character varying, 'rejected'::character varying, 'requested_changes'::character varying])::text[])))
);


ALTER TABLE public.verification_logs OWNER TO postgres;

--
-- TOC entry 4964 (class 0 OID 107305)
-- Dependencies: 229
-- Data for Name: admins; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.admins (id, email, password_hash, role, full_name, is_active, created_at, last_login_at) FROM stdin;
\.


--
-- TOC entry 4960 (class 0 OID 107213)
-- Dependencies: 225
-- Data for Name: appointments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.appointments (id, client_id, specialist_id, specialist_service_id, appointment_status, scheduled_start, scheduled_end, total_price, client_address, client_notes, specialist_notes, created_at, updated_at, cancelled_at) FROM stdin;
\.


--
-- TOC entry 4959 (class 0 OID 107198)
-- Dependencies: 224
-- Data for Name: booked_slots; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.booked_slots (id, specialist_id, start_datetime, end_datetime, is_blocked, notes, created_at) FROM stdin;
\.


--
-- TOC entry 4953 (class 0 OID 107090)
-- Dependencies: 218
-- Data for Name: clients; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.clients (id, user_id, first_name, last_name, date_of_birth, address, emergency_contact, created_at) FROM stdin;
\.


--
-- TOC entry 4963 (class 0 OID 107285)
-- Dependencies: 228
-- Data for Name: payments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.payments (id, appointment_id, payment_method, payment_status, cash_received, received_at, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 4961 (class 0 OID 107240)
-- Dependencies: 226
-- Data for Name: reviews; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.reviews (id, appointment_id, client_id, specialist_id, rating, comment, is_verified, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 4957 (class 0 OID 107170)
-- Dependencies: 222
-- Data for Name: service_areas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.service_areas (id, specialist_id, city, postal_code, max_distance_km, is_primary, created_at) FROM stdin;
\.


--
-- TOC entry 4955 (class 0 OID 107140)
-- Dependencies: 220
-- Data for Name: service_types; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.service_types (id, name, category, default_duration, description, created_at) FROM stdin;
\.


--
-- TOC entry 4958 (class 0 OID 107184)
-- Dependencies: 223
-- Data for Name: specialist_availability; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.specialist_availability (id, specialist_id, date, start_time, end_time, is_available, recurrence_pattern, created_at) FROM stdin;
\.


--
-- TOC entry 4962 (class 0 OID 107267)
-- Dependencies: 227
-- Data for Name: specialist_qualifications; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.specialist_qualifications (id, specialist_id, profession, license_number, license_photo_url, id_card_photo_url, verification_notes, verified_by_admin_id, verified_at, is_active, created_at) FROM stdin;
\.


--
-- TOC entry 4956 (class 0 OID 107150)
-- Dependencies: 221
-- Data for Name: specialist_services; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.specialist_services (id, specialist_id, service_type_id, duration_minutes, price, description, is_active, created_at) FROM stdin;
\.


--
-- TOC entry 4954 (class 0 OID 107121)
-- Dependencies: 219
-- Data for Name: specialists; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.specialists (id, user_id, first_name, last_name, professional_title, bio, hourly_rate, is_verified, verification_status, average_rating, total_reviews, verified_at, created_at) FROM stdin;
\.


--
-- TOC entry 4952 (class 0 OID 107076)
-- Dependencies: 217
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, email, password_hash, user_type, phone_number, avatar_url, is_active, created_at, updated_at, last_login_at) FROM stdin;
\.


--
-- TOC entry 4965 (class 0 OID 107319)
-- Dependencies: 230
-- Data for Name: verification_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.verification_logs (id, specialist_id, admin_id, action, notes, created_at) FROM stdin;
\.


--
-- TOC entry 4784 (class 2606 OID 107318)
-- Name: admins admins_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admins
    ADD CONSTRAINT admins_email_key UNIQUE (email);


--
-- TOC entry 4786 (class 2606 OID 107316)
-- Name: admins admins_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admins
    ADD CONSTRAINT admins_pkey PRIMARY KEY (id);


--
-- TOC entry 4772 (class 2606 OID 107224)
-- Name: appointments appointments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.appointments
    ADD CONSTRAINT appointments_pkey PRIMARY KEY (id);


--
-- TOC entry 4770 (class 2606 OID 107207)
-- Name: booked_slots booked_slots_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.booked_slots
    ADD CONSTRAINT booked_slots_pkey PRIMARY KEY (id);


--
-- TOC entry 4758 (class 2606 OID 107098)
-- Name: clients clients_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT clients_pkey PRIMARY KEY (id);


--
-- TOC entry 4780 (class 2606 OID 107299)
-- Name: payments payments_appointment_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_appointment_id_key UNIQUE (appointment_id);


--
-- TOC entry 4782 (class 2606 OID 107297)
-- Name: payments payments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (id);


--
-- TOC entry 4774 (class 2606 OID 107251)
-- Name: reviews reviews_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_pkey PRIMARY KEY (id);


--
-- TOC entry 4766 (class 2606 OID 107178)
-- Name: service_areas service_areas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.service_areas
    ADD CONSTRAINT service_areas_pkey PRIMARY KEY (id);


--
-- TOC entry 4762 (class 2606 OID 107149)
-- Name: service_types service_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.service_types
    ADD CONSTRAINT service_types_pkey PRIMARY KEY (id);


--
-- TOC entry 4768 (class 2606 OID 107192)
-- Name: specialist_availability specialist_availability_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.specialist_availability
    ADD CONSTRAINT specialist_availability_pkey PRIMARY KEY (id);


--
-- TOC entry 4778 (class 2606 OID 107277)
-- Name: specialist_qualifications specialist_qualifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.specialist_qualifications
    ADD CONSTRAINT specialist_qualifications_pkey PRIMARY KEY (id);


--
-- TOC entry 4764 (class 2606 OID 107159)
-- Name: specialist_services specialist_services_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.specialist_services
    ADD CONSTRAINT specialist_services_pkey PRIMARY KEY (id);


--
-- TOC entry 4760 (class 2606 OID 107134)
-- Name: specialists specialists_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.specialists
    ADD CONSTRAINT specialists_pkey PRIMARY KEY (id);


--
-- TOC entry 4776 (class 2606 OID 107345)
-- Name: reviews unique_appointment_review; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT unique_appointment_review UNIQUE (appointment_id);


--
-- TOC entry 4754 (class 2606 OID 107089)
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- TOC entry 4756 (class 2606 OID 107087)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- TOC entry 4788 (class 2606 OID 107328)
-- Name: verification_logs verification_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.verification_logs
    ADD CONSTRAINT verification_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 4796 (class 2606 OID 107225)
-- Name: appointments appointments_client_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.appointments
    ADD CONSTRAINT appointments_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.clients(id) ON DELETE CASCADE;


--
-- TOC entry 4797 (class 2606 OID 107230)
-- Name: appointments appointments_specialist_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.appointments
    ADD CONSTRAINT appointments_specialist_id_fkey FOREIGN KEY (specialist_id) REFERENCES public.specialists(id) ON DELETE CASCADE;


--
-- TOC entry 4798 (class 2606 OID 107235)
-- Name: appointments appointments_specialist_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.appointments
    ADD CONSTRAINT appointments_specialist_service_id_fkey FOREIGN KEY (specialist_service_id) REFERENCES public.specialist_services(id);


--
-- TOC entry 4795 (class 2606 OID 107208)
-- Name: booked_slots booked_slots_specialist_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.booked_slots
    ADD CONSTRAINT booked_slots_specialist_id_fkey FOREIGN KEY (specialist_id) REFERENCES public.specialists(id) ON DELETE CASCADE;


--
-- TOC entry 4789 (class 2606 OID 107099)
-- Name: clients clients_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT clients_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 4802 (class 2606 OID 107339)
-- Name: specialist_qualifications fk_verified_by_admin; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.specialist_qualifications
    ADD CONSTRAINT fk_verified_by_admin FOREIGN KEY (verified_by_admin_id) REFERENCES public.admins(id) ON DELETE SET NULL;


--
-- TOC entry 4804 (class 2606 OID 107300)
-- Name: payments payments_appointment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_appointment_id_fkey FOREIGN KEY (appointment_id) REFERENCES public.appointments(id) ON DELETE CASCADE;


--
-- TOC entry 4799 (class 2606 OID 107252)
-- Name: reviews reviews_appointment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_appointment_id_fkey FOREIGN KEY (appointment_id) REFERENCES public.appointments(id) ON DELETE CASCADE;


--
-- TOC entry 4800 (class 2606 OID 107257)
-- Name: reviews reviews_client_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.clients(id) ON DELETE CASCADE;


--
-- TOC entry 4801 (class 2606 OID 107262)
-- Name: reviews reviews_specialist_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_specialist_id_fkey FOREIGN KEY (specialist_id) REFERENCES public.specialists(id) ON DELETE CASCADE;


--
-- TOC entry 4793 (class 2606 OID 107179)
-- Name: service_areas service_areas_specialist_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.service_areas
    ADD CONSTRAINT service_areas_specialist_id_fkey FOREIGN KEY (specialist_id) REFERENCES public.specialists(id) ON DELETE CASCADE;


--
-- TOC entry 4794 (class 2606 OID 107193)
-- Name: specialist_availability specialist_availability_specialist_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.specialist_availability
    ADD CONSTRAINT specialist_availability_specialist_id_fkey FOREIGN KEY (specialist_id) REFERENCES public.specialists(id) ON DELETE CASCADE;


--
-- TOC entry 4803 (class 2606 OID 107278)
-- Name: specialist_qualifications specialist_qualifications_specialist_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.specialist_qualifications
    ADD CONSTRAINT specialist_qualifications_specialist_id_fkey FOREIGN KEY (specialist_id) REFERENCES public.specialists(id) ON DELETE CASCADE;


--
-- TOC entry 4791 (class 2606 OID 107165)
-- Name: specialist_services specialist_services_service_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.specialist_services
    ADD CONSTRAINT specialist_services_service_type_id_fkey FOREIGN KEY (service_type_id) REFERENCES public.service_types(id) ON DELETE CASCADE;


--
-- TOC entry 4792 (class 2606 OID 107160)
-- Name: specialist_services specialist_services_specialist_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.specialist_services
    ADD CONSTRAINT specialist_services_specialist_id_fkey FOREIGN KEY (specialist_id) REFERENCES public.specialists(id) ON DELETE CASCADE;


--
-- TOC entry 4790 (class 2606 OID 107135)
-- Name: specialists specialists_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.specialists
    ADD CONSTRAINT specialists_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 4805 (class 2606 OID 107334)
-- Name: verification_logs verification_logs_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.verification_logs
    ADD CONSTRAINT verification_logs_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.admins(id) ON DELETE SET NULL;


--
-- TOC entry 4806 (class 2606 OID 107329)
-- Name: verification_logs verification_logs_specialist_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.verification_logs
    ADD CONSTRAINT verification_logs_specialist_id_fkey FOREIGN KEY (specialist_id) REFERENCES public.specialists(id) ON DELETE CASCADE;


-- Completed on 2025-12-03 11:53:13

--
-- PostgreSQL database dump complete
--

