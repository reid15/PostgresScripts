--liquibase formatted sql

-----------------------------------------------------------------------------------------
--changeset Rob:initial 
--comment: Initial DB

CREATE TABLE test.team (
team_id int NOT NULL PRIMARY KEY,
team_name text NOT NULL
);

CREATE TABLE test.player (
team_id int NOT NULL REFERENCES test.team(team_id),
player_number int NOT NULL,
player_name text NOT NULL,
primary key (team_id, player_number)
);

CREATE OR REPLACE VIEW test.vwPlayers 
AS

SELECT t.team_name, p.player_number, p.player_name
FROM test.player as p
JOIN test.team as t
	ON t.team_id = p.team_id;

--rollback DROP VIEW test.vwPlayers; DROP TABLE test.player; DROP TABLE test.team;

-----------------------------------------------------------------------------------------

--changeset Rob:initial-data 
--comment: Initial database data

INSERT INTO test.team(team_id, team_name)
VALUES (1, 'Atlanta Falcons');

INSERT INTO test.player(team_id, player_number, player_name)
VALUES (1, 9, 'Desmond Ridder');

--rollback DELETE FROM test.player; DELETE FROM test.team;

-----------------------------------------------------------------------------------------

--changeset Rob:player-position 
--comment: Initial database data

ALTER TABLE test.player
ADD position varchar(3) NULL;

UPDATE test.player SET position = 'QB' WHERE team_id = 1 AND player_number = 9;

CREATE OR REPLACE VIEW test.vwPlayers 
AS

SELECT t.team_name, p.player_number, p.player_name, p.position
FROM test.player as p
JOIN test.team as t
	ON t.team_id = p.team_id;

--rollback ALTER TABLE test.player DROP COLUMN position;
