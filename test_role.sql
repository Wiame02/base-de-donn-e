--pour utilisateur L3_32
-- Insérer des données dans la table Dresseur en utilisant les valeurs des séquences
INSERT INTO Dresseur (idDresseur, nom, prenom, adresse) VALUES (seq_dresseur_id.NEXTVAL, 'KETCHUM', 'Sacha', '5 rue du Bourg Palette, Kanto');
INSERT INTO Dresseur (idDresseur, nom, prenom, adresse) VALUES (seq_dresseur_id.NEXTVAL, 'MAY', 'Flora', '46 avenue d Oliville, Johto');
INSERT INTO Dresseur (idDresseur, nom, prenom, adresse) VALUES (seq_dresseur_id.NEXTVAL, 'CHEN', 'Regis', '11 rue d Argenta, Johto');
INSERT INTO Dresseur (idDresseur, nom, prenom, adresse) VALUES (seq_dresseur_id.NEXTVAL, 'MISTY', 'Ondine', '102 Arène Azuria, Kanto');

-- Sélectionner des données depuis la table Dresseur pour vérifier l'insertion
SELECT * FROM Dresseur;

--pour utilisateur L3_20
-- Connexion à la base de données en utilisant un compte utilisateur ayant le rôle pokedex_manager

-- Insérer des données dans la table Pokedex
INSERT INTO Pokedex (idPokedex, idPokemon, idDresseur, apercu, capture, nbPokemonApercu, nbPokemonCapture) 
VALUES (seq_pokedex_id.nextval, seq_pokemon_id.nextval, 25, 1, 1, 27, 24);

INSERT INTO Pokedex (idPokedex, idPokemon, idDresseur, apercu, capture, nbPokemonApercu, nbPokemonCapture) 
VALUES (seq_pokedex_id.currval, seq_pokemon_id.nextval, 25, 1, 1, 27, 24);

INSERT INTO Pokedex (idPokedex, idPokemon, idDresseur, apercu, capture, nbPokemonApercu, nbPokemonCapture) 
VALUES (seq_pokedex_id.currval, seq_pokemon_id.nextval, 25, 1, 1, 27, 24);
-- Sélectionner des données depuis la table Pokedex pour vérifier l'insertion
SELECT * FROM Pokedex;

