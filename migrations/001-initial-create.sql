-- public.package
CREATE TABLE public.package (
	id int4 GENERATED ALWAYS AS IDENTITY NOT NULL,
	name varchar NOT NULL,
	CONSTRAINT package_pk PRIMARY KEY (id),
	CONSTRAINT package_unique UNIQUE (name)
);

COMMENT ON TABLE public.package IS 'Basic details related to a package.';
COMMENT ON COLUMN public.package.id IS 'Unique primary key for package.';
COMMENT ON COLUMN public.package.name IS 'Name of the package.';


-- public.package_version
CREATE TABLE public.package_version (
	id int4 GENERATED ALWAYS AS IDENTITY NOT NULL,
	package_id int4 NOT NULL,
	"version" varchar NOT NULL,
	CONSTRAINT package_version_pk PRIMARY KEY (id),
	CONSTRAINT package_version_package_fk FOREIGN KEY (package_id) REFERENCES public.package(id) ON DELETE RESTRICT
);
CREATE UNIQUE INDEX package_version_package_id_idx ON public.package_version (package_id,"version");

COMMENT ON TABLE public.package_version IS 'Versions of a package.';
COMMENT ON COLUMN public.package_version.id IS 'Unique primary key for package version.';
COMMENT ON COLUMN public.package_version.package_id IS 'Package this version is for.';
COMMENT ON COLUMN public.package_version."version" IS 'Package version label.';


-- public.package_count
CREATE TABLE public.package_count (
	id int4 GENERATED ALWAYS AS IDENTITY NOT NULL,
	package_version_id int4 NOT NULL,
	count_date date DEFAULT CURRENT_DATE NOT NULL,
	count int4 DEFAULT 1 NOT NULL,
	count_total int4 DEFAULT 1 NOT NULL,
	CONSTRAINT package_count_pk PRIMARY KEY (id),
	CONSTRAINT package_count_package_version_fk FOREIGN KEY (package_version_id) REFERENCES public.package_version(id) ON DELETE RESTRICT
);
CREATE UNIQUE INDEX package_count_package_version_id_idx ON public.package_count (package_version_id,count_date);

COMMENT ON TABLE public.package_count IS 'Download counts of packages.';
COMMENT ON COLUMN public.package_count.id IS 'Unique primary key for package count.';
COMMENT ON COLUMN public.package_count.package_version_id IS 'Package version this count is for.';
COMMENT ON COLUMN public.package_count.count_date IS 'Date this count is for.';
COMMENT ON COLUMN public.package_count.count IS 'Count for this date.';
COMMENT ON COLUMN public.package_count.count_total IS 'Total download count, upto the date.';


-- public.trg_copy_count_total -- Trigger function for copying previous count_total on new inserts into public.package_count.
CREATE OR REPLACE FUNCTION public.trg_copy_count_total()
    RETURNS trigger
    LANGUAGE plpgsql
AS $function$
	BEGIN
		NEW.count_total := (
			SELECT COALESCE((
				SELECT count_total FROM package_count
				WHERE package_version_id = NEW.package_version_id
				AND count_date < NEW.count_date
				ORDER BY count_date DESC
				LIMIT 1
			), NEW.count_total)
		);
		RETURN NEW;
	END;
$function$
;

COMMENT ON FUNCTION public.trg_copy_count_total() IS 'Trigger function for copying previous count_total on new inserts into public.package_count.';


-- public.package_count -> copy_count_total - Trigger for copying previous count_total on new inserts into public.package_count.
CREATE TRIGGER copy_count_total BEFORE
INSERT
    ON
    public.package_count FOR EACH ROW EXECUTE FUNCTION trg_copy_count_total();

COMMENT ON TRIGGER copy_count_total ON public.package_count IS 'Trigger for copying previous count_total on new inserts into public.package_count.';


-- public.handle_package_count - Function for handling updating the counter for a package.
CREATE OR REPLACE FUNCTION public.handle_package_count(package_id varchar, package_version varchar)
    RETURNS void
    LANGUAGE plpgsql
AS $function$
	DECLARE
		found_package public.package;
		found_package_version public.package_version;
	BEGIN
		-- First, get package
		SELECT 
			* INTO found_package
		FROM
			public.package
		WHERE name = package_id;

		-- No package, insert it
		IF found_package IS NULL THEN
			INSERT INTO public.package
				("name")
			VALUES(package_id)
			RETURNING * INTO found_package;
		END IF;

		-- Now get package version
		SELECT 
			* INTO found_package_version
		FROM
			public.package_version AS pck_version
		WHERE pck_version.package_id = found_package.id
		AND version = package_version;

		-- No package version, insert it
		IF found_package_version IS NULL THEN
			INSERT INTO public.package_version
				(package_id, version)
			VALUES(found_package.id, package_version)
			RETURNING * INTO found_package_version;
		END IF;

		-- Update count
		INSERT INTO public.package_count
			(package_version_id, count_date, count, count_total)
		VALUES (found_package_version.id, now(), 1, 1)
		ON CONFLICT (package_version_id, count_date)
		DO UPDATE 
		SET
			count = package_count.count + 1,
			count_total = package_count.count_total + 1;

	END;
$function$
;
