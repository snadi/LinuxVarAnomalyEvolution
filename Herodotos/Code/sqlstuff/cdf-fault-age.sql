

--
-- Name: study_bug_life
--
-- DROP VIEW study_bug_life

-- CREATE OR REPLACE VIEW study_bug_life AS
-- select c1.correlation_id,
-- 			 c1.file_name, -- useless but it helps for debug
-- 			 c1.birth,
-- 			 c2.death
-- 	 from
-- 			(select c.correlation_id,
-- 							f.file_name,
-- 			 				min(v.release_date) as birth
-- 				from
-- 							correlations c,
-- 			        reports r,
-- 			  			files f,
-- 			 				versions v
--   			where 
-- 			 				c.correlation_id = r.correlation_id
--  				 and  r.file_id = f.file_id
-- 				 and  f.version_name = v.version_name
-- 				group by
-- 							c.correlation_id, f.file_name) as c1,
-- 			(select c.correlation_id,
-- 			 				max(v.next_release_date) as death
-- 				from
-- 							correlations c,
-- 			 				reports r,
-- 			 				files f,
-- 			 				"Release age" v
--   			where 
-- 			 				c.correlation_id = r.correlation_id
--  					and r.file_id = f.file_id
-- 					and f.version_name = v.version_name
-- 					group by
-- 								c.correlation_id) as c2
-- 		where
-- 		  c1.correlation_id = c2.correlation_id
-- 		order by
-- 			c1.birth;

--
-- Name: study_bug_life_distribution
--
-- DROP VIEW study_bug_life_distribution
CREATE OR REPLACE VIEW study_bug_life_distribution AS
select 
			 count(*) as number_of_bugs,
			 s.max - s.min as life_in_days
	from "Bug ages" s
	group by life_in_days
	order by life_in_days;

--
-- Name: study_bug_life_cummulative_distribution
--
-- DROP VIEW study_bug_life_cummumative_distribution
CREATE OR REPLACE VIEW study_bug_life_cummulative_distribution AS
select d1.life_in_days,
			 sum(d2.number_of_bugs) as commulative_number_of_resolved_bugs
	from
		study_bug_life_distribution d1,
		study_bug_life_distribution d2
	where
		d2.life_in_days<=d1.life_in_days
	group by
		d1.life_in_days
	order by
		d1.life_in_days;

--
-- Name: study_bug_life_cummulative_distribution_in_month
--
-- DROP VIEW study_bug_life_cummumative_distribution_in_month
create or replace view study_bug_life_cummulative_distribution_in_month as
select
			d1.life_in_month,
			sum(d2.number_of_bugs) as commulative_number_of_resolved_bugs
	from
				(select    count(*) as number_of_bugs,
			  				   ceil((s.max - s.min)::numeric / 30.5) as life_in_month
					 from    "Bug ages" s
					group by life_in_month) as d1,
				(select    count(*) as number_of_bugs,
			  				   ceil((s.max - s.min)::numeric / 30.5) as life_in_month
					 from    "Bug ages" s
					group by life_in_month) as d2
	where
		d2.life_in_month<=d1.life_in_month
	group by
		d1.life_in_month
	order by
		d1.life_in_month;

create or replace view study_bug_life_cummulative_distribution_by_dir_in_day as
select
			d1.study_dirname,
			d1.life_in_day,
			sum(d2.number_of_bugs) as commulative_number_of_resolved_bugs
	from
				(select    count(*) as number_of_bugs,
									 study_dirname,
			  				   s.max - s.min as life_in_day
					 from    "Bug ages" s
					group by life_in_day, study_dirname) as d1,
				(select    count(*) as number_of_bugs,
									 study_dirname,
			  				   s.max - s.min as life_in_day
					 from    "Bug ages" s
					group by life_in_day, study_dirname) as d2
	where
		d2.life_in_day<=d1.life_in_day and d1.study_dirname=d2.study_dirname
	group by
		d1.life_in_day, d1.study_dirname
	order by
		d1.study_dirname, d1.life_in_day;

create or replace view study_bug_life_cummulative_distribution_by_dir_in_month as
select
			d1.study_dirname,
			d1.life_in_month,
			sum(d2.number_of_bugs) as commulative_number_of_resolved_bugs
	from
				(select    count(*) as number_of_bugs,
									 study_dirname,
			  				   ceil((s.max - s.min)::numeric / 30.5) as life_in_month
					 from    "Bug ages" s
					group by life_in_month, study_dirname) as d1,
				(select    count(*) as number_of_bugs,
									 study_dirname,
			  				   ceil((s.max - s.min)::numeric / 30.5) as life_in_month
					 from    "Bug ages" s
					group by life_in_month, study_dirname) as d2
	where
		d2.life_in_month<=d1.life_in_month and d1.study_dirname=d2.study_dirname
	group by
		d1.life_in_month, d1.study_dirname
	order by
		d1.study_dirname, d1.life_in_month;

	
create or replace view study_bug_life_month_where_half_of_the_bugs_are_corrected as
select b.study_dirname, b.life_in_month, c.min as corrected, c.max as total, c.min/c.max as pct
from
(select b.study_dirname, min(b.commulative_number_of_resolved_bugs), max(b.commulative_number_of_resolved_bugs)
from
	 study_bug_life_cummulative_distribution_by_dir_in_month b,
	 (select study_dirname, max(commulative_number_of_resolved_bugs) 
      from study_bug_life_cummulative_distribution_by_dir_in_month
		group by study_dirname) as c
where b.commulative_number_of_resolved_bugs>=c.max/2 and b.study_dirname=c.study_dirname
group by b.study_dirname
order by b.study_dirname) as c,
study_bug_life_cummulative_distribution_by_dir_in_month b
where c.study_dirname=b.study_dirname and b.commulative_number_of_resolved_bugs=c.min
;