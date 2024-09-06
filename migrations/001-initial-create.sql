-- public.package_count - Download counts of packages
CREATE TABLE public.package_count (
	id int4 GENERATED ALWAYS AS IDENTITY NOT NULL,
	package_id text NOT NULL,
	count_date date DEFAULT CURRENT_DATE NOT NULL,
	count int4 DEFAULT 1 NOT NULL,
	CONSTRAINT package_count_pk PRIMARY KEY (id)
);
CREATE UNIQUE INDEX package_count_package_id_count_date_idx ON public.package_count (package_id,count_date);

COMMENT ON TABLE public.package_count IS 'Download counts of packages.';
COMMENT ON COLUMN public.package_count.id IS 'Unique primary key for package count.';
COMMENT ON COLUMN public.package_count.package_id IS 'Full package ID this count is for.';
COMMENT ON COLUMN public.package_count.count_date IS 'Date this count is for.';
COMMENT ON COLUMN public.package_count.count IS 'Download ount for this date.';


-- public.package_total_count - Total download counts of a package
CREATE TABLE public.package_total_count (
	id int4 GENERATED ALWAYS AS IDENTITY NOT NULL,
	package_id text NOT NULL,
	total_count int4 DEFAULT 1 NOT NULL,
	CONSTRAINT package_total_count_pk PRIMARY KEY (id)
);
CREATE UNIQUE INDEX package_total_count_package_id_idx ON public.package_total_count (package_id);

COMMENT ON TABLE public.package_total_count IS 'Total download counts of a package.';
COMMENT ON COLUMN public.package_total_count.id IS 'Unique primary key for package total count.';
COMMENT ON COLUMN public.package_total_count.package_id IS 'Package ID this total count is for.';
COMMENT ON COLUMN public.package_total_count.total_count IS 'Total count the package has.';


-- public.handle_package_count - Procedure to handle incrementing download counts of a package
CREATE OR REPLACE FUNCTION public.handle_package_count(package_id varchar, package_version varchar)
    RETURNS void
    LANGUAGE plpgsql
AS $function$
	DECLARE 
		package_full_id text;
	BEGIN
		SELECT (package_id || '@' || package_version) INTO package_full_id;

		-- Update counts
		MERGE INTO public.package_total_count AS ptc
			USING (SELECT package_id AS version_id) AS ptc_details
			ON ptc_details.version_id = ptc.package_id
		WHEN NOT MATCHED THEN
			INSERT (package_id)
			VALUES (package_id)
		WHEN MATCHED THEN
			UPDATE SET total_count = ptc.total_count + 1;

		-- Update total counts
		MERGE INTO public.package_count AS pc
			USING (SELECT package_full_id AS version_id, current_date AS today_date) AS pc_details
			ON pc_details.version_id = pc.package_id
			AND pc_details.today_date = pc.count_date
		WHEN NOT MATCHED THEN
			INSERT (package_id)
			VALUES (package_full_id)	
		WHEN MATCHED THEN
			UPDATE SET count = pc.count + 1;
	END;
$function$
;

COMMENT ON FUNCTION public.handle_package_count(varchar, varchar) IS 'Procedure to handle incrementing download counts of a package.';
