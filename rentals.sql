/*B.  Provide original code for function(s) in text format that perform the transformation(s) you identified in part A4.
At first I overcomplicated this in my head and tried to create a case statement for each month. It wasn't working well and then I remembered that there are conversion functions for time.*/

CREATE OR REPLACE FUNCTION month_string(payment_date TIMESTAMP)
RETURNS VARCHAR(9)
LANGUAGE plpgsql
AS
$$
DECLARE month_return VARCHAR(9);
BEGIN
  SELECT to_char(payment_date, 'Month') INTO month_return;
  RETURN month_return;
END;
$$
 
/*C.  Provide original SQL code in a text format that creates the detailed and summary tables to hold your report table sections. 
*/

CREATE TABLE rental_summary (
  staff_id INT,
  staff_name VARCHAR(45),
  month VARCHAR(9),
  total_rentals INT,
  PRIMARY KEY(staff_id, month),
  FOREIGN KEY(staff_id)
    REFERENCES staff (staff_id)
);
 
CREATE TABLE rental_details (
  film_id INT,
  month VARCHAR(9), 
  staff_id INT,
  staff_name VARCHAR(45), 
  film_title VARCHAR(255),
  count_rentals INT,
  PRIMARY KEY (film_id, month, staff_id),
  FOREIGN KEY (film_id)
    REFERENCES film (film_id),
  FOREIGN KEY (staff_id)
    REFERENCES staff (staff_id)
);
 
 
/*D.  Provide an original SQL query in a text format that will extract the raw data needed for the detailed section of your report from the source database. 
*/

INSERT INTO rental_details 
SELECT 	i.film_id, month_string(r.rental_date), r.staff_id, s.last_name, f.title, COUNT(r.inventory_id)
FROM rental AS r
LEFT JOIN inventory AS i 
ON r.inventory_id = i.inventory_id
INNER JOIN film AS f 
ON i.film_id = f.film_id
INNER JOIN staff AS s
ON r.staff_id = s.staff_id
WHERE r.rental_date BETWEEN '07/01/2005 00:00:00' AND '08/31/2005 23:59:59'
GROUP BY month_string(r.rental_date), r.staff_id, s.last_name, i.film_id, f.title
ORDER BY month_string(r.rental_date), r.staff_id, COUNT(r.inventory_id) DESC;
 
 
/*E.  Provide original SQL code in a text format that creates a trigger on the detailed table of the report that will continually update the summary table as data is added to the detailed table. 
*/

CREATE OR REPLACE FUNCTION insert_trigger_function()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  DELETE FROM rental_summary;
  INSERT INTO rental_summary
  SELECT staff_id, staff_name, month, SUM(count_rentals)
  FROM rental_details
  GROUP BY month, staff_id, staff_name
  ORDER BY month, staff_id;
  RETURN NEW;
END;
$$
 
 
CREATE TRIGGER new_summary
AFTER INSERT
ON rental_details
FOR EACH STATEMENT
EXECUTE PROCEDURE insert_trigger_function();
 
/*F.  Provide an original stored procedure in a text format that can be used to refresh the data in both the detailed table and summary table. The procedure should clear the contents of the detailed table and summary table and perform the raw data extraction from part D. 
*/

CREATE OR REPLACE PROCEDURE refresh_tables()
LANGUAGE plpgsql
AS $$
BEGIN
  DELETE FROM rental_details;
  INSERT INTO rental_details 
  SELECT 	i.film_id, month_string(r.rental_date), r.staff_id, s.last_name, f.title, COUNT(r.inventory_id)
  FROM rental AS r
  LEFT JOIN inventory AS i 
  ON r.inventory_id = i.inventory_id
  INNER JOIN film AS f 
  ON i.film_id = f.film_id
  INNER JOIN staff AS s
  ON r.staff_id = s.staff_id
  WHERE r.rental_date BETWEEN '07/01/2005 00:00:00' AND '08/31/2005 23:59:59'
  GROUP BY month_string(r.rental_date), r.staff_id, s.last_name, i.film_id, f.title
  ORDER BY month_string(r.rental_date), r.staff_id, COUNT(r.inventory_id) DESC;
  --The rental_summary table will be cleared and and refreshed automatically with the trigger.
  RETURN;
END;
$$
 
CALL refresh_tables();
 
SELECT * FROM rental_summary;
SELECT * FROM rental_details;
