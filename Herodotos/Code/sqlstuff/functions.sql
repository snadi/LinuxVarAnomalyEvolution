

create or replace function get_file (VarChar(256), VarChar(256)) returns int as $$
declare
	version_name ALIAS FOR $1;
	file_name    ALIAS FOR $2;
	res			     int;
begin
	select file_id into res from files f where f.file_name=file_name and f.version_name=version_name;

  return res;

end;
$$ LANGUAGE 'plpgsql';

-- line_no, column_start, column_end, text_link
create or replace function get_position (int, int, int, VarChar(256)) returns int as $$
declare
	line_no      ALIAS FOR $1;
	column_start ALIAS FOR $2;
	column_end   ALIAS FOR $3;
	text_link		 ALIAS FOR $4;
	res			     int;
begin
	select position_id into res from positions p
		where p.line_no=line_no
			and p.column_start=column_start
			and p.column_end=column_end
			and p.text_link=text_link;

  return res;

end;
$$ LANGUAGE 'plpgsql';


-- line_no, column_start, column_end, text_link
create or replace function useful_for_rates (text) returns boolean as $$
begin
	return $1!='Float';
end;
$$ LANGUAGE 'plpgsql';

--
-- Name: get_last_release_date(); Type: FUNCTION; Schema: public;
--

CREATE or replace FUNCTION last_release_date(OUT last date) RETURNS date
    LANGUAGE sql STABLE
    AS $$SELECT max(versions.release_date) AS last FROM versions$$;

CREATE or replace FUNCTION last_release() RETURNS VarChar(256)
    LANGUAGE sql STABLE
    AS
$$
	select version_name from versions where release_date=(select max(release_date) from versions)
$$;

--
-- Name: study_dirname(text); Type: FUNCTION; Schema: public; Owner: npalix
--

CREATE or replace FUNCTION study_dirname(family_name text, type_name text, OUT dir text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT CASE
            WHEN $1 = 'arch'::text THEN 'arch'::text
            WHEN $1 = 'net'::text THEN 'net'::text
            WHEN $1 = 'fs'::text THEN 'fs'::text
            WHEN $1 = 'sound'::text THEN 'sound'::text
            WHEN $1 = 'drivers'::text THEN
               CASE WHEN $2 = 'staging' THEN 'staging'::text
                    ELSE 'drivers'::text
               END
            ELSE 'other'::text
        END AS dir$_$;

--
-- Name: compute_file_name_info(text): returns the different components of the path and the study_dirname as an array
--
create or replace function compute_file_name_info(text) returns text[5] as $$
			 select array[fn.t[1], fn.t[2], fn.t[3], fn.t[4],
							case
            				 when fn.t[1] = 'arch'::text        then 'arch'::text
            				 when fn.t[1] = 'net'::text         then 'net'::text
            				 when fn.t[1] = 'fs'::text          then 'fs'::text
            				 when fn.t[1] = 'sound'::text       then 'sound'::text
            				 when fn.t[1] = 'drivers'::text     then
               			 			case when fn.t[2] = 'staging' then 'staging'::text
                    			else 'drivers'::text
               						end
            				 else 'other'::text
							end]
							from (select fn.t[1:array_upper(fn.t, 1)-1] as t
 			  							 		 from (select regexp_split_to_array($1,'/') as t) as fn) as fn;
$$ LANGUAGE 'SQL';

--
-- Name: add_file_name(text): add a file_name in file_names if it is not yet present
--
create or replace function add_file_name(text) returns text as $$
begin
	if not exists (select * from file_names where file_name=$1) then
		 insert into file_names
		 select $1, t[1], t[2], t[3], t[4], t[5] from compute_file_name_info($1) as t;
  end if;
	return $1;
end;
$$ LANGUAGE 'plpgsql';

--
-- Name: rebuild_file_names(): rebuild all the file_names table without destroying anything
--
create or replace function rebuild_file_names() returns void as $$
begin
	update file_names f
			 set study_dirname=fn.t[5]
			 from 
			 (select file_name, compute_file_name_info(file_name) as t from files group by file_name) as fn
			 where fn.file_name=f.file_name;
end;
$$ LANGUAGE 'plpgsql';

create or replace function do_exp_bucket(idx bigint, nb_buckets int, tot bigint) returns int as $$
declare
	i int;
	f int;
begin
	f := cast(tot/(power(2, nb_buckets) - 1) as integer);
	i=0;

	while i<nb_buckets loop
				if idx >= (tot - (f * (power(2, i+1)-1))) then
					 return nb_buckets - i - 1;
				end if;
				i=i+1;
	end loop;

	return 0;
end
$$ language 'plpgsql';

create or replace function do_lin_bucket(idx bigint, nb_buckets int, tot bigint) returns int as $$
declare
	r int;
begin
	r := cast((nb_buckets * idx) / tot as int);
	if r < nb_buckets then
		 return r;
	end if;
	return nb_buckets-1;
end
$$ language 'plpgsql';
