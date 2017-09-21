 DROP VIEW vfiles CASCADE;

CREATE OR REPLACE VIEW vfiles
  AS SELECT
      f.file_id,
      fn.file_name,
      study_dirname (fn.family_name, fn.type_name) as study_dirname,
      fn.family_name, fn.type_name, fn.impl_name, fn.other_name,
      f.file_size,
      f.nb_mods,
      vn.version_name,
      vn.main as version_main,
      vn.major as version_major,
      vn.minor as version_minor,
      vn.release_date
  FROM
      files f
  INNER JOIN
      file_names fn
  ON
      f.file_name = fn.file_name
  INNER JOIN
      versions vn
  ON
      f.version_name = vn.version_name;

--
-- Name: Release age
--
-- If there is next release yet, replace the date by
--    now()::date
-- DROP VIEW "Release age" CASCADE;

CREATE or replace VIEW "Release age" AS
select v1.version_name,
       v1.release_date,
       coalesce((select min(v2.release_date)
                 from versions v2
                 where (v2.release_date > v1.release_date)),
                '2010-05-16'::date) as next_release_date, -- 2.6.34
       coalesce((select min(v2.release_date)
                 from versions v2
                 where (v2.release_date > v1.release_date)),
                '2010-05-16'::date) -v1.release_date
		as release_length
    from versions v1,
    	 (select min(v3.release_date) as start
	 from versions v3) as s
    order by v1.release_date;


--
-- Name: Bug ages
--
-- DROP VIEW "Bug ages" CASCADE;

CREATE or replace VIEW "Bug ages" AS
    SELECT error_names.standardized_name,
    	   study_dirname,
    	   max(a.next_release_date) AS max,
	   min(v.release_date) AS min,
	   (max(a.next_release_date) - min(v.release_date))
	   		AS "age in days",
	   ceil((((max(a.next_release_date) - min(v.release_date)))::numeric / 30.5))
	   		AS "age in months",
	  max(v.minor) - min(v.minor) + 1
			AS "age in versions",
	   correlations.correlation_id
    FROM error_names, correlations, reports, vfiles, "Release age" a, versions v
    WHERE correlations.report_error_name = error_names.report_error_name
    	  AND v.release_date >= '2003-12-18'
    	  AND correlations.correlation_id = reports.correlation_id
	  AND correlations.status = 'BUG'
	  AND reports.file_id = vfiles.file_id
	  AND vfiles.version_name = a.version_name
	  AND v.version_name = a.version_name
	  AND error_names.standardized_name != 'Real'
    GROUP BY correlations.correlation_id, error_names.standardized_name, vfiles.study_dirname;

--
-- Name: Correlation ages
--
-- DROP VIEW "Bug ages" CASCADE;

CREATE or replace VIEW "Correlation ages" AS
    SELECT error_names.standardized_name,
    	   study_dirname,
    	   max(a.next_release_date) AS max,
	   min(v.release_date) AS min,
	   (max(a.next_release_date) - min(v.release_date))
	   		AS "age in days",
	   ceil((((max(a.next_release_date) - min(v.release_date)))::numeric / 30.5))
	   		AS "age in months",
	  max(v.minor) - min(v.minor) + 1
			AS "age in versions",
	   correlations.correlation_id
    FROM error_names, correlations, reports, vfiles, "Release age" a, versions v
    WHERE correlations.report_error_name = error_names.report_error_name
    	  AND v.release_date >= '2003-12-18'
    	  AND correlations.correlation_id = reports.correlation_id
	  AND reports.file_id = vfiles.file_id
	  AND vfiles.version_name = a.version_name
	  AND v.version_name = a.version_name
	  AND error_names.standardized_name != 'Real'
    GROUP BY correlations.correlation_id, error_names.standardized_name, vfiles.study_dirname;

--
-- Name: report_ages
--
-- DROP VIEW report_ages CASCADE;

CREATE OR REPLACE VIEW report_ages AS
    SELECT error_names.standardized_name,
    	   study_dirname,
    	   max(a.next_release_date) AS max,
	   min(v.release_date) AS min,
	   (max(a.next_release_date) - min(v.release_date))
	   		AS "age in days",
	   ceil((((max(a.next_release_date) - min(v.release_date)))::numeric / 30.5))
	   		AS "age in month",
	   correlations.correlation_id,
	   correlations.status
    FROM error_names, correlations, reports, vfiles, "Release age" a, versions v
    WHERE correlations.report_error_name = error_names.report_error_name
    	  AND correlations.correlation_id = reports.correlation_id
	  AND reports.file_id = vfiles.file_id
	  AND vfiles.version_name = a.version_name
	  AND v.version_name = a.version_name
    GROUP BY correlations.status, correlations.correlation_id, error_names.standardized_name, vfiles.study_dirname;

--
-- Name: Count evol
--
-- DROP VIEW "Count evol" CASCADE;

CREATE or replace VIEW "Count evol"  AS
    SELECT v2.version_name,
    	   v2.release_date,
	   coalesce(sum(c.data),0) AS data,
	   v2.standardized_name,
	   v2.study_dirname
    FROM (SELECT DISTINCT v.version_name, v.release_date, e.standardized_name, d.dirname AS study_dirname
    	 FROM versions v, error_names e, dir_names d
    	 ) v2
    LEFT OUTER JOIN
        (SELECT v.version_name,
	   count(correlations.correlation_id) AS data,
	   error_names.standardized_name,
	   study_dirname(vfiles.family_name, vfiles.type_name) as study_dirname
         FROM versions v, error_names, vfiles, correlations, reports
         WHERE ((((((error_names.report_error_name)::text = (correlations.report_error_name)::text)
    	  AND ((correlations.status)::text = 'BUG'::text))
  	  AND (correlations.correlation_id = reports.correlation_id))
  	  AND (reports.file_id = vfiles.file_id))
  	  AND ((vfiles.version_name)::text = (v.version_name)::text))
        GROUP BY error_names.standardized_name,
    	  correlations.report_error_name,
  	  v.version_name,
  	  vfiles.family_name,
  	  vfiles.type_name
        ) AS c
    ON v2.version_name = c.version_name
    AND v2.standardized_name = c.standardized_name
    AND v2.study_dirname = c.study_dirname
    GROUP BY v2.standardized_name,
  	  v2.version_name,
  	  v2.release_date,
  	  v2.study_dirname;

--
-- Name: Origin of bugs in last release
--

CREATE or replace VIEW "Origin of bugs" AS
select cur.version_name         as for_version_name,
       base.version_name        as version_name,
       base.release_date        as release_date,
       e.standardized_name      as standardized_name,
       count(r1.correlation_id) as number_of_bugs_already_present
       from versions cur, versions base, reports r1, reports r2, files f1, files f2, correlations c, error_names e
       where base.release_date <= cur.release_date
          and r1.file_id=f1.file_id
          and r2.file_id=f2.file_id
         and base.version_name=f1.version_name
         and cur.version_name=f2.version_name
         and r1.correlation_id=r2.correlation_id
         and r1.correlation_id=c.correlation_id
         AND c.status = 'BUG'
         and c.report_error_name=e.report_error_name
       group by base.version_name,
       	     cur.version_name,
	     cur.release_date,
	     base.release_date,
	     e.standardized_name,
	     base.release_date
       order by cur.release_date, base.release_date, e.standardized_name;

--
-- Name: Per dir and cat
--
-- DROP VIEW public."Per dir and cat";

CREATE OR REPLACE VIEW "Per dir and cat" AS
       SELECT v.version_name, d.dirname, s.standardized_name,
       	      COALESCE((SELECT sum(c.data)
	       FROM "Count evol" c
	       WHERE v.version_name = c.version_name
		      AND d.dirname = c.study_dirname
		      AND s.standardized_name=c.standardized_name
	       GROUP BY c.standardized_name,
   	       	        c.study_dirname,
	    		c.version_name
	      ) , 0) AS "Number of errors"
       FROM versions v, dir_names d, standardized_names s
       ORDER BY v.version_name, d.dirname, s.standardized_name;

--
-- Name: Bugs in last Linux
--
CREATE or replace VIEW "Bugs in last Linux" AS
    SELECT correlations.correlation_id,
    	   correlations.status,
	   correlations.report_error_name,
	   reports.text_link,
	   files.file_name,
	   reports.line_no,
	   reports.column_start,
	   reports.column_end
    FROM correlations, reports, files, versions
    WHERE ((((((correlations.status)::text = 'BUG'::text)
    	  AND (correlations.correlation_id = reports.correlation_id))
	  AND (reports.file_id = files.file_id))
	  AND ((files.version_name)::text = (versions.version_name)::text))
	  AND (versions.release_date = last_release_date()))
    ORDER BY correlations.report_error_name, files.file_name;

--
-- Name: Birth of bugs (in git)
--
-- DROP VIEW public."Birth of bugs (in git)";

CREATE OR REPLACE VIEW "Birth of bugs (in git)" AS
    SELECT c.correlation_id,
    	   r.report_id,
	   a.min AS birth_date,
	   f.file_name,
	   r.line_no,
	   r.column_start,
	   r.column_end
    FROM correlations c, reports r, files f, versions v, "Bug ages" a
    WHERE c.correlation_id = r.correlation_id
    AND c.correlation_id = a.correlation_id
    AND r.file_id = f.file_id
    AND f.version_name = v.version_name
    AND v.release_date = a.min
    AND a.min >= '2005-06-17';


--
-- Name: Birth of reports
--
-- DROP VIEW public."Birth of reports" CASCADE;

CREATE OR REPLACE VIEW "Birth of reports" AS
    SELECT c.correlation_id,
       c.status,
       e.standardized_name,
       c.report_error_name,
    	   r.report_id,
	   f.version_name,
	   a.min AS birth_date,
	   f.study_dirname,
	   f.file_name,
	   r.line_no,
	   r.column_start,
	   r.column_end
    FROM correlations c, reports r, vfiles f,
    	 versions v, report_ages a, error_names e
    WHERE c.correlation_id = r.correlation_id
    AND c.correlation_id = a.correlation_id
    AND r.file_id = f.file_id
    AND f.version_name = v.version_name
    AND v.release_date = a.min
    AND c.report_error_name = e.report_error_name;

--
-- Name: Death of reports
--
-- DROP VIEW public."Death of reports";

-- CREATE OR REPLACE VIEW "Death of reports" AS
--     SELECT c.correlation_id,
--         c.status,
--         e.standardized_name,
--         c.report_error_name,
--     	r.report_id,
-- 	f.version_name,
-- 	a.max AS death_date,
-- 	f.study_dirname,
-- 	f.file_name,
-- 	r.line_no,
-- 	r.column_start,
-- 	r.column_end
--     FROM correlations c, reports r, vfiles f,
--     	 report_ages a, error_names e
--     WHERE c.correlation_id = r.correlation_id
--     AND c.correlation_id = a.correlation_id
--     AND r.file_id = f.file_id
--     AND f.release_date = a.max
--     AND c.report_error_name = e.report_error_name;

-- compute the complet churn of files (long running request)
CREATE or replace VIEW file_churns_linear AS
select f2.file_id,
       f2.file_name,
       f2.version_name,
       cast(sum(f1.nb_mods) as bigint) as file_churn
       from files f1, files f2, versions v1, versions v2
       where f1.file_name=f2.file_name
         and f1.version_name=v1.version_name
       	 and f2.version_name=v2.version_name
       	 and v1.release_date<=v2.release_date
       group by f2.file_id, f2.file_name, f2.version_name, v2.release_date
       order by v2.release_date, file_churn;

-- compute the complet churn of files but associate a bigger weight to youger releases (long running request)
CREATE or replace VIEW file_churns_weighted AS
select f2.file_id,
       f2.file_name,
       f2.version_name,
       cast(sum(f1.nb_mods * (r1.release_date - base.release_date)) as bigint) as file_churn
       from files f1, 
			 			files f2, 
						versions v1, 
						versions v2, 
						"Release age" r1, 
						(select r.release_date from "Release age" r where r.version_name='linux-2.6.0') as base
       where f1.file_name=f2.file_name
         and f1.version_name=v1.version_name
       	 and f2.version_name=v2.version_name
       	 and v1.release_date<=v2.release_date
				 and r1.version_name=v1.version_name
       group by f2.file_id, f2.file_name, f2.version_name, v2.release_date
       order by v2.release_date, file_churn;

-- compute the complet churn of files but associate a bigger weight to youger releases (long running request)
CREATE or replace VIEW file_churns_simple AS
select f.file_id,
       f.file_name,
       f.version_name,
			 cast(f.nb_mods as bigint) as file_churn
       from files f,
 						versions v
        where f.version_name=v.version_name
        order by v.release_date, file_churn;

create or replace view file_churns as select * from file_churns_simple;

-- compute the complet age of files (long running request)
-- DROP VIEW file_ages CASCADE;

CREATE OR REPLACE VIEW file_ages AS
SELECT f2.file_name,
       f2.version_name,
       (max(r.next_release_date) - min(v1.release_date)) AS file_age_in_days,
       (max(r.next_release_date) - min(v1.release_date)) / 30.5 AS file_age_in_months,
       (max(r.next_release_date) - min(v1.release_date)) / 365 AS file_age_in_years
       FROM files f1, files f2, versions v1, versions v2, "Release age" r
       WHERE f1.file_name    =  f2.file_name
         AND f1.version_name =  v1.version_name
       	 AND f2.version_name =  v2.version_name
       	 AND v1.release_date <= v2.release_date
	 AND v1.version_name = r.version_name
       GROUP BY f2.file_name, f2.version_name, v2.release_date
       ORDER BY v2.release_date, file_age_in_days;

-- report with its status and its standardized_name
create or replace view standardized_notes as
select n.*, cn.standardized_name
			 from  notes n, note_names cn
			 where n.note_error_name = cn.note_error_name;

-- Expanded view of reports
-- DROP VIEW "Reports info";

CREATE OR REPLACE VIEW "Reports info" AS
SELECT correlations.correlation_id,
       correlations.status,
       reports.report_id,
       reports.file_id,
       error_names.standardized_name,
       correlations.report_error_name,
       versions.release_date,
       vfiles.version_name,
       vfiles.file_name,
       vfiles.family_name,
       study_dirname(vfiles.family_name, vfiles.type_name) as study_dirname,
       reports.text_link,
       reports.line_no,
       reports.column_start,
       reports.column_end
FROM correlations, reports, vfiles, versions, error_names
WHERE correlations.correlation_id = reports.correlation_id
AND error_names.report_error_name = correlations.report_error_name
AND reports.file_id = vfiles.file_id
AND vfiles.version_name::text = versions.version_name::text
;

-- reports that have an associated note
create or replace view report_with_notes as
select r.report_id, r.file_id, r.standardized_name, r.status, r.line_no
       from  "Reports info" r, standardized_notes n
       where r.file_id = n.file_id
       and r.line_no = n.line_no
       and (r.standardized_name='Block'
       	   or r.standardized_name='Lock'
	   or r.standardized_name='LockIntr'
	   or r.column_start = n.column_start)
       and r.standardized_name = n.standardized_name
       and useful_for_rates(n.standardized_name);

-- number of report and note by file and by standardized_name (useful to compute rate)
-- DROP VIEW rates CASCADE;

create or replace view rates as
select nnn.file_id,
       f.study_dirname,
       f.version_name,
			 nnn.standardized_name,
			 coalesce(rrr.total,0) as number_of_reports,
			 nnn.total as number_of_notes
	from vfiles f, (select r.file_id,
	     	     	 r.standardized_name,
		     			 count(*) as total
	     				 from  report_with_notes r
	     				 where r.status='BUG'
	     				 group by r.file_id, r.standardized_name
	     ) as rrr -- count only reports that have an associated note
	right outer join
	      (select n.file_id,
	      				n.standardized_name,
	      				count(*) as total
	      				from standardized_notes n
	      				group by n.file_id, n.standardized_name) as nnn
	on    rrr.standardized_name=nnn.standardized_name
	and   rrr.file_id=nnn.file_id
	and   useful_for_rates(nnn.standardized_name)
	where nnn.file_id = f.file_id;

-- number of report and note by function and by standardized_name (useful to compute rate)
create or replace view rates_per_fct as
select nnn.function_id,
	nnn.standardized_name,
	coalesce(rrr.total,0) as number_of_reports,
	nnn.total as number_of_notes
	from (select f.function_id,
	     	     r.standardized_name,
		     count(*) as total
	     from  report_with_notes r, functions f
	     where r.status='BUG'
	     AND  r.line_no between f.start and f.finish
	     group by f.function_id, r.standardized_name
	     ) as rrr -- count only reports that have an associated note
	right outer join
	      (select f.function_id,
	      	      n.standardized_name,
		      count(*) as total
	      from standardized_notes n, functions f
	      where n.line_no between f.start and f.finish
	      group by f.function_id, n.standardized_name
	      ) as nnn
	on    rrr.standardized_name=nnn.standardized_name
	and   rrr.function_id=nnn.function_id
	and   useful_for_rates(nnn.standardized_name);

-- number of report and note by file and by standardized_name (useful to compute rate)
-- DROP VIEW rates_per_dir CASCADE;

CREATE OR REPLACE VIEW rates_per_dir AS
SELECT r.version_name,
       v.release_date,
       r.study_dirname,
       r.standardized_name,
       sum(r.number_of_reports) as number_of_reports,
       sum(r.number_of_notes) as number_of_notes
FROM rates r, versions v
WHERE r.version_name = v.version_name
GROUP BY r.version_name,
       v.release_date,
       r.study_dirname,
       r.standardized_name
;

-- list only orphan reports, i.e, reports that do not have an associated note
-- DROP VIEW orphan_reports CASCADE;

create or replace view orphan_reports as
select sr.standardized_name,
       sr.report_error_name,
       sr.report_id,
       f.file_id,
       f.version_name,
       f.file_name,
       sr.line_no,
       sr.column_start,
       sr.status
  from  "Reports info" sr, files f
  where not exists (select rn.report_id
  	from report_with_notes rn
	where rn.report_id=sr.report_id)
  AND f.file_id=sr.file_id
	and useful_for_rates(sr.standardized_name)
  ORDER BY sr.standardized_name, f.version_name, f.file_name, sr.line_no;

-- gives the rate of orphan, function of the standardized_name
create or replace view orphan_rates as
select r.standardized_name,
       coalesce(o.total, 0) as orphan,
       r.total as total,
       cast(coalesce(o.total, 0) as numeric)/cast(r.total as numeric) as orphan_rate
       from
	(select o.standardized_name, count(*) as total from orphan_reports o
		group by o.standardized_name) as o
	right outer join
	      (select r.standardized_name, count(*) as total
	      from "Reports info" r group by r.standardized_name) as r
	on o.standardized_name=r.standardized_name
where useful_for_rates(r.standardized_name);

-- gives the notes that do not have associated functions
create or replace view note_without_functions as
select n.note_id, n.file_id, f.version_name, f.file_name, n.line_no, n.column_start, n.column_end, n.note_error_name
from notes n, files f, note_names e
where not exists
      (select * from functions func
      where n.file_id=func.file_id
      and n.line_no between func.start and func.finish)
and f.file_id=n.file_id
and n.note_error_name = e.note_error_name
and useful_for_rates(e.standardized_name);

-- same thing for reports
create or replace view report_without_functions as
select r.report_id, f.file_id, f.version_name, f.file_name, r.line_no, r.column_start, r.column_end, c.report_error_name
from reports r, files f, correlations c, error_names e
where not exists
      (select * from functions func
      where r.file_id=func.file_id
      and r.line_no between func.start and func.finish)
and f.file_id=r.file_id and c.correlation_id=r.correlation_id
and c.report_error_name = e.report_error_name
and useful_for_rates(e.standardized_name);

-- Expanded view of faults
-- DROP VIEW "Faults info";

CREATE OR REPLACE VIEW "Faults info" AS
SELECT correlations.correlation_id,
       reports.report_id,
       reports.file_id,
       error_names.standardized_name,
       correlations.report_error_name,
       versions.release_date,
       vfiles.version_name,
       vfiles.file_name,
       vfiles.family_name,
       study_dirname(vfiles.family_name, vfiles.type_name) as study_dirname,
       reports.text_link,
       reports.line_no,
       reports.column_start,
       reports.column_end
FROM correlations, reports, vfiles, versions, error_names
WHERE correlations.correlation_id = reports.correlation_id
AND correlations.status = 'BUG'
AND error_names.report_error_name = correlations.report_error_name
AND reports.file_id = vfiles.file_id
AND vfiles.version_name::text = versions.version_name::text
;

-- Expanded view of notes
-- DROP VIEW "Notes info";

CREATE OR REPLACE VIEW "Notes info" AS
SELECT notes.note_id,
       note_names.standardized_name,
       notes.note_error_name,
       versions.release_date,
       vfiles.version_name,
       vfiles.file_name,
       vfiles.family_name,
       study_dirname(vfiles.family_name, vfiles.type_name) as study_dirname,
       notes.text_link,
       notes.line_no,
       notes.column_start,
       notes.column_end
FROM notes, vfiles, versions, note_names
WHERE note_names.note_error_name = notes.note_error_name
AND notes.file_id = vfiles.file_id
AND vfiles.version_name::text = versions.version_name::text
;

-- List of correlated reports in the TODO state
-- DROP VIEW "TODO";

CREATE OR REPLACE VIEW "TODO" AS
SELECT correlations.correlation_id,
       reports.report_id,
       correlations.report_error_name,
       files.version_name,
       files.file_name,
       reports.text_link,
       reports.line_no,
       reports.column_start,
       reports.column_end
FROM correlations, reports, files, versions
WHERE correlations.status = 'TODO'
AND correlations.correlation_id = reports.correlation_id
AND reports.file_id = files.file_id
AND files.version_name::text = versions.version_name::text
AND versions.release_date =
    (SELECT
	min(v2.release_date)
     FROM reports r2, files f2, versions v2
     WHERE correlations.correlation_id = r2.correlation_id
     AND r2.file_id = f2.file_id
     AND f2.version_name::text = v2.version_name::text
     )
;

-- Statistics about TODOs
-- DROP VIEW "TODO count";

CREATE OR REPLACE VIEW "TODO count" AS
SELECT e.standardized_name, e.report_error_name, coalesce(cerr."todos",0)
FROM (SELECT e.standardized_name, e.report_error_name FROM error_names e) as e
LEFT OUTER JOIN
     (SELECT err.standardized_name, c.report_error_name, count(c.correlation_id) as "todos"
     FROM correlations c, error_names err
     WHERE c.report_error_name = err.report_error_name
     AND c.status = 'TODO'
     GROUP BY err.standardized_name, c.report_error_name
     ) as cerr
ON e.report_error_name = cerr.report_error_name
;

-- Fault count across release

CREATE OR REPLACE VIEW faults_across_releases AS
 SELECT cur.version_name AS for_version_name,
 	base.version_name,
	base.release_date,
 	e.standardized_name,
	count(r1.correlation_id) AS number_of_bugs
   FROM versions cur, versions base,
   	reports r1, reports r2,
	files f1, files f2,
	correlations c,
	error_names e
  WHERE  r1.file_id = f1.file_id
  AND r2.file_id = f2.file_id
  AND base.version_name::text = f1.version_name::text
  AND cur.version_name::text = f2.version_name::text
  AND r1.correlation_id = r2.correlation_id
  AND r1.correlation_id = c.correlation_id
  AND c.status::text = 'BUG'::text
  AND c.report_error_name=e.report_error_name
  GROUP BY base.version_name,
  	   cur.version_name,
	   cur.release_date,
	   base.release_date,
	   e.standardized_name
  ORDER BY cur.release_date, base.release_date
;

-- Fault count center on release
-- DROP VIEW faults_around_releases;

CREATE OR REPLACE VIEW faults_around_releases AS
 SELECT cur.version_name AS for_version_name,
 	base.version_name,
	(base.release_date-cur.release_date)/30.5 as delta_in_month,
 	e.standardized_name,
	count(r1.correlation_id) AS number_of_bugs
   FROM versions cur, versions base,
   	reports r1, reports r2,
	files f1, files f2,
	correlations c,
	error_names e
  WHERE  r1.file_id = f1.file_id
  AND r2.file_id = f2.file_id
  AND base.version_name::text = f1.version_name::text
  AND cur.version_name::text = f2.version_name::text
  AND r1.correlation_id = r2.correlation_id
  AND r1.correlation_id = c.correlation_id
  AND c.status::text = 'BUG'::text
  AND c.report_error_name=e.report_error_name
  GROUP BY base.version_name,
  	   cur.version_name,
	   cur.release_date,
	   base.release_date,
	   e.standardized_name
  ORDER BY cur.release_date, base.release_date
;

-- compute the complet function size where
-- we have reports
-- DROP VIEW fct_size_of_reports CASCADE;

CREATE OR REPLACE VIEW fct_size_of_reports AS
SELECT report_id,
       function_id,
       version_name,
       finish - start + 1 as fct_size
       FROM reports r, functions f, vfiles v
       WHERE r.file_id = f.file_id
       AND v.file_id = f.file_id
       AND r.line_no between start and finish
;

-- View for hBugs (log. distribution of faults)
--
CREATE OR REPLACE VIEW version_file_report AS
SELECT files.version_name,
       files.file_id,
       error_names.standardized_name AS standardized_report_name
FROM correlations, error_names, files, reports
WHERE correlations.report_error_name = error_names.report_error_name
AND correlations.correlation_id = reports.correlation_id
AND files.file_id = reports.file_id;

--
-- Name: Bugs per category
--
-- DROP VIEW "Bugs per category";

CREATE OR REPLACE VIEW "Bugs per category" AS
    SELECT version_name,
    	   release_date,
    	   standardized_name,
    	   sum(data) AS data
    FROM "Count evol"
    GROUP BY version_name,
    	     release_date,
	     standardized_name;

--
--
--
-- DROP VIEW study_count_evol_agg_kind;

CREATE OR REPLACE VIEW study_count_evol_agg_kind AS
SELECT f.version_name, f.release_date,
       f.study_dirname,
       f.standardized_name,
       coalesce(count(s.*),0) as pts
FROM (SELECT DISTINCT v.version_name, v.release_date, e.standardized_name, d.dirname AS study_dirname
    	 FROM versions v, error_names e, dir_names d) f
LEFT OUTER JOIN
     (SELECT version_name, study_dirname, standardized_name
     FROM "Faults info"
     GROUP BY file_id, version_name, study_dirname, standardized_name) as s
ON  f.version_name      = s.version_name
AND f.study_dirname      = s.study_dirname
AND f.standardized_name = s.standardized_name
GROUP BY f.version_name,
	 f.release_date,
	 f.study_dirname,
	 f.standardized_name;

-- drop VIEW "study_bugs_and_reports_number" ;
CREATE or replace VIEW "study_bugs_and_reports_number" AS
	select r.*, s.total_in_version
from
(select r.release_date,
				r.version_name, 
				r.status,
			  count(*) as number_of_reports
			  from "Reports info" r 
			  where r.standardized_name != 'Real'
			  group by r.version_name, r.status, r.release_date
			  order by r.version_name, r.status) as r,
(select r.version_name, count(*) as total_in_version from "Reports info" r where r.standardized_name != 'Real' group by r.version_name) as s
where r.version_name=s.version_name
order by r.release_date;

create or replace view study_birth_and_death_of_bugs as	
select  b.correlation_id,
				f.file_name,
				f.birth_of_file,
				b.birth_of_bug,
				(select f.death_of_file where f.death_of_file!=last_release_date()) as death_of_file,
				(select b.death_of_bug where b.death_of_bug!=last_release_date()) as death_of_bug
from
(select f.file_name, min(f.release_date) as birth_of_file, max(f.release_date) as death_of_file
from
(select f.file_name, v.release_date, v.version_name
			 from files f, versions v
			 where f.version_name=v.version_name
			 order by f.file_id) as f
group by f.file_name) as f,
(select *
 from
 (select v.correlation_id, v.file_name, min(v.release_date) as birth_of_bug, max(v.release_date) as death_of_bug
 from
 (
 select r.correlation_id, v.version_name, v.release_date, f.file_name
 			 from "Bug ages" c, reports r, files f, versions v
 			 where r.correlation_id=c.correlation_id
 			 and r.file_id=f.file_id
 			 and f.version_name=v.version_name) as v
 group by v.correlation_id, v.file_name
 order by v.correlation_id) as v) as b
where f.file_name=b.file_name;

	
-- usefull to compute the number of lines
-- 	select v.version_name, v.study_dirname, v.sum as loc, w.sum as total, v.sum::numeric/w.sum::numeric as percentage_of_total_loc
-- 	from
-- 	  (select release_date, version_name, study_dirname, sum(file_size) from vfiles group by release_date, version_name, study_dirname) as v,
-- 	  (select version_name, sum(file_size) from vfiles group by version_name) as w
-- 	where v.version_name=w.version_name and v.study_dirname='drivers'
-- 	order by v.release_date, v.study_dirname ;


	