/**
 * @file create_the_tsp_db_fully.sql
 *
 * @author Samah A. SHAYYA
 *
 * @brief This script creates the tsp_matlab_data database, tables,
 *        procedures, and triggers.
 */

-- Creating the database using dynamic SQL query.
CREATE DATABASE tsp_matlab_data;

-- Switching to the created database.
USE tsp_matlab_data;

-- Creating the 'tsps' table.
CREATE TABLE tsps (
    id INT AUTO_INCREMENT PRIMARY KEY,
    size INT CHECK (size >= 1 AND size <= 25),

    -- Closed-path distance.
    distance FLOAT CHECK (distance >= 0),

    /**
     * All fields below can be dismissed for current application.
     * However, they are kept for teaching purposes here and for
     * later advanced functionalities.
     */

	-- is_optimal: Optimal (TRUE) and near-optimal (FALSE)
    is_optimal BOOLEAN DEFAULT FALSE,

    /*
     * Gives the level of confidence on the optimality of the solution with zero being
     * extremely unconfident and one being fully confident. In case of optimal solution,
     * it should be one and in case of near-optimal solution it should be less than or
     * equal to one (actually less than one).
     */
    confidence FLOAT CHECK (confidence >= 0 AND confidence <= 1),

    -- Below are common fields, and you may add created_by and modified_by (user_id).
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    modified_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Creating the 'points' table.
CREATE TABLE points (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tsp_id INT,
    x FLOAT,
    y FLOAT,

	-- Upper-limit can be dismissed.
    point_order INT CHECK (point_order >= 1 AND point_order <= 25),

    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    modified_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (tsp_id) REFERENCES tsps(id)
);

-- Creating a view to combine 'tsps' and 'points' data.
CREATE VIEW tsp_point_view AS
    SELECT
        t.id AS tsp_id,
        t.size AS tsp_size,
        t.is_optimal AS tsp_is_optimal,
        t.distance AS tsp_distance,
        t.confidence AS tsp_confidence,
        p.id AS point_id,
        p.x AS point_x,
        p.y AS point_y,
        p.point_order AS point_order
    FROM
        tsps t
    JOIN
        points p ON t.id = p.tsp_id
    ORDER BY
        t.id, p.point_order;

-- Defining procedures to validate TSP and point data.

/**
 * Changing delimiter to be able to define procdures, functions, triggers and
 * multi-statment constructs. Do not forget to reset it back to default ';'
 * once done.
 */
DELIMITER $$

CREATE PROCEDURE validate_tsp(IN id INT,
							  IN size INT,
                              IN is_optimal BOOLEAN,
                              IN confidence FLOAT)
BEGIN
	/**
     * Remember that all declarations should be made after BEGIN directly
     * and prior to any executable statement.
     */
    DECLARE max_order INT;

    IF (is_optimal AND confidence < 1) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid TSP parameters!';
    END IF;

    SELECT COALESCE(MAX(point_order), 0) INTO max_order FROM points WHERE tsp_id = id;

    IF max_order > size THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid point order given the TSP size!';
    END IF;
END$$

CREATE PROCEDURE validate_point(IN tsp_id INT, IN point_order INT)
BEGIN
    DECLARE tsp_size INT;

    SELECT size INTO tsp_size FROM tsps WHERE id = tsp_id;

    IF point_order > tsp_size THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid point order!';
    END IF;
END$$

-- Creating triggers to call the validation procedures.
CREATE TRIGGER validate_tsp_insertion BEFORE INSERT ON tsps
FOR EACH ROW BEGIN
    CALL validate_tsp(NEW.id, NEW.size, NEW.is_optimal, NEW.confidence);
END$$

CREATE TRIGGER validate_tsp_update BEFORE UPDATE ON tsps
FOR EACH ROW BEGIN
    CALL validate_tsp(NEW.id, NEW.size, NEW.is_optimal, NEW.confidence);
END$$

CREATE TRIGGER validate_point_insertion BEFORE INSERT ON points
FOR EACH ROW BEGIN
    CALL validate_point(NEW.tsp_id, NEW.point_order);
END$$

CREATE TRIGGER validate_point_update BEFORE UPDATE ON points
FOR EACH ROW BEGIN
    CALL validate_point(NEW.tsp_id, NEW.point_order);
END$$

-- Reset back delimiter to ';'
DELIMITER ;
