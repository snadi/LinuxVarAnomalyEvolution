SELECT
 files.file_name,
 min(files.version_name) AS firstversion,
 max(files.version_name) AS lastversion,
 (SELECT line_no
  FROM reports
  WHERE reports.file_id = get_file(min(files.version_name), files.file_name)
  LIMIT 1)
FROM files, reports
WHERE files.file_id = reports.file_id
GROUP BY correlation_id, file_name;

SELECT
  correlations.correlation_id AS defect_no,
  array_sort_unique(array_agg(report_error_name)) AS classification,
  array_sort_unique(array_agg(files.file_name)) AS filename,
  min(files.version_name) AS firstversion,
  max(files.version_name) AS lastversion,
  (SELECT line_no
   FROM reports, files
   WHERE
       reports.file_id = files.file_id
     AND
       reports.correlation_id = correlations.correlation_id
   ORDER BY files.version_name ASC
   LIMIT 1) AS line_in_first_version
FROM
  correlations,
  files,
  reports
WHERE
    correlations.correlation_id = reports.correlation_id
  AND
    reports.file_Id = files.file_id
GROUP BY
  correlations.correlation_id;

CREATE OR REPLACE FUNCTION array_sort_unique (ANYARRAY) RETURNS ANYARRAY
LANGUAGE SQL
AS $body$
  SELECT ARRAY(
    SELECT DISTINCT $1[s.i]
    FROM generate_series(array_lower($1,1), array_upper($1,1)) AS s(i)
    ORDER BY 1
  );
$body$;
