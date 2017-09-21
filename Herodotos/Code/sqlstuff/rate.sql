
create or replace function study_nb_buckets() returns int
    language sql STABLE
    as $$select 6$$;

create or replace function study_rate_version() returns VarChar(256)
    language sql STABLE
    as
--	  	$$select 'linux-2.4.1'::VarChar(256)$$;
			$$select last_release()$$;

create or replace function study_do_bucket(idx bigint, nb_buckets int, tot bigint) returns int as $$
begin
	return do_exp_bucket(idx, nb_buckets, tot);
end
$$ language 'plpgsql';

--
-- Name: study_cmp_rate_by_directory_and_error_name
--
-- DROP VIEW study_cmp_rate_by_directory_and_error_name;

CREATE OR REPLACE VIEW study_cmp_rate_by_directory_and_error_name AS
    SELECT r.version_name,
    	   r.standardized_name,
	   r.study_dirname AS dirname,
	   sum(r.number_of_reports)::float / sum(r.number_of_notes)::float AS rate_dir,
	   sum(ro.number_of_reports)::float / sum(ro.number_of_notes)::float AS rate_other,
	   ((sum(r.number_of_reports)::float / sum(r.number_of_notes)::float) / (NULLIF(sum(ro.number_of_reports)::float,0) / sum(ro.number_of_notes)::float)) AS rate

FROM rates_per_dir r, rates_per_dir ro
WHERE r.study_dirname <> ro.study_dirname
AND r.version_name = ro.version_name
AND r.standardized_name = ro.standardized_name
GROUP BY r.version_name, r.standardized_name, r.study_dirname;

-- DROP VIEW study_rate_by_directory;

create or replace view study_rate_by_directory as
SELECT r.version_name,
       r.study_dirname AS dirname,
       100 * sum(r.number_of_reports) / sum(r.number_of_notes) AS rate
   FROM rates r, versions v
  WHERE v.version_name = r.version_name
  GROUP BY study_dirname, r.version_name, v.release_date
  ORDER BY v.release_date, sum(r.number_of_reports) / sum(r.number_of_notes) DESC;

-- DROP VIEW study_rate_by_directory_and_error_name;

CREATE OR REPLACE VIEW study_rate_by_directory_and_error_name AS
       SELECT version_name,
       	      standardized_name,
	      study_dirname AS dirname,
	      100 * sum(number_of_reports) / sum(number_of_notes) AS rate
       FROM  rates r
       GROUP BY version_name, standardized_name, study_dirname;

-- DROP VIEW study_rate_by_directory_4_x386;

CREATE OR REPLACE VIEW study_rate_by_directory_4_x386 AS
       SELECT f.version_name,
	      r.study_dirname AS dirname,
       	      f.def_compiled,
	      100 * sum(r.number_of_reports) / sum(r.number_of_notes) AS rate
       FROM files f, rates r
       WHERE r.file_id = f.file_id
       AND f.file_name LIKE '%.c'
       GROUP BY f.version_name, r.study_dirname, f.def_compiled;

-- DROP VIEW study_rate_by_directory_4_x386_allyes;

CREATE OR REPLACE VIEW study_rate_by_directory_4_x386_allyes AS
       SELECT f.version_name,
	      r.study_dirname AS dirname,
       	      f.allyes_compiled,
	      100 * sum(r.number_of_reports) / sum(r.number_of_notes) AS rate
       FROM files f, rates r
       WHERE r.file_id = f.file_id
       AND f.file_name LIKE '%.c'
       GROUP BY f.version_name, r.study_dirname, f.allyes_compiled;

-- DROP VIEW study_rate_by_error_name_4_x386;

CREATE OR REPLACE VIEW study_rate_by_error_name_4_x386 AS
       SELECT f.version_name,
       	      r.standardized_name,
       	      f.def_compiled,
	      100 * sum(r.number_of_reports) / sum(r.number_of_notes) AS rate
       FROM files f, rates r
       WHERE r.file_id = f.file_id
       AND f.file_name LIKE '%.c'
       GROUP BY f.version_name, r.standardized_name, f.def_compiled;

-- DROP VIEW study_rate_by_error_name_4_x386_allyes;

CREATE OR REPLACE VIEW study_rate_by_error_name_4_x386_allyes AS
       SELECT f.version_name,
       	      r.standardized_name,
       	      f.allyes_compiled,
	      100 * sum(r.number_of_reports) / sum(r.number_of_notes) AS rate
       FROM files f, rates r
       WHERE r.file_id = f.file_id
       AND f.file_name LIKE '%.c'
       GROUP BY f.version_name, r.standardized_name, f.allyes_compiled;

-- DROP VIEW study_rate_by_churn;

create or replace view study_rate_by_churn as
select b.bucket,
       r.standardized_name,
       a.average_churn,
	     a.min_churn,
		   a.max_churn,
	     a.nb_files_per_bucket,
       cast(100 * sum(r.number_of_reports) as numeric)/sum(r.number_of_notes) as rate,
       sum(r.number_of_reports) as number_of_reports,
       sum(r.number_of_notes) as number_of_notes
       from
        (select f.*,
                study_do_bucket(row_number() over (order by file_churn), study_nb_buckets(), t.tot) as bucket
                from
                     file_churns f,
                      (select count(*) as tot
                               from file_churns
                              where version_name=study_rate_version()) as t
                 where f.version_name=study_rate_version()) as b,
        (select b.bucket,
								avg(b.file_churn) as average_churn,
								min(b.file_churn) as min_churn,
								max(b.file_churn) as max_churn,
								count(b.file_id)    as nb_files_per_bucket
                from (select f.*,
                              study_do_bucket(row_number() over (order by file_churn), study_nb_buckets(), t.tot) as bucket
                             from
                                   file_churns f,
                                    (select count(*) as tot
                                           from file_churns
                                          where version_name=study_rate_version()) as t
                             where f.version_name=study_rate_version()) as b
                group by b.bucket) as a,
        rates r
      where b.file_id=r.file_id
        and a.bucket=b.bucket
      group by b.bucket, r.standardized_name, a.average_churn, a.min_churn, a.max_churn, a.nb_files_per_bucket
      order by r.standardized_name, b.bucket;


-- DROP VIEW study_rate_by_age;

-- To have other metric you can replace 'file_age_in_years'
-- by either 'file_age_in_months' or 'file_age_in_days'

create or replace view study_rate_by_age as
select b.bucket,
       r.standardized_name,
       a.average_age,
       a.min_age,
       a.max_age,
			 a.nb_files_per_bucket,
       cast(100 * sum(r.number_of_reports) as numeric)/sum(r.number_of_notes) as rate,
       sum(r.number_of_reports) as number_of_reports,
       sum(r.number_of_notes) as number_of_notes
  from (select f.file_id,
               study_do_bucket(row_number() over (order by file_age_in_years), study_nb_buckets(), t.tot) as bucket
           from files f,
               file_ages fa,
                (select count(*) as tot
                   from file_ages
                   where version_name=study_rate_version()) as t
           where f.version_name=study_rate_version()
             and fa.file_name = f.file_name
             and fa.version_name = f.version_name) as b,
       (select b.bucket,
							 avg(b.file_age_in_years) as average_age,
							 min(b.file_age_in_years) as min_age,
							 max(b.file_age_in_years) as max_age,
							 count(b.file_id) as nb_files_per_bucket
           from (select f.file_id,
                         fa.file_age_in_years,
                       study_do_bucket(row_number() over (order by file_age_in_years), study_nb_buckets(), t.tot) as bucket
                  from files f,
                       file_ages fa,
                        (select count(*) as tot
                           from file_ages
                          where version_name=study_rate_version()) as t
                  where f.version_name=study_rate_version()
                    and fa.file_name = f.file_name
                    and fa.version_name = f.version_name) as b
                  group by b.bucket) as a,
       rates r
  where b.file_id=r.file_id
    and a.bucket=b.bucket
  group by b.bucket, r.standardized_name, a.average_age, a.min_age, a.max_age, a.nb_files_per_bucket
  order by r.standardized_name, b.bucket;

-- DROP VIEW study_rate_by_fct_size;

create or replace view study_rate_by_fct_size as
select b.bucket,
       r.standardized_name,
       a.average_length as average_fct_size,
			 a.min_length as min_fct_size,
			 a.max_length as max_fct_size,
			 a.nb_functions_per_bucket,
       cast(100 * sum(r.number_of_reports) as numeric)/sum(r.number_of_notes) as rate,
       sum(r.number_of_reports) as number_of_reports,
       sum(r.number_of_notes) as number_of_notes
       from
        (select func.*,
                study_do_bucket(row_number() over (order by len), study_nb_buckets(), t.tot) as bucket
            from (select *, finish - start as len from functions) as func,
                 files f,
                 (select count(*) as tot
                   from functions func,
                         files f
                  where f.version_name=study_rate_version()
                    and func.file_id=f.file_id) as t -- total number of function in version study_rate_version
           where f.version_name=study_rate_version() and f.file_id=func.file_id) as b, -- associates a function with a bucket
        (select b.bucket,
								avg(b.len) as average_length,
								min(b.len) as min_length,
								max(b.len) as max_length,
								count(b.function_id) as nb_functions_per_bucket
            from (select func.*,
                          study_do_bucket(row_number() over (order by len), study_nb_buckets(), t.tot) as bucket
                     from (select *, finish - start as  len from functions) as func,
                          files f,
                         (select count(*) as tot
                           from functions func, files f
                          where f.version_name=study_rate_version() and func.file_id=f.file_id) as t
                    where f.version_name=study_rate_version() and f.file_id=func.file_id) as b -- idem, associates a function with a bucket
           group by b.bucket) as a, -- associate a bucket with the average length of the functions in the bucket
        (select n.function_id, n.standardized_name, coalesce(r.number_of_reports, 0) as number_of_reports, n.number_of_notes
                from (select func.function_id,
                                r.standardized_name,
                               count(*) as number_of_reports
                        from report_with_notes r, functions func, files f
                         where r.file_id=func.file_id
                          and f.file_id=r.file_id
                          and f.version_name=study_rate_version()
                           and r.line_no between func.start and func.finish
                           and r.status='BUG'
                         group by func.function_id, r.standardized_name) as r   -- number of reports for each function
                right outer join
                     (select func.function_id,
                              n.standardized_name,
                             count(*) as number_of_notes
                         from standardized_notes n, functions func, files f
                        where n.file_id=func.file_id
                         and f.file_id=n.file_id
                         and f.version_name=study_rate_version()
                          and n.line_no between func.start and func.finish
                        group by func.function_id, n.standardized_name) as n  -- number of notes for each function
                 on  n.function_id=r.function_id
                 and n.standardized_name=r.standardized_name
                 and useful_for_rates(n.standardized_name)) as r -- gives the number of reports/notes per function and standardized_name
        where a.bucket=b.bucket
          and b.function_id=r.function_id
        group by b.bucket, r.standardized_name, a.average_length, a.min_length, a.max_length, a.nb_functions_per_bucket
        order by r.standardized_name, b.bucket;
	
create or replace view study_total_rate_by_churn as
			 select bucket, 
			 				average_churn,
							min_churn,
							max_churn,
	            nb_files_per_bucket,
							cast(100 * sum(number_of_reports) as numeric)/sum(number_of_notes) as rate, 
							sum(number_of_reports) as number_of_reports, 
							sum(number_of_notes) as number_of_notes 
				 from study_rate_by_churn 
				 group by bucket, average_churn, min_churn, max_churn, nb_files_per_bucket
				 order by bucket;

create or replace view study_total_rate_by_age as
			 select bucket, 
			 				average_age, 
			 				min_age, 
			 				max_age,
	            nb_files_per_bucket,
							cast(100 * sum(number_of_reports) as numeric)/sum(number_of_notes) as rate, 
							sum(number_of_reports) as number_of_reports, 
							sum(number_of_notes) as number_of_notes 
				 from study_rate_by_age 
				 group by bucket, average_age, min_age, max_age, nb_files_per_bucket
				 order by bucket;
	
create or replace view study_total_rate_by_fct_size as
			 select bucket, 
			 				average_fct_size,
							min_fct_size,
							max_fct_size,
	            nb_functions_per_bucket,
							cast(100 * sum(number_of_reports) as numeric)/sum(number_of_notes) as rate, 
							sum(number_of_reports) as number_of_reports, 
							sum(number_of_notes) as number_of_notes 
				 from study_rate_by_fct_size 
				 group by bucket, average_fct_size, min_fct_size, max_fct_size, nb_functions_per_bucket
				 order by bucket;

--
--
--
-- DROP VIEW faults_per_churn;

CREATE OR REPLACE VIEW faults_per_churn AS
       SELECT b.version_name,
       	      b.birth_date,
	      count(b.report_id) AS nb_faults,
--	      n.nb_notes,
       	      m.nb_mods,
	      count(b.report_id)::float / a.release_length AS norm_faults,
--	      (count(b.report_id)::float / n.nb_notes) / a.release_length AS norm_flt_rate,
       	      m.nb_mods::float  / a.release_length AS norm_mods,
	      100 * count(b.report_id)::float / m.nb_mods::float AS rate_pct
       FROM "Birth of reports" b, "Release age" a,
--        	    (SELECT version_name, count(note_id) AS nb_notes
-- 	    FROM "Notes info"
-- 	    GROUP BY version_name
-- 	    ) AS n,
       	    (SELECT version_name, sum(nb_mods) AS nb_mods
	    FROM files
	    GROUP BY version_name
	    ) AS m
       WHERE b.version_name = m.version_name
       AND b.version_name = a.version_name
--       AND b.version_name = n.version_name
       AND b.status = 'BUG'
       AND birth_date > '2003-12-18'
       GROUP BY b.version_name,
       	     	b.birth_date,
		a.release_length,
--		n.nb_notes,
		m.nb_mods
       ORDER BY b.birth_date;


--
-- Name: deaths_churn
--
-- DROP VIEW deaths_churn;

CREATE OR REPLACE VIEW deaths_churn AS

SELECT v.version_name,
       v.release_date,
       COALESCE ( d.deaths , 0 ) AS deaths,
       m.nb_mods,
       COALESCE ( d.deaths , 0 )::float / v.release_length AS norm_deaths,
       m.nb_mods::float  / v.release_length AS norm_mods
FROM  	    (SELECT version_name, sum(nb_mods) AS nb_mods
	    FROM files
	    GROUP BY version_name
	    ) AS m,
	    "Release age" v
LEFT OUTER JOIN (
     SELECT max AS release_date , count ( * ) AS deaths
     FROM report_ages GROUP BY max ) as d
ON v.release_date = d.release_date
WHERE v.release_date > '2003-12-18'
AND v.release_date < '2010-02-24'
AND v.version_name = m.version_name
ORDER BY v.release_date;
