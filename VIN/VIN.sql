
-- VIN Validation
-- https://en.wikipedia.org/wiki/Vehicle_identification_number
--
-- Postgres

--------------------------------------------------------
-- Schema ----------------------------------------------
--------------------------------------------------------

CREATE SCHEMA IF NOT EXISTS vin;

--------------------------------------------------------
-- Cleanup ---------------------------------------------
--------------------------------------------------------

DROP FUNCTION IF EXISTS vin.is_valid_vin;

DROP TABLE IF EXISTS vin.checksum_code;
DROP TABLE IF EXISTS vin.checksum_weight;

--------------------------------------------------------
-- Tables ----------------------------------------------
--------------------------------------------------------

-- checksum_code

CREATE TABLE vin.checksum_code(
	Letter char(1) NOT NULL PRIMARY KEY,
	Code smallint NOT NULL
);

INSERT INTO vin.checksum_code(Letter, Code) VALUES ('A', 1); 	
INSERT INTO vin.checksum_code(Letter, Code) VALUES ('B', 2); 	
INSERT INTO vin.checksum_code(Letter, Code) VALUES ('C', 3); 	
INSERT INTO vin.checksum_code(Letter, Code) VALUES ('D', 4); 	
INSERT INTO vin.checksum_code(Letter, Code) VALUES ('E', 5); 	
INSERT INTO vin.checksum_code(Letter, Code) VALUES ('F', 6); 	
INSERT INTO vin.checksum_code(Letter, Code) VALUES ('G', 7); 	
INSERT INTO vin.checksum_code(Letter, Code) VALUES ('H', 8); 	
INSERT INTO vin.checksum_code(Letter, Code) VALUES ('J', 1); 	
INSERT INTO vin.checksum_code(Letter, Code) VALUES ('K', 2); 	
INSERT INTO vin.checksum_code(Letter, Code) VALUES ('L', 3); 	
INSERT INTO vin.checksum_code(Letter, Code) VALUES ('M', 4); 	
INSERT INTO vin.checksum_code(Letter, Code) VALUES ('N', 5); 	
INSERT INTO vin.checksum_code(Letter, Code) VALUES ('P', 7);
INSERT INTO vin.checksum_code(Letter, Code) VALUES ('R', 9);
INSERT INTO vin.checksum_code(Letter, Code) VALUES ('S', 2); 	
INSERT INTO vin.checksum_code(Letter, Code) VALUES ('T', 3); 	
INSERT INTO vin.checksum_code(Letter, Code) VALUES ('U', 4); 	
INSERT INTO vin.checksum_code(Letter, Code) VALUES ('V', 5); 	
INSERT INTO vin.checksum_code(Letter, Code) VALUES ('W', 6); 	
INSERT INTO vin.checksum_code(Letter, Code) VALUES ('X', 7); 	
INSERT INTO vin.checksum_code(Letter, Code) VALUES ('Y', 8); 	
INSERT INTO vin.checksum_code(Letter, Code) VALUES ('Z', 9);

-- checksum_weight

CREATE TABLE vin.checksum_weight(
	Position smallint NOT NULL,
	Weight smallint NOT NULL
);

INSERT INTO vin.checksum_weight(Position, Weight) VALUES (1, 8);
INSERT INTO vin.checksum_weight(Position, Weight) VALUES (2, 7);
INSERT INTO vin.checksum_weight(Position, Weight) VALUES (3, 6);
INSERT INTO vin.checksum_weight(Position, Weight) VALUES (4, 5);
INSERT INTO vin.checksum_weight(Position, Weight) VALUES (5, 4);
INSERT INTO vin.checksum_weight(Position, Weight) VALUES (6, 3);
INSERT INTO vin.checksum_weight(Position, Weight) VALUES (7, 2);
INSERT INTO vin.checksum_weight(Position, Weight) VALUES (8, 10);
INSERT INTO vin.checksum_weight(Position, Weight) VALUES (9, 0);
INSERT INTO vin.checksum_weight(Position, Weight) VALUES (10, 9);
INSERT INTO vin.checksum_weight(Position, Weight) VALUES (11, 8);
INSERT INTO vin.checksum_weight(Position, Weight) VALUES (12, 7);
INSERT INTO vin.checksum_weight(Position, Weight) VALUES (13, 6);
INSERT INTO vin.checksum_weight(Position, Weight) VALUES (14, 5);
INSERT INTO vin.checksum_weight(Position, Weight) VALUES (15, 4);
INSERT INTO vin.checksum_weight(Position, Weight) VALUES (16, 3);
INSERT INTO vin.checksum_weight(Position, Weight) VALUES (17, 2);

-------------------------------------------------------------------------------
-- Function -------------------------------------------------------------------
-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION vin.is_valid_vin (vin char(17))
RETURNS boolean
LANGUAGE plpgsql
AS
$$
DECLARE 
	return_value boolean = false;
	calculated_check_number char(1);
	check_number_character char(1) = SUBSTRING(vin, 9, 1);
BEGIN

IF LENGTH(vin) = 17
	THEN
		
		WITH RECURSIVE cte_vin
		AS (
			SELECT 1 as position, SUBSTRING(vin, 1, 1) as code
			UNION ALL
			SELECT position + 1 as position, SUBSTRING(vin, (position + 1), 1) as code
			FROM cte_vin
			WHERE position < 17
		)
		SELECT (SUM(CAST(COALESCE(CAST(c.code as char(1)), v.code) as smallint) * w.weight) % 11)
		INTO calculated_check_number
		FROM cte_vin as v
		JOIN vin.checksum_weight as w ON w.position = v.position
		-- If a character is numeric, use that value for the checksum_code value
		LEFT JOIN vin.checksum_code as c ON c.letter = v.code;
		
		SELECT CASE WHEN (check_number_character = (CASE WHEN calculated_check_number = '10' THEN 'X' ELSE calculated_check_number END))
			THEN true ELSE false END
		INTO return_value;

	END IF;

RETURN return_value;

END
$$;

-- Test Function

SELECT vin.is_valid_vin ('1111111111111111'); -- Not correct length
SELECT vin.is_valid_vin ('11111111111111111'); -- Valid
SELECT vin.is_valid_vin ('11111111111111112'); -- Not Valid

