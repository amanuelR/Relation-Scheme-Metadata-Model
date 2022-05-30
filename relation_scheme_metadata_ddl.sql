/*
    Relation Scheme Metadata Homework DDL, Triggers, and Procedures
*/

/* DDL for models table */
CREATE TABLE models(
    name varchar(50) not null primary key,
    description text not null,
    creation_date date not null
);

/* DDL for relation_scheme table */
CREATE TABLE relation_schemes(
    name varchar(50) not null,
    model_name varchar(50) not null,
    description text not null,
    CONSTRAINT pk_relation_schemes PRIMARY KEY (name,model_name),
    CONSTRAINT fk_relation_schemes FOREIGN KEY (model_name) REFERENCES models(name)
);

/* DDL for attributes table */
CREATE TABLE attributes(
    name varchar(60) not null,
    relation_scheme_name varchar(50) not null,
    model_name varchar(50) not null,
    description text not null,
    CONSTRAINT pk_attributes PRIMARY KEY (name,relation_scheme_name,model_name),
    CONSTRAINT fk_attributes_schemes FOREIGN KEY (relation_scheme_name) REFERENCES relation_schemes(name),
    CONSTRAINT fk_attributes_models FOREIGN KEY (model_name) REFERENCES models(name)
);

/* DDL for decimals table */
CREATE TABLE decimals(
    attribute_name varchar(60) not null,
    relation_scheme_name varchar(50) not null,
    model_name varchar(50) not null,
    decimal_precision INTEGER not null,
    decimal_scale INTEGER not null,
    CONSTRAINT pk_decimals PRIMARY KEY (attribute_name,relation_scheme_name,model_name),
    CONSTRAINT fk_decimals_attributes FOREIGN KEY (attribute_name,relation_scheme_name,model_name) REFERENCES attributes(name,relation_scheme_name,model_name),
    CONSTRAINT decimal_precision_check CHECK (decimal_precision > decimal_scale AND decimal_precision < 66),
    CONSTRAINT decimal_scale_check CHECK ( decimal_scale > 0 AND decimal_scale <= decimal_precision )
);
/* DDL for varchars table */
CREATE TABLE varchars(
    attribute_name varchar(60) not null,
    relation_scheme_name varchar(50) not null,
    model_name varchar(50) not null,
    length int not null,
    CONSTRAINT pk_varchars PRIMARY KEY (attribute_name,relation_scheme_name,model_name),
    CONSTRAINT fk_varchars FOREIGN KEY (attribute_name,relation_scheme_name,model_name) REFERENCES attributes(name,relation_scheme_name,model_name),
    CONSTRAINT varchars_length_check CHECK ( length > 0 AND length <= 65535)
);
/* DDL for data_types table */
CREATE TABLE data_types(
    name varchar(20) not null primary key
);
/* DDL for others table */
CREATE TABLE others(
    attribute_name varchar(60) not null,
    relation_scheme_name varchar(50) not null,
    model_name varchar(50) not null,
    data_type_name varchar(20) not null,
    CONSTRAINT pk_data_types PRIMARY KEY (attribute_name,relation_scheme_name,model_name),
    CONSTRAINT fk_data_types FOREIGN KEY (attribute_name,relation_scheme_name,model_name) REFERENCES attributes(name,relation_scheme_name,model_name)
);

/* DDL for candidate_keys table */
CREATE TABLE candidate_keys(
    name varchar(30) not null,
    model_name varchar(50) not null,
    relation_scheme_name varchar(50) not null,
    CONSTRAINT pk_candidate_keys PRIMARY KEY (name,model_name),
    CONSTRAINT fk_candidate_keys_models FOREIGN KEY (model_name) REFERENCES models(name),
    CONSTRAINT fk_candidate_keys_schemes FOREIGN KEY (relation_scheme_name,model_name) REFERENCES relation_schemes(name,model_name)
);

/* DDL for unique_columns table */
CREATE TABLE unique_columns(
    attribute_name varchar(60) not null,
    model_name varchar(50) not null,
    relation_scheme_name varchar(50) not null,
    candidate_key_name varchar(30) not null,
    ordering_index int not null,
    CONSTRAINT unique_columns_unique_key UNIQUE (model_name,relation_scheme_name,candidate_key_name,ordering_index),
    CONSTRAINT unique_columns_keys PRIMARY KEY (attribute_name,model_name,relation_scheme_name,candidate_key_name),
    CONSTRAINT fk_unique_columns_attributes FOREIGN KEY (attribute_name,relation_scheme_name,model_name) REFERENCES attributes(name,relation_scheme_name,model_name),
    CONSTRAINT fk_unique_columns_candidate_keys FOREIGN KEY (candidate_key_name,model_name) REFERENCES candidate_keys(name,model_name)
);
/* DDL for primary_keys table */
CREATE TABLE primary_keys(
    candidate_key_name varchar(30) not null,
    model_name varchar(50) not null,
    relation_scheme_name varchar(50) not null,
    CONSTRAINT pk_primary_keys PRIMARY KEY (relation_scheme_name,model_name),
    CONSTRAINT fk_primary_keys_ck FOREIGN KEY (candidate_key_name,model_name) REFERENCES candidate_keys(name,model_name),
    CONSTRAINT fk_primary_keys_scheme FOREIGN KEY (relation_scheme_name,model_name) REFERENCES relation_schemes(name,model_name)
);
/* DDL for foreign_keys table */
CREATE TABLE foreign_keys(
    name varchar(30) not null,
    model_name varchar(50) not null,
    relation_scheme_name varchar(50) not null,
    CONSTRAINT pk_primary_keys PRIMARY KEY (name,relation_scheme_name,model_name),
    CONSTRAINT fk_foreign_keys_primary_keys FOREIGN KEY (relation_scheme_name,model_name) REFERENCES primary_keys(relation_scheme_name,model_name),
    CONSTRAINT fk_foreign_keys_scheme FOREIGN KEY (relation_scheme_name,model_name) REFERENCES relation_schemes(name,model_name)
);
/* DDL for attribute_foreign_keys table */
CREATE TABLE attribute_foreign_keys(
    attribute_name varchar(60) not null,
    attribute_name_child varchar(60) not null,
    model_name varchar(50) not null,
    relation_scheme_name varchar(50) not null,
    relation_scheme_name_child varchar(50) not null,
    candidate_key_name varchar(30) not null,
    foreign_keys_name varchar(30) not null,
    ordering_index int not null,
    CONSTRAINT unique_attribute_foreign_keys UNIQUE (attribute_name,relation_scheme_name,model_name,candidate_key_name),
    CONSTRAINT pk_attribute_foreign_keys PRIMARY KEY (attribute_name_child,model_name,relation_scheme_name_child,foreign_keys_name),
    CONSTRAINT fk_attr_foreign_keys_unique_columns FOREIGN KEY (attribute_name,model_name ,relation_scheme_name,candidate_key_name) REFERENCES unique_columns(attribute_name,model_name,relation_scheme_name,candidate_key_name),
    CONSTRAINT fk_attr_foreign_keys_btn_foreign_keys FOREIGN KEY (foreign_keys_name,relation_scheme_name_child,model_name) REFERENCES foreign_keys(name,relation_scheme_name,model_name),
    CONSTRAINT fk_attr_foreign_keys_attributes_child FOREIGN KEY (attribute_name_child,relation_scheme_name_child,model_name) REFERENCES attributes(name,relation_scheme_name,model_name)

);
/*
   A Trigger that checks if a given primary key which also
   a candidate key belongs to the same relation scheme that
   the candidate key belongs to
 */
DELIMITER //
CREATE TRIGGER primary_keys_before_insert
    BEFORE INSERT ON primary_keys FOR EACH ROW
    BEGIN
        IF EXISTS(SELECT 'CK'
                  FROM candidate_keys
                  WHERE name = NEW.candidate_key_name
                        AND relation_scheme_name = NEW.relation_scheme_name AND
                            model_name = NEW.model_name) <> TRUE THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error, the primary key should belong to the same relation_scheme with candidate_key.';
        END IF;
    END //
DELIMITER ;

/*
    A trigger to enforce the business rule that a relation_scheme name is unique within it's model
*/
DELIMITER //
CREATE TRIGGER relation_scheme_before_insert
    BEFORE INSERT ON relation_schemes FOR EACH ROW
    BEGIN
        IF EXISTS(SELECT 'R'
                  FROM relation_schemes
                  WHERE name = NEW.name
                        AND model_name = NEW.model_name) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error, the relation_scheme_name should be unique within its model.';
        END IF;
    END //
DELIMITER ;

/*
   A function that returns the data_type of a given attribute
   @param model: name of the model
          relation_scheme: name of the relation scheme
          attribute_name
 */
DELIMITER //
CREATE FUNCTION get_attribute_type(model varchar(50),scheme varchar(50),attr_name varchar(60))
RETURNS varchar(20)
BEGIN
    IF EXISTS(SELECT 'X'
              FROM decimals
              WHERE model_name = model AND relation_scheme_name = scheme AND attribute_name = attr_name) THEN
        RETURN 'decimal';
    ELSEIF EXISTS(SELECT 'X'
              FROM varchars
              WHERE model_name = model AND relation_scheme_name = scheme AND attribute_name = attr_name) THEN
        RETURN 'varchar';
    ELSE
        RETURN (SELECT data_type_name
                FROM others
                WHERE model_name = model AND relation_scheme_name = scheme AND attribute_name = attr_name);
    END IF;
END //
DELIMITER ;

/*
   Three on insert triggers to enforce that an attribute only belongs to one data_type
*/
DELIMITER //
CREATE TRIGGER decimal_before_insert
    BEFORE INSERT ON decimals FOR EACH ROW
    BEGIN
        IF EXISTS(SELECT 'A'
                  FROM varchars
                  WHERE relation_scheme_name = NEW.relation_scheme_name
                        AND model_name = NEW.model_name
                        AND attribute_name = NEW.attribute_name) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error, the attribute already exist in the model';
        END IF;
        IF EXISTS(SELECT 'B'
                  FROM others
                  WHERE relation_scheme_name = NEW.relation_scheme_name
                        AND model_name = NEW.model_name
                        AND attribute_name = NEW.attribute_name) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error, the attribute already exist in the model';
        END IF;
    END //
DELIMITER ;


DELIMITER //
CREATE TRIGGER varchars_before_insert
    BEFORE INSERT ON varchars FOR EACH ROW
    BEGIN
        IF EXISTS(SELECT 'A'
                  FROM decimals
                  WHERE relation_scheme_name = NEW.relation_scheme_name
                        AND model_name = NEW.model_name
                        AND attribute_name = NEW.attribute_name) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error, the attribute already exist in the model';
        END IF;
        IF EXISTS(SELECT 'B'
                  FROM others
                  WHERE relation_scheme_name = NEW.relation_scheme_name
                        AND model_name = NEW.model_name
                        AND attribute_name = NEW.attribute_name) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error, the attribute already exist in the model';
        END IF;
    END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER others_before_insert
    BEFORE INSERT ON others FOR EACH ROW
    BEGIN
        IF EXISTS(SELECT 'A'
                  FROM decimals
                  WHERE relation_scheme_name = NEW.relation_scheme_name
                        AND model_name = NEW.model_name
                        AND attribute_name = NEW.attribute_name) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error, the attribute already exist in the model';
        END IF;
        IF EXISTS(SELECT 'B'
                  FROM varchars
                  WHERE relation_scheme_name = NEW.relation_scheme_name
                        AND model_name = NEW.model_name
                        AND attribute_name = NEW.attribute_name) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error, the attribute already exist in the model';
        END IF;
END //
DELIMITER ;

/*
  An on insert trigger that enforces that float type attribute cannot be a key
  INSERT INTO unique_columns(attribute_name, model_name, relation_scheme_name, candidate_key_name, ordering_index) VALUES
('incentive_compensation_percentage','EmployeeDeptModel','Employees','incentive_compensation_key',3);
*/
DELIMITER //
CREATE TRIGGER valid_type_candidate_keys
    BEFORE INSERT ON unique_columns FOR EACH ROW
BEGIN
        IF STRCMP(get_attribute_type(NEW.model_name,NEW.relation_scheme_name,NEW.attribute_name), 'float') = 0 THEN
           SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error, a float type attribute cannot be a unique key';
        END IF;
END //
DELIMITER ;

/*
    Enforce that the relationship between candidate_keys and unique_columns belong to the same relation_scheme
*/
DELIMITER //
CREATE TRIGGER unique_columns_before_insert
    BEFORE INSERT ON unique_columns FOR EACH ROW
    BEGIN
        IF (STRCMP((SELECT candidate_keys.relation_scheme_name
                  FROM candidate_keys
                  WHERE candidate_keys.name = NEW.candidate_key_name AND candidate_keys.model_name = NEW.model_name), NEW.relation_scheme_name) <> 0) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error, the unique column should be in the same relation scheme with candidate_keys and attributes';
        END IF;
END //
DELIMITER ;
/*
    A Stored Procedure that check whether there is a candidate key or primary key associated with the coming foreign key name.
    We want to keep consistency by making the foreign key name unique in the model.

    @param foreign_key_name - the name of the foreign key we are trying to insert
           foreign_key_model_name - the model name that the foreign key we are trying to insert belongs to
*/
DELIMITER $$
CREATE PROCEDURE check_foreign_key_name(IN foreign_key_name VARCHAR(30), IN foreign_key_model_name VARCHAR(50))
BEGIN
        IF ((SELECT COUNT(*)
             FROM candidate_keys
             WHERE candidate_keys.name = foreign_key_name AND candidate_keys.model_name = foreign_key_model_name) <> 0) THEN
           SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error, a foreign key name should be different from an existing candidate key name.';
        END IF;
        IF ((SELECT COUNT(*)
             FROM primary_keys
             WHERE primary_keys.candidate_key_name = foreign_key_name AND primary_keys.model_name = foreign_key_model_name) <> 0) THEN
           SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error, a foreign key name should be different from an existing primary key name.';
        END IF;
END $$
DELIMITER ;

/*
    A trigger to enforce a foreign key should not be the same with neither primary key name nor candidate key name
*/
DELIMITER //
CREATE TRIGGER foreign_keys_before_insert
    BEFORE INSERT ON foreign_keys FOR EACH ROW
    BEGIN
        CALL check_foreign_key_name(NEW.name,NEW.model_name);
END //
DELIMITER ;

/*
    A Stored Procedure that check whether there is a foreign key associated with the coming candidate key name.
    We want to keep consistency by making the foreign key name unique in the model.

    @param candidate_key_name - the name of the candidate key we are trying to insert
           candidate_key_model_name - the model name that the candidate key we are trying to insert belongs to
*/

DELIMITER $$
CREATE PROCEDURE check_candidate_name(IN candidate_key_name VARCHAR(30), IN candidate_key_model_name VARCHAR(50))
BEGIN
        IF ((SELECT COUNT(*)
             FROM foreign_keys
             WHERE foreign_keys.name = candidate_key_name AND foreign_keys.model_name = candidate_key_model_name) <> 0) THEN
           SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error, a candidate key cannot have a name of an existing foreign key since a foreign key name should be unique in the model.';
        END IF;
END $$
DELIMITER ;

/*
    An INSERT ON trigger to not let add a candidate key that has a name of an existing foreign key.
*/
DELIMITER //
CREATE TRIGGER candidate_keys_before_insert
    BEFORE INSERT ON candidate_keys FOR EACH ROW
    BEGIN
        CALL check_candidate_name(NEW.name,NEW.model_name);
END //
DELIMITER ;
/*

*/
/*
    a function generating attributes for relation scheme DDL which is utilized in generate_attribute function
    @param	in_model_name			The name of the model that you want to generate the DDL for.
    @param	in_relation_scheme_name	The relation scheme within that model that owns the attribute.
    @param	in_attribute_name		The name of the attribute to generate DDL for.
    @return							The one line of DDL for this particular attribute.
*/
DELIMITER //
CREATE FUNCTION generate_attribute_with_datatype(in_model_name VARCHAR(50), in_relation_scheme_name VARCHAR(50),
				in_attribute_name VARCHAR(60)) RETURNS TEXT CHARSET utf8mb4
    READS SQL DATA
BEGIN
	DECLARE	results TEXT DEFAULT '';			-- The output string.
	DECLARE decimal_precision_x TEXT DEFAULT '';
	DECLARE decimal_scale_x TEXT DEFAULT '';
	DECLARE varchar_length TEXT DEFAULT '';
	SET decimal_precision_x := (SELECT decimal_precision
                             FROM decimals
                             WHERE model_name = in_model_name
                                   AND relation_scheme_name = in_relation_scheme_name
                                   AND attribute_name = in_attribute_name);
	SET decimal_scale_x := (SELECT decimal_scale
                         FROM decimals
                         WHERE model_name = in_model_name
                               AND relation_scheme_name = in_relation_scheme_name
                               AND attribute_name = in_attribute_name);
	SET varchar_length := (SELECT length
                          FROM varchars
                          WHERE model_name = in_model_name
                                AND relation_scheme_name = in_relation_scheme_name
                                AND attribute_name = in_attribute_name);
    IF STRCMP(get_attribute_type(in_model_name,in_relation_scheme_name,in_attribute_name), 'decimal') = 0 THEN
       SET results = concat (in_attribute_name, '	','DECIMAL(',CAST(decimal_precision_x AS CHAR ),',',CAST(decimal_scale_x AS CHAR),')');
	ELSEIF STRCMP(get_attribute_type(in_model_name,in_relation_scheme_name,in_attribute_name), 'varchar') = 0 THEN
       SET results = concat (in_attribute_name, '	','VARCHAR(',CAST(varchar_length AS CHAR),')');
	ELSE
	    SET results = concat (in_attribute_name, '	',get_attribute_type(in_model_name,in_relation_scheme_name,in_attribute_name));
    END IF;
	RETURN results;
END //
DELIMITER ;
/*
    This generates the attribute with it's data type
    @param	in_model_name			The name of the model that you want to generate the DDL for.
    @param	in_relation_scheme_name	The relation scheme within that model that owns the attribute.
    @param	in_attribute_name		The name of the attribute to generate DDL for.
    @return							The one line of DDL for this particular attribute.
    */
DELIMITER //
CREATE FUNCTION generate_attribute(in_model_name VARCHAR(50), in_relation_scheme_name VARCHAR(50),
				in_attribute_name VARCHAR(60)) RETURNS TEXT CHARSET utf8mb4
    READS SQL DATA
BEGIN
	DECLARE	results TEXT DEFAULT '';			-- The output string.
    IF NOT EXISTS (
		SELECT	'X'
        FROM	attributes
        WHERE	model_name = in_model_name AND
				relation_scheme_name = in_relation_scheme_name AND
                name = in_attribute_name) THEN
		SET results = concat ('Error, model: ', in_model_name, ' relation scheme name: ', in_relation_scheme_name,
							' attribute: ', in_attribute_name, ' not found!');
	ELSE
		SET results = generate_attribute_with_datatype(in_model_name,in_relation_scheme_name,in_attribute_name);
	END IF;
	RETURN results;
END //
DELIMITER ;

SELECT get_attribute_type('EmployeeDeptModel','Employees','employee_id');


/*

    This generates the prototype DDL for a single relation scheme.
    @param	in_model_name			The name of the model that you want to generate the DDL for.
    @param	in_relation_scheme_name	The relation scheme within that model that owns the attribute.
    @return							The DDL for this one relation scheme.

*/
DELIMITER $$
CREATE FUNCTION generate_relation_scheme (in_model_name VARCHAR(64), in_relation_scheme_name VARCHAR(64)) RETURNS text CHARSET utf8mb4
    READS SQL DATA
BEGIN
	DECLARE results text default '';
    DECLARE next_attribute VARCHAR(64);
    -- Flag to tell us whether this is the first column in the output
    DECLARE first BOOLEAN default true;
    DECLARE done int default 0;						-- Flag to get us out of the cursor
    DECLARE	relation_cur CURSOR FOR
		SELECT	name
        FROM	attributes
        WHERE	model_name = in_model_name AND
				relation_scheme_name = in_relation_scheme_name;
	-- This handler will flip the done flag after we read the last row from the cursor.
	DECLARE continue handler for not found set done = 1;
    IF NOT EXISTS (
		SELECT	'X'
        FROM	relation_schemes
        WHERE	model_name = in_model_name AND
				name = in_relation_scheme_name) THEN
		SET results = concat ('Error, model: ', in_model_name, ' relation scheme name: ', in_relation_scheme_name,
								' does not exist!');
	ELSE
		SET results = concat ('CREATE TABLE	', in_relation_scheme_name, '(');
        OPEN relation_cur;
        REPEAT
			FETCH relation_cur into next_attribute;
            IF NOT done THEN
				IF first THEN
					SET first = false;				-- Not the first attribute anymore.
                    -- This is the only way that I've been able to insert a CR/LF
                    SET results = CONCAT(results, '', generate_attribute (in_model_name, in_relation_scheme_name, next_attribute),' ',get_not_null_attributes (in_model_name, in_relation_scheme_name, next_attribute));
				ELSE
					SET results = CONCAT(results, ',', generate_attribute (in_model_name, in_relation_scheme_name, next_attribute), ' ',get_not_null_attributes (in_model_name, in_relation_scheme_name, next_attribute));
				END IF;
            END IF;
		    UNTIL done
        END REPEAT;
        CLOSE relation_cur;

		-- PRIMARY KEY RETRIEVING
		SET results = CONCAT(results, ', CONSTRAINT PK_', in_relation_scheme_name, ' PRIMARY KEY (');
		SET first = TRUE;
		SET done = 0;
		OPEN relation_cur;
        REPEAT
            FETCH relation_cur into next_attribute;
            IF NOT done THEN
                IF first AND get_primary_keys (in_model_name, in_relation_scheme_name, next_attribute) THEN
                    SET results = CONCAT(results, next_attribute);
                    SET first = FALSE;
                ELSE
                    IF (NOT first) AND get_primary_keys (in_model_name, in_relation_scheme_name, next_attribute) THEN
                        SET results = CONCAT(results, ',', next_attribute);
                    END IF;
                END IF;
            END IF;
            UNTIL done
        END REPEAT;
        CLOSE relation_cur;
		SET results = CONCAT(results, ')');
        SET results = CONCAT(results, ');');
    END IF;
    IF check_split_key (in_model_name, in_relation_scheme_name) THEN
        SET results = CONCAT(in_relation_scheme_name, ' has a split key, cannot generate a primary key.');
    END IF;
	RETURN results;
END $$
DELIMITER ;
/*
   A function that tells us which attribute cannot be null
    @param	in_model_name			The name of the model.
    @param	in_relation_scheme_name	The relation scheme within that model that owns the attribute.
    @param	in_attribute_name	    The attribute name.
    @return							The 'Not Null' for this one attribute.
*/
DELIMITER //
CREATE FUNCTION get_not_null_attributes(in_model_name VARCHAR(50), in_relation_scheme_name VARCHAR(50),in_attribute_name VARCHAR(60)) RETURNS TEXT CHARSET utf8mb4
    READS SQL DATA
BEGIN
	DECLARE	results TEXT DEFAULT '';			-- The output string.

    IF EXISTS (
				SELECT	'X'
                FROM	unique_columns
                WHERE	model_name = in_model_name
                        AND relation_scheme_name = in_relation_scheme_name
                        AND attribute_name = in_attribute_name
                        AND candidate_key_name IN (SELECT name
                                                   FROM candidate_keys
                                                   WHERE	model_name = in_model_name AND
                                                            relation_scheme_name = in_relation_scheme_name)) THEN
        SET results = 'Not Null';
    ELSE
        SET  results = '';
    END IF;
	RETURN results;
END //
DELIMITER ;
/*
   A function that check if a given attribute is part of a primary keys
    @param	in_model_name			The name of the model.
    @param	in_relation_scheme_name	The relation scheme within that model that owns the attribute.
    @param	in_attribute_name	    The attribute name.
    @return							TRUE if the attribute is part of a primary key.

*/
DELIMITER //
CREATE FUNCTION get_primary_keys(in_model_name VARCHAR(50), in_relation_scheme_name VARCHAR(50),in_attribute_name VARCHAR(60)) RETURNS TEXT CHARSET utf8mb4
    READS SQL DATA
BEGIN
	DECLARE	results BOOLEAN DEFAULT FALSE;			-- The output boolean.

    IF EXISTS (
				SELECT	'X'
                FROM	unique_columns
                WHERE	model_name = in_model_name
                        AND relation_scheme_name = in_relation_scheme_name
                        AND attribute_name = in_attribute_name
                        AND candidate_key_name IN (SELECT candidate_key_name
                                                   FROM primary_keys
                                                   WHERE	model_name = in_model_name AND
                                                            relation_scheme_name = in_relation_scheme_name)) THEN
        SET results = TRUE;
    ELSE
        SET  results = FALSE;
    END IF;
	RETURN results;
END //
DELIMITER ;

/*
    FOREIGN KEY GENERATOR
    @param	in_model_name			            The name of the model.
    @param	in_relation_scheme_name	            The parent relation scheme within that model.
    @param	in_relation_scheme_name_child	    The child relation scheme within that model.
    @return							            ALTER statement for one relationship
*/

DELIMITER //
CREATE FUNCTION get_foreign_keys(in_model_name VARCHAR(50), in_relation_scheme_name VARCHAR(50), in_relation_scheme_name_child VARCHAR(50)) RETURNS TEXT CHARSET utf8mb4
    READS SQL DATA
BEGIN
	DECLARE	results TEXT DEFAULT '';			-- The output string.

    IF EXISTS (
				SELECT	'X'
                FROM	attribute_foreign_keys
                WHERE	model_name = in_model_name
                        AND relation_scheme_name_child = in_relation_scheme_name_child
                        AND relation_scheme_name = in_relation_scheme_name
               ) THEN
        SET results = CONCAT('ALTER TABLE ',in_relation_scheme_name_child,' ADD CONSTRAINT ',(SELECT DISTINCT foreign_keys_name
                                       FROM attribute_foreign_keys
                                       WHERE model_name = in_model_name
                                             AND relation_scheme_name_child = in_relation_scheme_name_child
                                             AND relation_scheme_name = in_relation_scheme_name
                                             AND foreign_keys_name like CONCAT('%',in_relation_scheme_name,'%')) ,' FOREIGN KEY (');
        SET results =CONCAT (results,( SELECT GROUP_CONCAT(attribute_name_child) FROM attribute_foreign_keys
                                       WHERE model_name = in_model_name
                                             AND relation_scheme_name_child = in_relation_scheme_name_child
                                             AND relation_scheme_name = in_relation_scheme_name),') REFERENCES ', in_relation_scheme_name , '(');
        SET results =CONCAT (results,(SELECT GROUP_CONCAT(attribute_name) FROM attribute_foreign_keys
                                      WHERE model_name = in_model_name
                                          AND relation_scheme_name_child = in_relation_scheme_name_child
                                          AND relation_scheme_name = in_relation_scheme_name),')');

    ELSE
        SET  results = '';
    END IF;
	RETURN results;
END //
DELIMITER ;

/*
    UNIQUE KEY GENERATOR
    @param	in_model_name			            The name of the model.
    @param	in_relation_scheme_name	            The relation scheme within that model that could have a unique key.
    @return							            ALTER statement for one relationship
*/
DELIMITER //
CREATE FUNCTION get_unique_keys(in_model_name VARCHAR(50), in_relation_scheme_name VARCHAR(50)) RETURNS TEXT CHARSET utf8mb4
    READS SQL DATA
BEGIN
	DECLARE	results TEXT DEFAULT '';			-- The output string.

    IF EXISTS (
				SELECT	'X'
                FROM	unique_columns
                WHERE	model_name = in_model_name
                        AND relation_scheme_name = in_relation_scheme_name
                        AND candidate_key_name NOT IN (SELECT candidate_key_name
                                                       FROM primary_keys
                                                       WHERE	model_name = in_model_name AND
                                                                relation_scheme_name = in_relation_scheme_name)
               ) THEN
        SET results = CONCAT('ALTER TABLE ',in_relation_scheme_name,' ADD UNIQUE (',(SELECT DISTINCT GROUP_CONCAT(attribute_name)
                                       FROM unique_columns
                                       WHERE model_name = in_model_name
                                             AND relation_scheme_name = in_relation_scheme_name
                                             AND candidate_key_name like CONCAT('%',in_relation_scheme_name,'%')
                                             AND candidate_key_name NOT IN (SELECT candidate_key_name
                                                       FROM primary_keys
                                                       WHERE	model_name = in_model_name AND
                                                                relation_scheme_name = in_relation_scheme_name)) ,')');

    ELSE
        SET  results = '';
    END IF;
	RETURN results;
END //
DELIMITER ;


/*
   A function that checks a given candidate key is a subset of another candidate key within its relation scheme
    @param	in_model_name			            The name of the model.
    @param	in_relation_scheme_name	            The relation scheme within that model.
    @param	in_candidate_key_name       	    The candidate key name other than the primary key.
    @return							            TRUE if the candidate_key is a subset
*/
DELIMITER //
CREATE FUNCTION check_candidate_key_subset(in_model_name VARCHAR(50), in_relation_scheme_name VARCHAR(50),in_candidate_key_name VARCHAR(60)) RETURNS TEXT CHARSET utf8mb4
    READS SQL DATA
BEGIN
	DECLARE	results BOOLEAN DEFAULT FALSE;			-- The output string.

    IF EXISTS (	SELECT	'X'
                FROM	unique_columns
                WHERE	model_name = in_model_name
                        AND relation_scheme_name = in_relation_scheme_name
                        AND candidate_key_name = in_candidate_key_name
                        AND attribute_name in (  SELECT	attribute_name
                                                 FROM	unique_columns
                                                 WHERE	model_name = in_model_name
                                                        AND relation_scheme_name = in_relation_scheme_name
                                                        AND candidate_key_name IN (SELECT candidate_key_name
                                                                                    FROM primary_keys
                                                                                    WHERE	model_name = in_model_name AND
                                                                                            relation_scheme_name = in_relation_scheme_name))) THEN
        SET results = FALSE;
    ELSE
        SET  results = TRUE;
    END IF;
	RETURN results;
END //
DELIMITER ;

/*
   A function that checks a given candidate key is a subset of another candidate key within its relation scheme
    @param	in_model_name			            The name of the model.
    @param	in_relation_scheme_name	            The relation scheme within that model.
    @return							            TRUE if the relation_scheme has a split key
*/

DELIMITER //
CREATE FUNCTION check_split_key(in_model_name VARCHAR(50), in_relation_scheme_name_child VARCHAR(50)) RETURNS TEXT CHARSET utf8mb4
    READS SQL DATA
BEGIN
	DECLARE	results BOOLEAN DEFAULT FALSE;			-- The output string.
    DECLARE done int default 0;						-- Flag to get us out of the cursor
	DECLARE next_parent varchar(60);
	DECLARE split_key_failure_counter int default 0;
    DECLARE	parent_cur CURSOR FOR
		SELECT	DISTINCT relation_scheme_name
        FROM	attribute_foreign_keys
        WHERE	model_name = in_model_name AND
				relation_scheme_name_child = in_relation_scheme_name_child;
	-- This handler will flip the done flag after we read the last row from the cursor.
	DECLARE continue handler for not found set done = 1;
        OPEN parent_cur;
        REPEAT
			FETCH parent_cur into next_parent;
            IF NOT done THEN
				IF
				  EXISTS(SELECT	DISTINCT relation_scheme_name
                         FROM	attribute_foreign_keys
                         WHERE	model_name = in_model_name AND
                                relation_scheme_name_child = in_relation_scheme_name_child
				                AND relation_scheme_name = next_parent)
				  AND
                   (((   SELECT COUNT(attribute_name)
                        FROM unique_columns
                        WHERE model_name = in_model_name
                             AND relation_scheme_name = next_parent
                             AND candidate_key_name in (
                                                         SELECT candidate_key_name
                                                         FROM primary_keys
                                                         WHERE model_name = in_model_name
                                                               AND relation_scheme_name = next_parent
                            ))
                    !=
                   ( SELECT COUNT(candidate_key_name)
                     FROM unique_columns
                     WHERE model_name = in_model_name
                         AND relation_scheme_name = in_relation_scheme_name_child
                         AND candidate_key_name IN (
                                                    SELECT candidate_key_name
                                                    FROM primary_keys
                                                    WHERE model_name = in_model_name
                                                         AND relation_scheme_name = in_relation_scheme_name_child
                    )))
                    AND
                     (( SELECT COUNT(attribute_name)
                        FROM unique_columns
                        WHERE model_name = in_model_name
                             AND relation_scheme_name = next_parent
                             AND candidate_key_name in (
                                                         SELECT candidate_key_name
                                                         FROM primary_keys
                                                         WHERE model_name = in_model_name
                                                               AND relation_scheme_name = next_parent
                            ))
                     > -- CHECK IF THE MIGRATING KEY IS GREATER THAT THE CHILD PK
                     (SELECT COUNT(candidate_key_name)
                     FROM unique_columns
                     WHERE model_name = in_model_name
                         AND relation_scheme_name = in_relation_scheme_name_child
                         AND candidate_key_name IN (
                                                    SELECT candidate_key_name
                                                    FROM primary_keys
                                                    WHERE model_name = in_model_name
                                                         AND relation_scheme_name = in_relation_scheme_name_child
                        ))))
                  THEN
				     SET split_key_failure_counter = split_key_failure_counter + 1;
				END IF;
            END IF;
		    UNTIL done
        END REPEAT;
        CLOSE parent_cur;

	    IF  split_key_failure_counter != 0 THEN
	        SET results = TRUE;
        ELSE
         SET  results = FALSE;
    END IF;
	RETURN results;
END //
DELIMITER ;

/*  Load up your database with a very simple model  */
INSERT INTO models(name, description, creation_date) VALUE
('EmployeeDeptModel','A model designed for employees and department relationships', NOW());

INSERT INTO relation_schemes(name, model_name, description) VALUES
('Employees', 'EmployeeDeptModel','Employees relation scheme that holds the metadata of employees table.'),
('Department', 'EmployeeDeptModel','Department relation scheme that holds the metadata of departments table.');

INSERT INTO attributes(name, relation_scheme_name, model_name, description) VALUES
('employee_id', 'Employees','EmployeeDeptModel','An auto generated identifier'),
('first_name', 'Employees','EmployeeDeptModel','The first name of a person who is hired by a company'),
('last_name', 'Employees','EmployeeDeptModel','The last name of a person who is hired by a company'),
('SSN', 'Employees','EmployeeDeptModel','A unique identifier number of a U.S resident that is issued by the Social Security Administration.'),
('annual_salary', 'Employees','EmployeeDeptModel','A yearly payment that a person receives.'),
('hire_date', 'Employees','EmployeeDeptModel','The first day a person started working for a company under some agreement.'),
('incentive_compensation_percentage', 'Employees','EmployeeDeptModel','An award that a person gets during emergency.');

INSERT INTO attributes(name, relation_scheme_name, model_name, description) VALUES
('name', 'Department','EmployeeDeptModel','A word or a set of word that a department is referred to.'),
('description', 'Department','EmployeeDeptModel','Details of what the department does.'),
('abbreviation', 'Department','EmployeeDeptModel','The department name in a short form generated from mostly the first letters of each works in the department name.');

INSERT INTO varchars(attribute_name, relation_scheme_name, model_name, length) VALUES
('first_name','Employees','EmployeeDeptModel',35),
('last_name','Employees','EmployeeDeptModel',35),
('name','Department','EmployeeDeptModel',100),
('abbreviation','Department','EmployeeDeptModel',10),
('description','Department','EmployeeDeptModel',200);

INSERT INTO decimals(attribute_name, relation_scheme_name, model_name, decimal_precision, decimal_scale) VALUES
('annual_salary','Employees','EmployeeDeptModel',10,2);

INSERT INTO data_types(name) VALUES
('int'),
('date'),
('float'),
('time');

INSERT INTO others(attribute_name, relation_scheme_name, model_name, data_type_name) VALUES
('employee_id', 'Employees','EmployeeDeptModel', 'int'),
('SSN', 'Employees','EmployeeDeptModel', 'int'),
('hire_date', 'Employees','EmployeeDeptModel', 'date'),
('incentive_compensation_percentage', 'Employees','EmployeeDeptModel','float');

INSERT INTO candidate_keys(name, model_name, relation_scheme_name) VALUES
('employee_id_key','EmployeeDeptModel','Employees'),
('incentive_compensation_percentage_key','EmployeeDeptModel','Employees'),
('employee_ssn_key','EmployeeDeptModel','Employees'),
('demp_name_key','EmployeeDeptModel','Department');

INSERT INTO primary_keys(candidate_key_name, model_name, relation_scheme_name) VALUES
('employee_id_key','EmployeeDeptModel','Employees'),
('demp_name_key','EmployeeDeptModel','Department');

INSERT INTO unique_columns(attribute_name, model_name, relation_scheme_name, candidate_key_name, ordering_index) VALUES
('employee_id','EmployeeDeptModel','Employees','employee_id_key',1);
INSERT INTO unique_columns(attribute_name, model_name, relation_scheme_name, candidate_key_name, ordering_index) VALUES
('SSN','EmployeeDeptModel','Employees','employee_ssn_key',2);
INSERT INTO unique_columns(attribute_name, model_name, relation_scheme_name, candidate_key_name, ordering_index) VALUES
('name','EmployeeDeptModel','Departments','demp_name_key',1);

/*
    TESTING float type attribute cannot be a key
*/
INSERT INTO candidate_keys(name, model_name, relation_scheme_name) VALUES
('incentive_compensation_key','EmployeeDeptModel','Employees');

DELETE FROM candidate_keys WHERE name = 'incentive_compensation_key' AND model_name = 'EmployeeDeptModel';

INSERT INTO unique_columns(attribute_name, model_name, relation_scheme_name, candidate_key_name, ordering_index) VALUES
('incentive_compensation_percentage','EmployeeDeptModel','Employees','incentive_compensation_key',3);

DELETE FROM unique_columns WHERE attribute_name = 'incentive_compensation_percentage' AND model_name = 'EmployeeDeptModel';
/*
    TESTING that the relationship between candidate_keys and unique_columns belong to the same relation_scheme
*/
INSERT INTO candidate_keys(name, model_name, relation_scheme_name) VALUES
('description_key','EmployeeDeptModel','Department');

DELETE FROM candidate_keys WHERE name = 'description_key' AND model_name = 'EmployeeDeptModel';

INSERT INTO unique_columns(attribute_name, model_name, relation_scheme_name, candidate_key_name, ordering_index) VALUES
('first_name','EmployeeDeptModel','Employees','description_key',3);

DELETE FROM unique_columns WHERE attribute_name = 'first_name' AND model_name = 'EmployeeDeptModel' AND relation_scheme_name = 'Employees';

/*
    TESTING that an attribute can only have one and only one data type

    WE have this record already in our database

    INSERT INTO others(attribute_name, relation_scheme_name, model_name, data_type_name) VALUES
    ('SSN', 'Employees','EmployeeDeptModel', 'int');
*/
INSERT INTO varchars(attribute_name, relation_scheme_name, model_name, length) VALUES
('SSN','Employees','EmployeeDeptModel',35);

INSERT INTO decimals(attribute_name, relation_scheme_name, model_name, decimal_precision, decimal_scale) VALUES
('SNN','Employees','EmployeeDeptModel',9,4);

/*
    TESTING that a relation_scheme should be unique within its model

    WE have this record already in our database

    INSERT INTO relation_schemes(name, model_name, description) VALUES
    ('Employees', 'EmployeeDeptModel','Employees relation scheme that holds the metadata of employees table.');

*/
INSERT INTO relation_schemes(name, model_name, description) VALUES
('Employees', 'EmployeeDeptModel','Employees relation scheme that holds the metadata of employees table.');

/*
    TESTING that a primary key should be in the same relation_scheme with the candidate key
*/
INSERT INTO primary_keys(candidate_key_name, model_name, relation_scheme_name) VALUES
('demp_name_key','EmployeeDeptModel','Employees');

/*
 -------------------------------------------------------------------------------------------
           PART 2 OF THE PROJECT DATA INSERTION AND TESTING AFTER THE HOMEWORK
 -------------------------------------------------------------------------------------------
*/
-- Erase all previous data we had
DELETE FROM primary_keys;
DELETE FROM decimals;
DELETE FROM varchars;
DELETE FROM others;
DELETE FROM data_types;
DELETE FROM unique_columns;
DELETE FROM candidate_keys;
DELETE FROM attributes;
DELETE FROM relation_schemes;
DELETE FROM models;

INSERT INTO models(name, description, creation_date) VALUE
('relation_scheme_model_project','A metadata model that stores data of data.',NOW());

INSERT INTO relation_schemes(name, model_name, description) VALUES
('departments','relation_scheme_model_project','The area of special experts.'),
('courses','relation_scheme_model_project','A training of provided by a higher institution.'),
('students','relation_scheme_model_project','A person who attends a higher institution to take courses.'),
('instructors','relation_scheme_model_project','A person who trains students.'),
('days','relation_scheme_model_project','A period of 24 hours that has a name which is one of the week days'),
('semesters','relation_scheme_model_project','A period where a specific course is given to students.'),
('sections','relation_scheme_model_project','A number given to the same courses to differentiate them.'),
('grades','relation_scheme_model_project','A number that has an upper limit of 4.0 which shows student success'),
('enrollments','relation_scheme_model_project','A system that identifies who is enrolled and who teaches a course.'),
('transcript_entries','relation_scheme_model_project','A paperwork that has all grade latter that student earned associated with courses');

INSERT INTO attributes(name, relation_scheme_name, model_name, description) VALUES
('name','departments','relation_scheme_model_project','A word or set of words that a department is known for.'),
('name','courses','relation_scheme_model_project','A word or set of words that a course is known for.'),
('number','courses','relation_scheme_model_project','An identifier given to course.'),
('description','courses','relation_scheme_model_project','An explanation of what the course is about.'),
('units','courses','relation_scheme_model_project','A general measure of academic work over a period of time'),
('title','courses','relation_scheme_model_project','A brief and general description of a course.'),
('instructor_name','instructors','relation_scheme_model_project','A word or set of words that instructor is known for.'),
('weekday_combinations','days','relation_scheme_model_project','A combinations of days within a week.'),
('name','semesters','relation_scheme_model_project','A word or set of words that a semester is known for.'),
('student_id','students','relation_scheme_model_project','A number that is associated and unique per student.'),
('last_name','students','relation_scheme_model_project','A word or set of words that students family is known for.'),
('first_name','students','relation_scheme_model_project','A word or set of words that students family is known for.'),
('department_name','sections','relation_scheme_model_project','A word or set of words that a department is known for.'),
('course_number','sections','relation_scheme_model_project','An identifier given to course.'),
('number','sections','relation_scheme_model_project','An identifier given to section.'),
('instructor','sections','relation_scheme_model_project','A person who trains students.'),
('year','sections','relation_scheme_model_project','A number that represents the period of 365 days.'),
('semester','sections','relation_scheme_model_project','A word or set of words that a semester is known for.'),
('start_time','sections','relation_scheme_model_project','The time that states the beginning of the course section.'),
('days','sections','relation_scheme_model_project','A word that states the meeting schedule of course section.'),
('grade_letter','grades','relation_scheme_model_project','Alphabetical representation of a students achievement from A - F, except E.'),
('student_id','enrollments','relation_scheme_model_project','A number that is associated and unique per student.'),
('department_name','enrollments','relation_scheme_model_project','A word or set of words that a department is known for.'),
('course_number','enrollments','relation_scheme_model_project','An identifier given to course.'),
('section_number','enrollments','relation_scheme_model_project','An identifier given to section.'),
('year','enrollments','relation_scheme_model_project','A number that represents the period of 365 days.'),
('semester','enrollments','relation_scheme_model_project','A word or set of words that a semester is known for.'),
('grade','enrollments','relation_scheme_model_project','Alphabetical representation of a students achievement from A - F, except E.'),
('student_id','transcript_entries','relation_scheme_model_project','A number that is associated and unique per student.'),
('department_name','transcript_entries','relation_scheme_model_project','A word or set of words that a department is known for.'),
('course_number','transcript_entries','relation_scheme_model_project','An identifier given to course.'),
('section_number','transcript_entries','relation_scheme_model_project','An identifier given to section.'),
('year','transcript_entries','relation_scheme_model_project','A number that represents the period of 365 days.'),
('semester','transcript_entries','relation_scheme_model_project','A word or set of words that a semester is known for.');

INSERT INTO varchars(attribute_name, relation_scheme_name, model_name, length) VALUES
('name','departments','relation_scheme_model_project',100),
('name','courses','relation_scheme_model_project',100),
('title','courses','relation_scheme_model_project',250),
('instructor_name','instructors','relation_scheme_model_project',60),
('weekday_combinations','days','relation_scheme_model_project',100),
('name','semesters','relation_scheme_model_project',10),
('last_name','students','relation_scheme_model_project',25),
('first_name','students','relation_scheme_model_project',25),
('department_name','sections','relation_scheme_model_project',100),
('semester','sections','relation_scheme_model_project',10),
('days','sections','relation_scheme_model_project',100),
('grade_letter','grades','relation_scheme_model_project',3),
('department_name','enrollments','relation_scheme_model_project',100),
('semester','enrollments','relation_scheme_model_project',10),
('grade','enrollments','relation_scheme_model_project',3),
('department_name','transcript_entries','relation_scheme_model_project',100),
('semester','transcript_entries','relation_scheme_model_project',10);

INSERT INTO data_types(name) VALUES
('int'),
('date'),
('float'),
('time'),
('text');

INSERT INTO others(attribute_name, relation_scheme_name, model_name, data_type_name) VALUES
('number','courses','relation_scheme_model_project','int'),
('description','courses','relation_scheme_model_project','text'),
('units','courses','relation_scheme_model_project','int'),
('student_id','students','relation_scheme_model_project','int'),
('course_number','sections','relation_scheme_model_project','int'),
('number','sections','relation_scheme_model_project','int'),
('year','sections','relation_scheme_model_project','int'),
('start_time','sections','relation_scheme_model_project','time'),
('student_id','enrollments','relation_scheme_model_project','int'),
('course_number','enrollments','relation_scheme_model_project','int'),
('section_number','enrollments','relation_scheme_model_project','int'),
('year','enrollments','relation_scheme_model_project','int'),
('student_id','transcript_entries','relation_scheme_model_project','int'),
('course_number','transcript_entries','relation_scheme_model_project','int'),
('section_number','transcript_entries','relation_scheme_model_project','int'),
('year','transcript_entries','relation_scheme_model_project','int');

INSERT INTO candidate_keys(name, model_name, relation_scheme_name) VALUES
('sections_key','relation_scheme_model_project','sections'),
('departments_key','relation_scheme_model_project','departments'),
('days_key','relation_scheme_model_project','days'),
('instructors_key','relation_scheme_model_project','instructors'),
('semesters_key','relation_scheme_model_project','semesters'),
('courses_key','relation_scheme_model_project','courses'),
('courses_key_1','relation_scheme_model_project','courses'),
('students_key','relation_scheme_model_project','students'),
('grades_key','relation_scheme_model_project','grades'),
('enrollments_key','relation_scheme_model_project','enrollments'),
('transcript_entries_key','relation_scheme_model_project','transcript_entries');



INSERT INTO primary_keys(candidate_key_name, model_name, relation_scheme_name) VALUES
('sections_key','relation_scheme_model_project','sections'),
('departments_key','relation_scheme_model_project','departments'),
('days_key','relation_scheme_model_project','days'),
('instructors_key','relation_scheme_model_project','instructors'),
('semesters_key','relation_scheme_model_project','semesters'),
('courses_key','relation_scheme_model_project','courses'),
('students_key','relation_scheme_model_project','students'),
('grades_key','relation_scheme_model_project','grades'),
('enrollments_key','relation_scheme_model_project','enrollments'),
('transcript_entries_key','relation_scheme_model_project','transcript_entries');

INSERT INTO unique_columns(attribute_name, model_name, relation_scheme_name, candidate_key_name, ordering_index) VALUES
('name','relation_scheme_model_project','courses','courses_key',1),
('number','relation_scheme_model_project','courses','courses_key',2),
('name','relation_scheme_model_project','departments','departments_key',1),
('weekday_combinations','relation_scheme_model_project','days','days_key',1),
('name','relation_scheme_model_project','courses','courses_key_1',1),
('title','relation_scheme_model_project','courses','courses_key_1',2),
('instructor_name','relation_scheme_model_project','instructors','instructors_key',1),
('name','relation_scheme_model_project','semesters','semesters_key',1),
('department_name','relation_scheme_model_project','sections','sections_key',1),
('course_number','relation_scheme_model_project','sections','sections_key',2),
('number','relation_scheme_model_project','sections','sections_key',3),
('year','relation_scheme_model_project','sections','sections_key',4),
('semester','relation_scheme_model_project','sections','sections_key',5),
('student_id','relation_scheme_model_project','students','students_key',1),
('grade_letter','relation_scheme_model_project','grades','grades_key',1),
('student_id','relation_scheme_model_project','enrollments','enrollments_key',1),
('department_name','relation_scheme_model_project','enrollments','enrollments_key',2),
('course_number','relation_scheme_model_project','enrollments','enrollments_key',3),
('section_number','relation_scheme_model_project','enrollments','enrollments_key',4),
('year','relation_scheme_model_project','enrollments','enrollments_key',5),
('semester','relation_scheme_model_project','enrollments','enrollments_key',6),
('student_id','relation_scheme_model_project','transcript_entries','transcript_entries_key',1),
('department_name','relation_scheme_model_project','transcript_entries','transcript_entries_key',2),
('course_number','relation_scheme_model_project','transcript_entries','transcript_entries_key',3);


INSERT INTO foreign_keys(name, model_name, relation_scheme_name) VALUES
('fk_course_dept','relation_scheme_model_project','courses'),
('fk_sections_courses','relation_scheme_model_project','sections'),
('fk_sections_semesters','relation_scheme_model_project','sections'),
('fk_sections_instructors','relation_scheme_model_project','sections'),
('fk_sections_days','relation_scheme_model_project','sections'),
('fk_enrollments_students','relation_scheme_model_project','enrollments'),
('fk_enrollments_sections','relation_scheme_model_project','enrollments'),
('fk_enrollments_grades','relation_scheme_model_project','enrollments'),
('fk_transcript_enrollments','relation_scheme_model_project','transcript_entries');


INSERT INTO attribute_foreign_keys(attribute_name, attribute_name_child, model_name, relation_scheme_name, relation_scheme_name_child, candidate_key_name, foreign_keys_name, ordering_index) VALUES
('name','name','relation_scheme_model_project','departments','courses','departments_key','fk_course_dept',1),
('name','department_name','relation_scheme_model_project','courses','sections','courses_key','fk_sections_courses',1),
('number','course_number','relation_scheme_model_project','courses','sections','courses_key','fk_sections_courses',2),
('name','semester','relation_scheme_model_project','semesters','sections','semesters_key','fk_sections_semesters',1),
('instructor_name','instructor','relation_scheme_model_project','instructors','sections','instructors_key','fk_sections_instructors',2),
('weekday_combinations','days','relation_scheme_model_project','days','sections','days_key','fk_sections_days',3),
('student_id','student_id','relation_scheme_model_project','students','enrollments','students_key','fk_enrollments_students',1),
('department_name','department_name','relation_scheme_model_project','sections','enrollments','sections_key','fk_enrollments_sections',1),
('course_number','course_number','relation_scheme_model_project','sections','enrollments','sections_key','fk_enrollments_sections',2),
('number','section_number','relation_scheme_model_project','sections','enrollments','sections_key','fk_enrollments_sections',3),
('year','year','relation_scheme_model_project','sections','enrollments','sections_key','fk_enrollments_sections',4),
('semester','semester','relation_scheme_model_project','sections','enrollments','sections_key','fk_enrollments_sections',5),
('grade_letter','grade','relation_scheme_model_project','grades','enrollments','grades_key','fk_enrollments_grades',1),
('student_id','student_id','relation_scheme_model_project','enrollments','transcript_entries','enrollments_key','fk_transcript_enrollments',1),
('department_name','department_name','relation_scheme_model_project','enrollments','transcript_entries','enrollments_key','fk_transcript_enrollments',2),
('course_number','course_number','relation_scheme_model_project','enrollments','transcript_entries','enrollments_key','fk_transcript_enrollments',3),
('section_number','section_number','relation_scheme_model_project','enrollments','transcript_entries','enrollments_key','fk_transcript_enrollments',4),
('year','year','relation_scheme_model_project','enrollments','transcript_entries','enrollments_key','fk_transcript_enrollments',5),
('semester','semester','relation_scheme_model_project','enrollments','transcript_entries','enrollments_key','fk_transcript_enrollments',6);
/*
    TESTING
*/

/*Test if a candidate key is a subset of another candidate key*/
SELECT check_candidate_key_subset('relation_scheme_model_project','courses','courses_key_1');

/*Generate DDL for courses*/
SELECT generate_relation_scheme('relation_scheme_model_project', 'students');

CREATE TABLE	students(first_name	VARCHAR(25) ,last_name	VARCHAR(25) ,student_id	int Not Null, CONSTRAINT PK_students PRIMARY KEY (student_id));

SELECT generate_relation_scheme('relation_scheme_model_project', 'transcript_entries');

SELECT get_foreign_keys('relation_scheme_model_project','students','enrollments');

ALTER TABLE enrollments ADD CONSTRAINT fk_enrollments_students FOREIGN KEY (student_id) REFERENCES students(student_id);

-- TEST unique key name
INSERT INTO candidate_keys(name, model_name, relation_scheme_name) VALUES
('fk_course_dept','relation_scheme_model_project','sections');

INSERT INTO foreign_keys(name, model_name, relation_scheme_name) VALUES
('sections_key','relation_scheme_model_project','courses');

-- GENERATE ALTER STATEMENT FOR FOREIGN KEY

SELECT get_foreign_keys('relation_scheme_model_project','enrollments','transcript_entries');
-- Query Result
-- USE alter table to add foreign key constraint for each relationships

SELECT get_foreign_keys('relation_scheme_model_project','departments','courses');

-- Get the unique columns of the table other than the primary key
SELECT get_unique_keys('relation_scheme_model_project', 'courses');
-- Check split key
SELECT check_split_key('relation_scheme_model_project','transcript_entries');
SELECT check_split_key('relation_scheme_model_project','students');
SELECT check_split_key('relation_scheme_model_project','enrollments');
SELECT check_split_key('relation_scheme_model_project','sections');

SELECT get_unique_keys('relation_scheme_model_project','courses');