DROP TABLE Pokemon CASCADE CONSTRAINTS;
DROP TABLE Pokedex CASCADE CONSTRAINTS;
DROP TABLE Specimen CASCADE CONSTRAINTS;
DROP TABLE Dresseur CASCADE CONSTRAINTS;
DROP TABLE FacteursEspece CASCADE CONSTRAINTS;

DROP SEQUENCE seq_pokemon_id ;
DROP SEQUENCE seq_pokedex_id ;
DROP SEQUENCE seq_dresseur_id;

DROP INDEX idx_prenom_dresseur;
DROP INDEX idx_types_pokemon ;
DROP TRIGGER Decouverte ;
DROP TRIGGER Capture;

DROP VIEW Nb_Meme_Pokemon_Capture;
DROP VIEW nb_Pokemon ;
DROP VIEW Stats_Pokemon_Capture;

DROP PROCEDURE Relacher;

CREATE TABLE Pokemon(
  idPokemon 	NUMBER NOT NULL, 
  Type1 		VARCHAR2(20),
  Type2		VARCHAR2(20),
  nomEspece	VARCHAR2(20),
  CONSTRAINT pk_Pokemon PRIMARY KEY (idPokemon)
);

CREATE TABLE Dresseur(
  idDresseur 	NUMBER,
  nom			VARCHAR2(50),
  prenom		VARCHAR2(50),
  adresse		VARCHAR2(50),
  idPokedex 	NUMBER,
  CONSTRAINT pk_dresseur PRIMARY KEY (idDresseur)
);

CREATE TABLE Pokedex(
  idPokedex 	NUMBER,
  idPokemon 	NUMBER,
  idDresseur	NUMBER,
  apercu		NUMBER(1),
  capture		NUMBER(1),
  nbPokemonApercu 	NUMBER,
  nbPokemonCapture 	NUMBER,
  CONSTRAINT ck_bool_apercu CHECK (apercu IN (1,0)),
  CONSTRAINT ck_bool_capture CHECK (capture IN (1,0)),
  CONSTRAINT pasApercuNega CHECK (nbPokemonApercu >= 0),
  CONSTRAINT pasCaptureNega CHECK (nbPokemonCapture >= 0),
    CONSTRAINT pk_Pokedex PRIMARY KEY (idPokedex, idPokemon, idDresseur),
    CONSTRAINT fk_Pokemon_Pokedex FOREIGN KEY (idPokemon) REFERENCES Pokemon(idPokemon),
    CONSTRAINT fk_Dresseur_Pokedew FOREIGN KEY (idDresseur) REFERENCES Dresseur(idDresseur)
);

CREATE TABLE FacteursEspece (
  espece VARCHAR2(20),
  facteurVie FLOAT,
  facteurTaille FLOAT, 
  facteurPoids FLOAT,
  CONSTRAINT pk_facteursEspece PRIMARY KEY (espece)
);


CREATE TABLE Specimen(
  numSpecimen	NUMBER,
  niveau		NUMBER,
  vie           NUMBER,
  taille    NUMBER,
  poids     NUMBER,
  idPokedex 	NUMBER,
  idPokemon	NUMBER,
  CONSTRAINT pasNiveauNega CHECK (niveau > 0),
  CONSTRAINT pasVieNega CHECK (vie > 0),
  CONSTRAINT pasTailleNega CHECK (taille > 0),
  CONSTRAINT pasPoidsNega CHECK (poids > 0),
  CONSTRAINT pk_specimen PRIMARY KEY (numSpecimen, idPokedex),
  CONSTRAINT fk_Pokemon_Specimen FOREIGN KEY (idPokemon) REFERENCES Pokemon(idPokemon)
);
--séquences
CREATE SEQUENCE seq_pokemon_id START WITH 1 INCREMENT BY 1 MINVALUE 1 MAXVALUE 30 CYCLE CACHE 20;
CREATE SEQUENCE seq_pokedex_id START WITH 1 INCREMENT BY 1 MINVALUE 1;
CREATE SEQUENCE seq_dresseur_id START WITH 1 INCREMENT BY 1 MINVALUE 1;

--Index

CREATE INDEX idx_prenom_dresseur ON Dresseur(prenom);
CREATE INDEX idx_types_pokemon ON Pokemon(type1, type2);
--view

CREATE VIEW Nb_Meme_Pokemon_Capture AS
  SELECT Count(numSpecimen) AS nbMemePoke
  FROM Specimen
  GROUP BY idPokedex
;

CREATE VIEW nb_Pokemon AS
  SELECT COUNT(DISTINCT idPokemon) AS nbPoke
  FROM Pokemon
;

CREATE VIEW Stats_Pokemon_Capture AS
  SELECT niveau, vie, taille, poids, idPokemon
  FROM Specimen
;

--triggers
-- Trigger pour ajuster les valeurs des spécimens lors de l'insertion ou de la mise à jour

CREATE OR REPLACE TRIGGER specimen_values
BEFORE INSERT OR UPDATE ON Specimen
FOR EACH ROW
DECLARE 
    fT FLOAT;
    fV FLOAT;
    fP FLOAT;
BEGIN
    SELECT facteurTaille INTO fT 
    FROM Pokemon JOIN FacteursEspece ON FacteursEspece.espece = Pokemon.nomEspece 
    WHERE Pokemon.idPokemon = :NEW.idPokemon;
    :NEW.taille := ROUND(:NEW.niveau * (fT));
    
    SELECT facteurVie INTO fV  
    FROM Pokemon JOIN FacteursEspece ON FacteursEspece.espece = Pokemon.nomEspece 
    WHERE Pokemon.idPokemon = :NEW.idPokemon;
    :NEW.vie := ROUND(:NEW.niveau * (fV));
    SELECT facteurPoids INTO fP 
    FROM Pokemon JOIN FacteursEspece ON FacteursEspece.espece = Pokemon.nomEspece 
    WHERE Pokemon.idPokemon = :NEW.idPokemon;
    :NEW.poids := ROUND(:NEW.niveau * (fP));
END specimen_values;
/


-- Trigger pour la gestion de la découverte d'un Pokémon dans le Pokédex

CREATE OR REPLACE TRIGGER Decouverte
BEFORE UPDATE ON Pokedex
FOR EACH ROW
DECLARE
  erreur_changement EXCEPTION;
BEGIN
  if (:OLD.apercu = 1 AND :NEW.apercu <> :OLD.apercu) then
    RAISE erreur_changement;
  end if;

  if ((:OLD.apercu = 0)
  AND (:NEW.apercu = 1)
  AND (:NEW.nbPokemonApercu = :OLD.nbPokemonApercu)) THEN 
    :NEW.nbPokemonApercu := :OLD.nbPokemonApercu + 1;
  end if;
END Decouverte;
/

-- Trigger pour la gestion de la capture d'un Pokémon dans le Pokédex

CREATE OR REPLACE TRIGGER Capture
BEFORE UPDATE ON Pokedex
FOR EACH ROW
DECLARE 
  pas_apercu EXCEPTION;
BEGIN	
  if :NEW.Apercu = 0 then
    RAISE pas_apercu;
  end if;
  if ((:NEW.capture = 0)
  AND (:OLD.capture = 1)
  AND (:NEW.nbPokemonCapture = :OLD.nbPokemonCapture)) THEN 
    :NEW.nbPokemonCapture := :OLD.nbPokemonCapture - 1;
  end if;	
  if (:NEW.nbPokemonCapture = :OLD.nbPokemonCapture) THEN 
    :NEW.nbPokemonCapture := :OLD.nbPokemonCapture + 1;
    INSERT INTO Specimen (numSpecimen, niveau, idPokedex, idPokemon) VALUES (:NEW.nbPokemonCapture , ROUND(DBMS_RANDOM.value(1, 100),2), :NEW.idPokedex, :NEW.idPokemon);
  end if;
END Capture;
/
-- Cette procédure stockée permet de relâcher un spécimen de Pokémon dans le Pokédex.
-- Elle supprime le spécimen spécifié par son numéro et ajuste les numéros des autres spécimens
-- dans le même Pokédex. Si aucun spécimen du même Pokémon n'est restant, le Pokédex est mis à jour
-- pour indiquer que ce Pokémon n'est plus capturé.

CREATE PROCEDURE Relacher (num_spe IN NUMBER, idPokd IN NUMBER) 
IS
id_poke NUMBER;  -- Variable pour stocker l'ID du Pokémon à relâcher
nbtotal NUMBER; -- Variable pour stocker le nombre total de spécimens du même Pokémon dans le Pokédex
CURSOR reglage_num IS  -- Curseur pour récupérer les numéros de spécimen à ajuster
    SELECT numSpecimen
    FROM Specimen
    WHERE numSpecimen > num_spe;
BEGIN 
-- Récupérer l'ID du Pokémon basé sur le numéro de spécimen et l'ID du Pokédex
    SELECT idPokemon INTO id_poke
    FROM Specimen
    WHERE Specimen.numSpecimen = num_spe AND Specimen.idPokedex = idPokd;
    -- Supprimer le spécimen du Pokédex
  DELETE FROM Specimen
  WHERE numSpecimen = num_spe AND Specimen.idPokedex = idPokd;
  -- Ouvrir le curseur pour ajuster les numéros de spécimen
  OPEN reglage_num;
 -- Vérifier si la suppression a réussi
  IF SQL%FOUND THEN --delete succeeded 
-- Calculer le nombre total de spécimens du même Pokémon dans le Pokédex
    SELECT count(*) INTO nbtotal
    FROM Specimen 
    WHERE Specimen.idPokedex = idPokd AND Specimen.idPokemon = id_poke
    GROUP BY Specimen.idPokemon;
-- Si aucun spécimen du même Pokémon n'est restant, mettre à jour le Pokédex pour indiquer qu'il n'est plus capturé
    IF ( nbtotal = 0) THEN	
      UPDATE Pokedex SET capture = 0
      WHERE id_poke = Pokedex.idPokemon ;
    END IF;
-- Ajuster les numéros de spécimen restants
    FOR item IN reglage_num 
        LOOP 
            item.numSpecimen := item.numSpecimen - 1 ;
        END LOOP;
  END IF;
-- Fermer le curseur
  CLOSE reglage_num;
END;
/

--Supprimez les rôles existants qui sont en conflit avec ceux que vous essayez de créer :

DROP ROLE pokedex_manager;
-- Créer le rôle POKEDEX_MANAGER pour l'utilisateur "L3_20"
CREATE ROLE pokedex_manager;

-- Attribuer des droits au rôle POKEDEX_MANAGER
GRANT SELECT, INSERT, UPDATE, DELETE ON Pokedex TO pokedex_manager;
GRANT SELECT, INSERT, UPDATE, DELETE ON Specimen TO pokedex_manager;
GRANT SELECT, INSERT, UPDATE, DELETE ON Pokemon TO pokedex_manager;

-- Accorder le rôle POKEDEX_MANAGER à l'utilisateur L3_20 avec l'option ADMIN
GRANT pokedex_manager TO L3_20;

DROP ROLE dresseur_manager;

--Pour l'utilisateur "L3_32" :
-- Créer le rôle dresseur_manager
CREATE ROLE dresseur_manager;

-- Attribuer des droits au rôle dresseur_manager
GRANT SELECT, INSERT, UPDATE, DELETE ON Dresseur TO dresseur_manager;
GRANT SELECT, INSERT, UPDATE, DELETE ON Specimen TO dresseur_manager;
GRANT SELECT, INSERT, UPDATE, DELETE ON Pokedex TO dresseur_manager;

-- Accorder le rôle dresseur_manager à l'utilisateur L3_32
GRANT dresseur_manager TO L3_32;

