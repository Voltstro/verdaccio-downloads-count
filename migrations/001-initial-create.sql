-- public.package - Basic details related to a package
CREATE TABLE public.package (
	id int4 GENERATED ALWAYS AS IDENTITY NOT NULL,
	name varchar NOT NULL,
	CONSTRAINT package_pk PRIMARY KEY (id),
	CONSTRAINT package_unique UNIQUE (name)
);

COMMENT ON TABLE public.package IS 'Basic details related to a package.';
COMMENT ON COLUMN public.package.id IS 'Unique primary key for package.';
COMMENT ON COLUMN public.package.name IS 'Name of the package.';


-- public.package_version - Versions of a package
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


-- public.package_count - Download counts of packages
CREATE TABLE public.package_count (
	id int4 GENERATED ALWAYS AS IDENTITY NOT NULL,
	package_version_id int4 NOT NULL,
	count_date date DEFAULT CURRENT_DATE NOT NULL,
	count int4 DEFAULT 1 NOT NULL,
	CONSTRAINT package_count_pk PRIMARY KEY (id),
	CONSTRAINT package_count_package_version_fk FOREIGN KEY (package_version_id) REFERENCES public.package_version(id) ON DELETE RESTRICT
);
CREATE UNIQUE INDEX package_count_package_version_id_idx ON public.package_count (package_version_id,count_date);

COMMENT ON TABLE public.package_count IS 'Download counts of packages.';
COMMENT ON COLUMN public.package_count.id IS 'Unique primary key for package count.';
COMMENT ON COLUMN public.package_count.package_version_id IS 'Package version this count is for.';
COMMENT ON COLUMN public.package_count.count_date IS 'Date this count is for.';
COMMENT ON COLUMN public.package_count.count IS 'Count for this date.';


-- public.package_total_count - Total download counts of a package
CREATE TABLE public.package_total_count (
	id int4 GENERATED ALWAYS AS IDENTITY NOT NULL,
	package_version_id int4 NOT NULL,
	total_count int4 DEFAULT 1 NOT NULL,
	CONSTRAINT package_total_count_pk PRIMARY KEY (id),
	CONSTRAINT package_total_count_package_version_fk FOREIGN KEY (package_version_id) REFERENCES public.package_version(id) ON DELETE RESTRICT
);
CREATE UNIQUE INDEX package_total_count_package_version_id_idx ON public.package_total_count (package_version_id);

COMMENT ON TABLE public.package_total_count IS 'Total download counts of a package.';
COMMENT ON COLUMN public.package_total_count.id IS 'Unique primary key for package total count.';
COMMENT ON COLUMN public.package_total_count.package_version_id IS 'Package version this total count is for.';
COMMENT ON COLUMN public.package_total_count.total_count IS 'Total count the package has.';


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

		-- Update counts
		INSERT INTO public.package_count
			(package_version_id)
		VALUES (found_package_version.id)
		ON CONFLICT (package_version_id, count_date)
		DO UPDATE 
		SET
			count = package_count.count + 1;

		-- Update total counts
		INSERT INTO public.package_total_count
			(package_version_id)
		VALUES (found_package_version.id)
		ON CONFLICT (package_version_id)
		DO UPDATE 
		SET
			total_count = package_total_count.total_count + 1;

	END;
$function$
;
