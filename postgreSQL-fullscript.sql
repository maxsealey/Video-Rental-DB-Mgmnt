DROP TABLE IF EXISTS detailed CASCADE;
DROP TABLE IF EXISTS summary CASCADE;

-- Section B: Creates Detailed and Summary Tables
CREATE TABLE detailed (
	rental_id INT PRIMARY KEY, -- rental table
	genre VARCHAR(30), -- category table
	rental_date DATE, -- rental table
	return_date DATE, -- rental_table
	store_id INT -- inventory table
);

CREATE TABLE summary (
	genre VARCHAR(30),
	total_rentals INT
);

-- Section C: Extracts raw data from DB and inserts into detailed table 
INSERT INTO detailed (
	rental_id,
	genre,
	rental_date,
	return_date,
	store_id
)
SELECT r.rental_id, c.name, r.rental_date, r.return_date, i.store_id 
FROM category AS c
INNER JOIN film_category AS fc
ON c.category_id = fc.category_id
INNER JOIN film AS f
ON fc.film_id = f.film_id
INNER JOIN inventory AS i
ON f.film_id = i.film_id
INNER JOIN rental AS r
ON i.inventory_id = r.inventory_id;

-- Section D: Write code for function that performs the transformation
-- update_summary_trigger() - clears and then populates summary table 
-- Uses the COUNT function to aggregate # of rentals for the summary table
-- Extracts data from detailed table and populates summary table
INSERT INTO summary
SELECT genre, COUNT(rental_id)
FROM detailed
GROUP BY genre;

-- Section D: Write code for function that performs the transformation
-- update_summary_trigger() - clears and then populates summary table 
CREATE OR REPLACE FUNCTION update_summary_trigger()
	RETURNS TRIGGER
	LANGUAGE plpgsql
AS $$
BEGIN
	DELETE FROM summary;
	INSERT INTO summary
	SELECT genre, COUNT(rental_id)
	FROM detailed
	GROUP BY genre;
	RETURN New;
END;
$$;

-- Section E: Creates a trigger on the detailed table that will continually update summary table
CREATE TRIGGER update_summary
	AFTER INSERT
	ON detailed
	FOR EACH ROW
	EXECUTE PROCEDURE update_summary_trigger();

--
-- TEST QUERIES
--
-- SELECT COUNT(*) FROM detailed;
-- INSERT INTO detailed VALUES(17000, 'History', '2009-07-02', '2009-07-27', 2);
-- SELECT COUNT(genre) FROM detailed WHERE genre = 'Action';
-- SELECT total_rentals FROM summary WHERE genre = 'Action';
-- SELECT * FROM summary;

DROP TRIGGER IF EXISTS update_summary ON detailed;

-- Section F: Creates a stored procedure that runs on a schedule to ensure data freshness

CREATE OR REPLACE PROCEDURE data_refresh()
LANGUAGE plpgsql
AS $$
BEGIN
	DROP TABLE IF EXISTS detailed;
	DROP TABLE IF EXISTS summary;
	
	CREATE TABLE detailed (
	rental_id INT PRIMARY KEY, -- rental table
	genre VARCHAR(30), -- category table
	rental_date DATE, -- rental table
	return_date DATE, -- rental_table
	store_id INT -- inventory table
);

	CREATE TABLE summary (
		genre VARCHAR(30),
		total_rentals INT
	);
 
	INSERT INTO detailed (
		rental_id,
		genre,
		rental_date,
		return_date,
		store_id
	)
	SELECT r.rental_id, c.name, r.rental_date, r.return_date, i.store_id 
	FROM category AS c
	INNER JOIN film_category AS fc
	ON c.category_id = fc.category_id
	INNER JOIN film AS f
	ON fc.film_id = f.film_id
	INNER JOIN inventory AS i
	ON f.film_id = i.film_id
	INNER JOIN rental AS r
	ON i.inventory_id = r.inventory_id;

	INSERT INTO summary
	SELECT genre, COUNT(rental_id)
	FROM detailed
	GROUP BY genre;
	RETURN;
END;
$$;

-- This procedure should be refreshed once a month for the forseeable future to 
-- accurately map trends in the popularity of specific genres of movies
-- over the course of a year. Once the most popular genres and trends have been identified,
-- decision-makers will be able to tailor how they stock their inventory and which movies to advertise.


CALL data_refresh();