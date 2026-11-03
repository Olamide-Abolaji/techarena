-- TechArena PostgreSQL schema v1.1 | PostgreSQL 15+
-- Four arenas; Knowledge/Scenario/Practical; deterministic evaluation only.
BEGIN;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE OR REPLACE FUNCTION set_updated_at() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at=now(); RETURN NEW; END; $$;

CREATE TABLE app_users (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 auth_provider varchar(40) NOT NULL DEFAULT 'cognito',
 auth_subject varchar(255) NOT NULL,
 email varchar(320) NOT NULL,
 email_verified boolean NOT NULL DEFAULT false,
 account_status varchar(20) NOT NULL DEFAULT 'active'
 CHECK(account_status IN ('active','suspended','deactivated')),
 created_at timestamptz NOT NULL DEFAULT now(),
 updated_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE(auth_provider,auth_subject));
CREATE UNIQUE INDEX uq_app_users_email_ci ON app_users(lower(email));

CREATE TABLE app_roles(id smallint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,role_key varchar(40) UNIQUE NOT NULL,description text);
CREATE TABLE user_roles(
 user_id uuid REFERENCES app_users(id) ON DELETE CASCADE,
 role_id smallint REFERENCES app_roles(id) ON DELETE RESTRICT,
 assigned_at timestamptz NOT NULL DEFAULT now(),PRIMARY KEY(user_id,role_id));
CREATE TABLE player_profiles(
 user_id uuid PRIMARY KEY REFERENCES app_users(id) ON DELETE CASCADE,
 display_name varchar(40) NOT NULL,avatar_url text,bio varchar(280),
 lifetime_xp bigint NOT NULL DEFAULT 0 CHECK(lifetime_xp>=0),
 current_level integer NOT NULL DEFAULT 1 CHECK(current_level>=1),
 profile_visibility varchar(20) NOT NULL DEFAULT 'public' CHECK(profile_visibility IN ('public','private')),
 created_at timestamptz NOT NULL DEFAULT now(),updated_at timestamptz NOT NULL DEFAULT now());

CREATE TABLE arenas(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),arena_key varchar(30) UNIQUE NOT NULL,
 name varchar(80) NOT NULL,description text NOT NULL,accent_color varchar(20),icon_key varchar(60),
 display_order smallint NOT NULL DEFAULT 0,is_active boolean NOT NULL DEFAULT true,created_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE arena_categories(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),arena_id uuid NOT NULL REFERENCES arenas(id) ON DELETE RESTRICT,
 category_key varchar(60) NOT NULL,name varchar(100) NOT NULL,description text,
 display_order smallint NOT NULL DEFAULT 0,is_active boolean NOT NULL DEFAULT true,
 UNIQUE(arena_id,category_key),UNIQUE(arena_id,name),UNIQUE(arena_id,id));

CREATE TABLE missions(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),arena_id uuid NOT NULL REFERENCES arenas(id) ON DELETE RESTRICT,
 category_id uuid,slug varchar(120) UNIQUE NOT NULL,title varchar(180) NOT NULL,
 short_description varchar(300) NOT NULL,
 difficulty varchar(20) NOT NULL CHECK(difficulty IN ('beginner','intermediate','advanced','expert')),
 estimated_minutes integer NOT NULL CHECK(estimated_minutes>0),
 status varchar(20) NOT NULL DEFAULT 'draft' CHECK(status IN ('draft','published','unpublished','archived')),
 current_version_id uuid,created_by uuid REFERENCES app_users(id) ON DELETE SET NULL,
 created_at timestamptz NOT NULL DEFAULT now(),updated_at timestamptz NOT NULL DEFAULT now(),
 FOREIGN KEY(arena_id,category_id) REFERENCES arena_categories(arena_id,id) ON DELETE RESTRICT);

CREATE TABLE mission_versions(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),mission_id uuid NOT NULL REFERENCES missions(id) ON DELETE RESTRICT,
 version_number integer NOT NULL CHECK(version_number>0),briefing text NOT NULL,
 instructions jsonb NOT NULL DEFAULT '[]' CHECK(jsonb_typeof(instructions)='array'),
 challenge_type varchar(20) NOT NULL CHECK(challenge_type IN ('knowledge','scenario','practical')),
 evaluation_mode varchar(20) NOT NULL DEFAULT 'deterministic' CHECK(evaluation_mode='deterministic'),
 submission_schema jsonb NOT NULL DEFAULT '{}' CHECK(jsonb_typeof(submission_schema)='object'),
 challenge_config jsonb NOT NULL DEFAULT '{}' CHECK(jsonb_typeof(challenge_config)='object'),
 evaluation_config jsonb NOT NULL DEFAULT '{}' CHECK(jsonb_typeof(evaluation_config)='object'),
 rubric jsonb NOT NULL DEFAULT '{}' CHECK(jsonb_typeof(rubric)='object'),
 xp_reward integer NOT NULL DEFAULT 0 CHECK(xp_reward>=0),
 pass_score numeric(5,2) NOT NULL DEFAULT 70 CHECK(pass_score BETWEEN 0 AND 100),
 changelog text,publication_status varchar(20) NOT NULL DEFAULT 'draft'
 CHECK(publication_status IN ('draft','validated','published','retired')),
 published_at timestamptz,created_by uuid REFERENCES app_users(id) ON DELETE SET NULL,
 created_at timestamptz NOT NULL DEFAULT now(),UNIQUE(mission_id,version_number),UNIQUE(mission_id,id));
ALTER TABLE missions ADD CONSTRAINT fk_missions_current_version
 FOREIGN KEY(id,current_version_id) REFERENCES mission_versions(mission_id,id) DEFERRABLE INITIALLY DEFERRED;

CREATE TABLE mission_assets(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),mission_version_id uuid NOT NULL REFERENCES mission_versions(id) ON DELETE RESTRICT,
 asset_key varchar(120) NOT NULL,asset_type varchar(30) NOT NULL
 CHECK(asset_type IN ('csv','image','document','diagram','log_file','other')),
 storage_key text NOT NULL,original_name varchar(255),mime_type varchar(120),
 size_bytes bigint CHECK(size_bytes>=0),checksum_sha256 char(64),is_downloadable boolean NOT NULL DEFAULT true,
 metadata jsonb NOT NULL DEFAULT '{}',created_at timestamptz NOT NULL DEFAULT now(),UNIQUE(mission_version_id,asset_key));

CREATE TABLE mission_attempts(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),user_id uuid NOT NULL REFERENCES app_users(id) ON DELETE RESTRICT,
 mission_id uuid NOT NULL REFERENCES missions(id) ON DELETE RESTRICT,mission_version_id uuid NOT NULL,
 attempt_number integer NOT NULL CHECK(attempt_number>0),
 status varchar(20) NOT NULL DEFAULT 'in_progress'
 CHECK(status IN ('in_progress','submitted','evaluating','completed','abandoned','failed')),
 started_at timestamptz NOT NULL DEFAULT now(),submitted_at timestamptz,completed_at timestamptz,
 last_activity_at timestamptz NOT NULL DEFAULT now(),score numeric(5,2) CHECK(score BETWEEN 0 AND 100),
 passed boolean,xp_awarded integer NOT NULL DEFAULT 0 CHECK(xp_awarded>=0),
 UNIQUE(user_id,mission_id,attempt_number),
 FOREIGN KEY(mission_id,mission_version_id) REFERENCES mission_versions(mission_id,id) ON DELETE RESTRICT);
CREATE INDEX idx_attempts_user_recent ON mission_attempts(user_id,started_at DESC);
CREATE INDEX idx_attempts_mission_status ON mission_attempts(mission_id,status);
CREATE INDEX idx_attempts_status_activity ON mission_attempts(status,last_activity_at);

CREATE TABLE attempt_submissions(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),attempt_id uuid NOT NULL REFERENCES mission_attempts(id) ON DELETE RESTRICT,
 revision_number integer NOT NULL CHECK(revision_number>0),
 submission_type varchar(20) NOT NULL CHECK(submission_type IN ('knowledge','scenario','practical')),
 response_text text,response_data jsonb NOT NULL DEFAULT '{}' CHECK(jsonb_typeof(response_data)='object'),
 is_final boolean NOT NULL DEFAULT false,submitted_by uuid NOT NULL REFERENCES app_users(id) ON DELETE RESTRICT,
 created_at timestamptz NOT NULL DEFAULT now(),UNIQUE(attempt_id,revision_number));
CREATE UNIQUE INDEX uq_attempt_one_final_submission ON attempt_submissions(attempt_id) WHERE is_final;
CREATE TABLE submission_assets(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),submission_id uuid NOT NULL REFERENCES attempt_submissions(id) ON DELETE CASCADE,
 storage_key text NOT NULL,original_name varchar(255),mime_type varchar(120),
 size_bytes bigint CHECK(size_bytes>=0),checksum_sha256 char(64),created_at timestamptz NOT NULL DEFAULT now());

CREATE TABLE evaluation_results(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),attempt_id uuid NOT NULL REFERENCES mission_attempts(id) ON DELETE RESTRICT,
 submission_id uuid NOT NULL REFERENCES attempt_submissions(id) ON DELETE RESTRICT,
 evaluator_type varchar(20) NOT NULL DEFAULT 'deterministic' CHECK(evaluator_type='deterministic'),
 evaluator_version varchar(80) NOT NULL,rubric_version varchar(80),
 score numeric(5,2) NOT NULL CHECK(score BETWEEN 0 AND 100),passed boolean NOT NULL,
 max_points numeric(10,2) NOT NULL CHECK(max_points>0),
 earned_points numeric(10,2) NOT NULL CHECK(earned_points BETWEEN 0 AND max_points),
 score_breakdown jsonb NOT NULL DEFAULT '{}',reference_checks jsonb NOT NULL DEFAULT '[]',
 evaluation_status varchar(20) NOT NULL DEFAULT 'completed'
 CHECK(evaluation_status IN ('queued','running','completed','failed','needs_review')),
 evaluated_at timestamptz NOT NULL DEFAULT now(),created_at timestamptz NOT NULL DEFAULT now(),UNIQUE(submission_id));
CREATE INDEX idx_evaluations_attempt ON evaluation_results(attempt_id,evaluated_at DESC);
CREATE TABLE evaluation_checks(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),evaluation_id uuid NOT NULL REFERENCES evaluation_results(id) ON DELETE CASCADE,
 criterion_key varchar(100) NOT NULL,display_name varchar(160) NOT NULL,
 max_points numeric(10,2) NOT NULL CHECK(max_points>=0),
 earned_points numeric(10,2) NOT NULL CHECK(earned_points BETWEEN 0 AND max_points),
 passed boolean,learner_explanation text,evidence jsonb NOT NULL DEFAULT '{}',
 display_order smallint NOT NULL DEFAULT 0,UNIQUE(evaluation_id,criterion_key));
CREATE TABLE feedback_items(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),evaluation_id uuid NOT NULL REFERENCES evaluation_results(id) ON DELETE CASCADE,
 criterion_key varchar(100),feedback_type varchar(30) NOT NULL
 CHECK(feedback_type IN ('strength','improvement','explanation','next_step','warning')),
 message text NOT NULL,evidence jsonb NOT NULL DEFAULT '{}',display_order smallint NOT NULL DEFAULT 0,
 created_at timestamptz NOT NULL DEFAULT now());

CREATE TABLE xp_transactions(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),user_id uuid NOT NULL REFERENCES app_users(id) ON DELETE RESTRICT,
 amount integer NOT NULL CHECK(amount<>0),
 transaction_type varchar(30) NOT NULL CHECK(transaction_type IN ('mission_completion','achievement','admin_adjustment','bonus','reversal')),
 source_type varchar(40) NOT NULL,source_id uuid,idempotency_key varchar(180) UNIQUE NOT NULL,
 description text,created_at timestamptz NOT NULL DEFAULT now());
CREATE INDEX idx_xp_user_created ON xp_transactions(user_id,created_at DESC);
CREATE TABLE achievements(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),achievement_key varchar(80) UNIQUE NOT NULL,
 name varchar(120) NOT NULL,description text NOT NULL,icon_key varchar(80),
 criteria jsonb NOT NULL DEFAULT '{}',xp_reward integer NOT NULL DEFAULT 0 CHECK(xp_reward>=0),
 is_active boolean NOT NULL DEFAULT true,created_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE user_achievements(
 user_id uuid NOT NULL REFERENCES app_users(id) ON DELETE RESTRICT,
 achievement_id uuid NOT NULL REFERENCES achievements(id) ON DELETE RESTRICT,
 awarded_at timestamptz NOT NULL DEFAULT now(),source_attempt_id uuid REFERENCES mission_attempts(id) ON DELETE SET NULL,
 PRIMARY KEY(user_id,achievement_id));

CREATE TABLE audit_events(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),actor_user_id uuid REFERENCES app_users(id) ON DELETE SET NULL,
 action varchar(100) NOT NULL,entity_type varchar(80) NOT NULL,entity_id uuid,
 metadata jsonb NOT NULL DEFAULT '{}',created_at timestamptz NOT NULL DEFAULT now());
CREATE INDEX idx_audit_entity ON audit_events(entity_type,entity_id,created_at DESC);
CREATE INDEX idx_audit_actor ON audit_events(actor_user_id,created_at DESC);

CREATE VIEW player_xp_totals AS
 SELECT u.id user_id,COALESCE(SUM(x.amount),0)::bigint lifetime_xp
 FROM app_users u LEFT JOIN xp_transactions x ON x.user_id=u.id GROUP BY u.id;
CREATE VIEW leaderboard_all_time AS
 SELECT p.user_id,p.display_name,p.avatar_url,COALESCE(SUM(x.amount),0)::bigint xp,
 RANK() OVER(ORDER BY COALESCE(SUM(x.amount),0) DESC) rank
 FROM player_profiles p LEFT JOIN xp_transactions x ON x.user_id=p.user_id
 GROUP BY p.user_id,p.display_name,p.avatar_url;

CREATE TRIGGER trg_app_users_updated BEFORE UPDATE ON app_users FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_profiles_updated BEFORE UPDATE ON player_profiles FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_missions_updated BEFORE UPDATE ON missions FOR EACH ROW EXECUTE FUNCTION set_updated_at();

INSERT INTO app_roles(role_key,description) VALUES
 ('learner','Standard TechArena learner'),('admin','Platform administrator and content manager')
ON CONFLICT(role_key) DO NOTHING;
INSERT INTO arenas(arena_key,name,description,accent_color,icon_key,display_order) VALUES
 ('cloud','Cloud Arena','Build, deploy and troubleshoot cloud solutions.','#35A7FF','cloud',1),
 ('cyber','Cyber Arena','Detect threats, investigate incidents and secure systems.','#B65CFF','shield',2),
 ('networking','Networking Arena','Design, configure and troubleshoot modern networks.','#20D96B','network',3),
 ('data','Data Arena','Explore data, uncover insights and solve business problems.','#FFB21C','database',4)
ON CONFLICT(arena_key) DO NOTHING;
COMMIT;

-- Application service invariants:
-- * Never return evaluation_config or answer keys to learner clients.
-- * Published versions are immutable; edit by creating a new version.
-- * Enforce attempt state transitions and attempt limits in FastAPI.
-- * Final submit/evaluate/XP award must be concurrency-safe and transactional.
-- * XP idempotency key: mission-completion:<user_uuid>:<mission_uuid> (prevents retake awards).
-- * No arbitrary code or SQL execution in MVP. Apply to a disposable dev DB first.