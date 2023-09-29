USE SmartHome;
SET @@SESSION.group_concat_max_len = 150000;
SET SESSION max_execution_time = 10000;
SET SQL_SAFE_UPDATES = 0;

-- Parametri per Apriori
SET @support=0.02;
SET @confidence=0.6;

-- Costante per definire le transazioni
SET @MinLenght=2;	

-- ================================================ --
--                      Indice                      --
-- ================================================ --   

-- 1) Creazione e Popolamento tabella Transazione	(riga 24)		
-- 2) Creazione tabelle C[k] ed L[k]				(riga 87)				
-- 3) Stored procedure Regole Associative 			(riga 230)	
-- 4) Algoritmo Apriori                             (riga 491)

-- ================================================================================ --
--            1)        Creazione e Popolamento tabella Transazione                    --
-- ================================================================================ --   
SELECT GROUP_CONCAT(
					CONCAT('`D', CodDisp, '`', ' INT DEFAULT 0') ORDER BY CodDisp
				   ) INTO @ListDisp
FROM dispositivi;


set @ListDisp = concat('CREATE TABLE transazione(',
						  ' ID INT AUTO_INCREMENT PRIMARY KEY, ', 
                           @ListDisp, 
						  ' )engine = InnoDB default charset = latin1;');

-- si crea la tabella Transazione, che ha come attributi ID, D1, D2....Dn 
DROP TABLE IF EXISTS transazione;
PREPARE creaTransazione FROM @ListDisp;
EXECUTE creaTransazione;

#----Popolamento------
# Serve la lista delle transazioni
#Una transazione coinvolge tutte le operazioni svolte nell'intervallo di tempo [Inizio-@delta, Inizio+@delta] per ogni utente 
#Abbiamo posto @delta= 20 minuti
-- ------------------------------------------ 
 	
WITH Transazioni AS (
SELECT OP.CodDisp,OP.Inizio,
	COUNT(DISTINCT OZ.CodDisp) AS NumDisp,
    GROUP_CONCAT(DISTINCT OZ.CodDisp) AS ListaDisp
FROM operazione OP LEFT OUTER JOIN
operazione OZ ON (OP.Username=OZ.Username) 
WHERE OZ.Inizio>=OP.Inizio-INTERVAL 20 MINUTE AND OZ.Inizio<=OP.Inizio+INTERVAL 20 MINUTE
GROUP BY OP.CodDisp,OP.Inizio,Op.Username),

PresDisp AS (
SELECT T.CodDisp AS Dispositivo,T.Inizio as Inizio,D.CodDisp AS Ordine ,
IF(find_in_set(D.CodDisp,T.listaDisp)>0,1,0) AS Presenze
FROM Transazioni T CROSS JOIN
dispositivi D
WHERE T.NumDisp>=@MinLenght),

RecordTrans AS (
SELECT Dispositivo,Inizio,GROUP_CONCAT(Presenze ORDER BY Ordine) AS Elenco
FROM PresDisp
GROUP BY Inizio,Dispositivo)

SELECT GROUP_CONCAT(CONCAT('(NULL,',elenco,')')) INTO @Inserimento
FROM RecordTrans;

SET @Inserimento=CONCAT('INSERT INTO transazione VALUES',@Inserimento,';');
					
PREPARE PopolaTrans FROM @Inserimento;
EXECUTE PopolaTrans;

#Debug per mostrare la tabella Transazione popolata
-- TABLE transazione;

#--------------------------------------------------------------------------------------------------------------------------------------
-- ================================================================================ --
--            2)                  Creazione tabelle C[k] ed L[k]                                --
-- ================================================================================ -- 

-- Principalmente si genera codice dinamico 
-- per creare le diverse tabelle ad ogni passo iterativo dell'algoritmo

#------------- Funzione per creare C[k]-----------------#
DROP FUNCTION IF EXISTS create_C;
DELIMITER $$
CREATE FUNCTION create_C(k INT)
RETURNS TEXT DETERMINISTIC
BEGIN
	DECLARE i INT DEFAULT 1;
    DECLARE combination_select TEXT DEFAULT '';
	DECLARE vertical_without_repetition TEXT DEFAULT '';
    DECLARE horizontal_without_rep_select TEXT DEFAULT '';
	DECLARE count_support TEXT DEFAULT '';
    DECLARE count_support_where TEXT DEFAULT '';
    DECLARE result TEXT DEFAULT '';
    
WHILE i < k DO
		-- si joina ogni elemento di combination con Dispositivo, poi si unisce, così
        -- da trovare la combinazione senza ripetizioni, in formato verticale
		SET vertical_without_repetition = CONCAT(vertical_without_repetition,
												 'SELECT ID1, ID2, CodDisp 
												  FROM combination 
												  INNER JOIN
												  Dispositivi D ON(D.CodDisp = Item', i,') 
                                                  UNION '
												 );
		
		-- prima parte del select di combination, seleziono gli item[i] di a 
        SET combination_select = CONCAT(combination_select, 'a.Item', i,', ');
		-- trasformo il formato delle combinazioni da verticale a orizzontale
        SET horizontal_without_rep_select = CONCAT(horizontal_without_rep_select, 'MAX(CASE WHEN rownum = ', i,' THEN CodDisp END) Item', i, ', ');
		-- where di support_transactions, l'item deve essere uguale a uno di quelli della combinazione in questione
        SET count_support_where = CONCAT(count_support_where, 'Item = Item', i, ' OR ');
        
        SET i = i + 1;
	END WHILE;

	-- ultimo elemento di horizontal_without_rep_select (i=k)
	SET horizontal_without_rep_select = CONCAT(horizontal_without_rep_select, 'MAX(CASE WHEN rownum = ', i,' THEN CodDisp END) Item', i);
    -- ultimo elemento di support_transactions_where (i=k)
	SET count_support_where = CONCAT(count_support_where, 'Item = Item', i);
     
    SET i = 1;
	WHILE i < k-1 DO
        -- si completa vertical_without_repetition joinando ogni elemento di b con Dispositivo
		SET vertical_without_repetition = CONCAT(vertical_without_repetition,
												 'SELECT ID1, ID2, CodDisp 
												  FROM combination 
												  INNER JOIN
												  Dispositivi D ON(D.CodDisp = Item',i,'Join)
                                                  UNION '
												 );
		-- seconda parte del select di combination, si rinomina ogni b.Item[i] in Item[i]Join							
        SET combination_select = CONCAT(combination_select, 'b.Item', i,' AS Item', i,'Join, ');   
        
		SET i = i + 1;
	END WHILE;
    
	-- si completa combination_select
    SET combination_select = CONCAT(combination_select, 'b.Item', i,' AS Item', i,'Join, a.ID AS ID1, b.ID AS ID2');
    
    -- ultimo elemento di vertical_without_repetition (i=k-1)
	SET vertical_without_repetition = CONCAT(vertical_without_repetition,
											 'SELECT ID1, ID2, CodDisp
											  FROM combination 
											  INNER JOIN
											  Dispositivi D ON(D.CodDisp = Item',i,'Join)'
											 );
                                             
	-- numero di transazioni che hanno tutti gli Item della combinazione										
	SET count_support = CONCAT('SELECT COUNT(*)
								FROM (
									  SELECT ID
									  FROM Items
									  WHERE ', count_support_where, '
									  GROUP BY ID
									  HAVING COUNT(*) = ', k,') AS Z'
							  );
	-- ----------------------
    --   RISULTATO FINALE
    -- ----------------------
	SET result = CONCAT(
						'WITH combination AS 
                        (
							SELECT ', combination_select,'
							FROM L',(k-1),' a 
								 INNER JOIN
								 L',(k-1),' b ON(a.ID < b.ID)  
						), 
                        vertical_without_rep AS
                        (', vertical_without_repetition,'), 
						horizontal_without_rep AS
                        (
							SELECT DISTINCT ', horizontal_without_rep_select, '
                            FROM (
								  SELECT *,
									@row:=if(@prev=CONCAT(ID1, ID2), @row,0) + 1 as rownum,
									@prev:= CONCAT(ID1, ID2)
								  FROM vertical_without_rep, (SELECT @row:=0, @prev:=null) AS R
								  ORDER BY ID1, ID2, CodDisp
								  ) AS S
						    GROUP BY ID1, ID2 
							HAVING MAX(rownum) = ', k,'
                        )
                        SELECT *, ('
							   , count_support, ') / (SELECT COUNT(*) FROM Items) AS Support
                        FROM horizontal_without_rep;'
					   );	-- fine concat
	RETURN result;
END $$
DELIMITER ;

-- -----------------------------------
--  Create_L(k): Funzione per trovare L[k]
-- -----------------------------------
DROP FUNCTION IF EXISTS Create_L;
DELIMITER $$
CREATE FUNCTION Create_L(k INT)
RETURNS TEXT DETERMINISTIC
BEGIN
	DECLARE item_list TEXT DEFAULT '';
	DECLARE i INT DEFAULT 1;
    
    -- Creo la lista degli items
    WHILE i < k DO
		SET item_list = CONCAT(item_list, 'Item', i, ', ');		-- Da i = 1 
		SET i = i + 1;											-- A  i = k-1
    END WHILE;
    SET item_list = CONCAT(item_list, 'Item', i);				-- i = k
    
	RETURN CONCAT(
				   'SELECT ', item_list,', Support, ROW_NUMBER() OVER (ORDER BY ', item_list,') AS ID ',
				   'FROM C', k,
				   ' WHERE Support > @Support');		-- Seleziono i k-LargeItemset
END $$
DELIMITER ;
				
                

-- ================================================================================ --
--            3)        Stored procedure Regole Associative                    --
-- ================================================================================ -- 

/*=========================
association2
===========================*/
DROP procedure IF EXISTS `association2`;
DELIMITER $$
CREATE PROCEDURE `association2`()
BEGIN
#in questa stored procedure si vanno a prendere le coppie e si vanno a scorporare le abitudini in antecedente e conseguente
#andando a capire quali sono le abitudini con confidenza più alta.
DECLARE D0 VARCHAR(4);
DECLARE D1 VARCHAR(4);
DECLARE Supp DOUBLE;
DECLARE fineCoppie INT DEFAULT 0;

DECLARE coppia CURSOR FOR
SELECT L2.Item1, L2.Item2, L2.Support  
FROM L2 ;  

DECLARE CONTINUE HANDLER
FOR NOT FOUND SET fineCoppie=1;

OPEN coppia;
scan: LOOP
FETCH coppia INTO D0,D1,Supp;

IF fineCoppie=1 THEN LEAVE scan;
END IF;

#Associations1_1 (A)->(B)
INSERT INTO association_rule(Antecedente, Conseguente, Confidenza)
SELECT D0 AS ant, D1 AS cons, (Supp/C1.Support) AS conf
FROM C1		
WHERE C1.Item1=D0;

#Associations1_1 (B)->(A)
INSERT INTO association_rule(Antecedente, Conseguente, Confidenza)
SELECT D1 AS ant, D0 AS cons, (Supp/C1.Support) AS conf
FROM C1		
WHERE C1.Item1=D1;

END LOOP;

END$$
DELIMITER ;


/*=========================
association3
===========================*/
DROP procedure IF EXISTS `association3`;
DELIMITER $$
CREATE PROCEDURE `association3`()
BEGIN
#in questa stored procedure si vanno a prendere le terne e si vanno a scorporare le abitudini in antecedente e conseguente
#andando a capire quali sono le abitudini con confidenza più alta.
DECLARE D0 VARCHAR(4);
DECLARE D1 VARCHAR(4);
DECLARE D2 VARCHAR(4);
DECLARE Supp DOUBLE;

DECLARE fineTerne INT DEFAULT 0;
DECLARE terna CURSOR FOR
SELECT L3.Item1, L3.Item2, L3.Item3, L3.Support
FROM L3; 

DECLARE CONTINUE HANDLER
FOR NOT FOUND SET fineTerne=1;

OPEN terna;
scan: LOOP
FETCH terna INTO D0,D1,D2,Supp;

IF fineTerne=1 THEN LEAVE scan;
END IF;


#Associations2_1 (A,B)->(C)
INSERT INTO association_rule(Antecedente, Conseguente, Confidenza)
SELECT CONCAT(D0,", ",D1) AS ant, D2 AS cons, Supp/C2.Support AS conf
FROM C2  
WHERE (C2.Item1=D0 AND C2.Item2=D1) OR (C2.Item1=D1 AND C2.Item2=D0);  	-- A,B e B,A

#(B,C)->(A)
INSERT INTO association_rule(Antecedente, Conseguente, Confidenza)
SELECT CONCAT(D1,", ",D2) AS ant, D0 AS cons, Supp/C2.Support AS conf
FROM C2
WHERE (C2.Item1=D1 AND C2.Item2=D2) OR (C2.Item1=D2 AND C2.Item2=D1);

#(C,A)->(B)
INSERT INTO association_rule(Antecedente, Conseguente, Confidenza)
SELECT CONCAT(D2,", ",D0) AS ant, D1 AS cons, Supp/C2.Support AS conf
FROM C2
WHERE (C2.Item1=D2 AND C2.Item2=D0) OR (C2.Item1=D0 AND C2.Item2=D2);


#Associations1_2 (A)->(B,C)
INSERT INTO association_rule(Antecedente, Conseguente, Confidenza)
SELECT D0 AS ant, CONCAT(D1,", ",D2) AS cons, Supp/C1.Support AS conf
FROM C1
WHERE C1.Item1=D0;
#(B)->(C,A)
INSERT INTO association_rule(Antecedente, Conseguente, Confidenza)
SELECT D1 AS ant, CONCAT(D2,", ",D0) AS cons, Supp/C1.Support AS conf
FROM C1
WHERE C1.Item1=D1;
#(C)->(A,B)
INSERT INTO association_rule(Antecedente, Conseguente, Confidenza)
SELECT D2 AS ant, CONCAT(D0,", ",D0) AS cons, Supp/C1.Support AS conf
FROM C1
WHERE C1.Item1=D2;


END LOOP;
END$$
DELIMITER ;

/*=========================
association4
===========================*/
DROP procedure IF EXISTS `association4`;
DELIMITER $$
CREATE PROCEDURE `association4`()
BEGIN
#in questa stored procedure si vanno a prendere le quaterne e si vanno a scorporare le abitudini in antecedente e conseguente
#andando a capire quali sono le abitudini con confidenza più alta.
DECLARE D0 VARCHAR(4);
DECLARE D1 VARCHAR(4);
DECLARE D2 VARCHAR(4);
DECLARE D3 VARCHAR(4);
DECLARE Supp DOUBLE;
DECLARE i INT DEFAULT 0;
DECLARE j INT DEFAULT 0;
DECLARE w INT DEFAULT 0;
DECLARE s INT DEFAULT 0;
DECLARE cont INT DEFAULT 0;

DECLARE fineQuat INT DEFAULT 0;
DECLARE Quat CURSOR FOR
SELECT L4.Item1, L4.Item2, L4.Item3, L4.Item4, L4.Support
FROM L4; 

DECLARE CONTINUE HANDLER
FOR NOT FOUND SET fineQuat=1;

OPEN Quat;
scan: LOOP
FETCH Quat INTO D0,D1,D2,D3,Supp;

IF fineQuat=1 THEN LEAVE scan;
END IF;
-- Association1_3 (A)->(B,C,D) (B)->(A,C,D) (C)->(A,B,C) (D)->(A,B,C)
 WHILE cont<4 DO
IF cont=0 THEN
	SET i=D0;
	SET j=D1;
	SET w=D2;
	SET s=D3; END IF;
IF cont=1 THEN
	SET i=D1; 
	SET j=D0;
	SET w=D2;
	SET s=D3; END IF;
IF cont=2 THEN
	SET i=D2;
	SET j=D0;
	SET w=D1;
	SET s=D3; END IF;
IF cont=3 THEN 
	SET i=D3;
	SET j=D0;
	SET w=D1;
	SET s=D2; END IF;
    
INSERT INTO association_rule(Antecedente, Conseguente, Confidenza)
SELECT i AS ant, CONCAT(j,", ",w,",",s) AS cons, Supp/C1.Support AS conf
FROM C1
WHERE C1.Item1=i;   
SET cont=cont+1;
 END WHILE;


-- Association2_2 (A,B)->(C,D) (A,C)->(B,D) (A,D)->(B,C) (B,C)->(A,D) (B,D)->(A,C) (C,D)->(A,B)
SET cont=0;
SET i=D0; SET j=D1; SET w=D0; SET s=D0;
-- primo while i è sempre uguale a D0 
	WHILE cont<3 DO 
    IF cont=0 THEN
	SET j=D1; SET w=D2; SET s=D3; END IF;
	IF cont=1 THEN 
		SET j=D2; SET w=D1; SET s=D3; END IF;
	IF cont=2 THEN 
		SET j=D3; SET w=D1; SET s=D2; END IF;
    INSERT INTO association_rule(Antecedente, Conseguente, Confidenza)
						 SELECT CONCAT(i,',',j) AS ant, CONCAT(w,',',s) AS cons, Supp/C2.Support AS conf
						 FROM C2  
						 WHERE (C2.Item1=i AND C2.Item2=j) OR (C2.Item1=j AND C2.Item2=i);    
SET cont=cont+1;
    END WHILE;
    
-- "scorro" i=D1
SET i=D1; SET cont=2; 
WHILE cont<=3 DO 
	IF cont=2 THEN 
		SET j=D2; SET w=D0; SET s=D3; END IF;
	IF cont=3 THEN 
		SET j=D3; SET w=D0; SET s=D2; END IF;
        
	INSERT INTO association_rule(Antecedente, Conseguente, Confidenza)
			    SELECT CONCAT(i,',',j) AS ant, CONCAT(w,',',s) AS cons, Supp/C2.Support AS conf
				FROM C2  
				WHERE (C2.Item1=i AND C2.Item2=j) OR (C2.Item1=j AND C2.Item2=i);
SET cont=cont+1;
END WHILE;

-- ultimo caso i=D2
SET i=D2; SET j=D3; 
 SET w=D0; SET s=D1;
 INSERT INTO association_rule(Antecedente, Conseguente, Confidenza)
			SELECT CONCAT(i,',',j) AS ant, CONCAT(w,',',s) AS cons, Supp/C2.Support AS conf
			FROM C2  
			WHERE (C2.Item1=i AND C2.Item2=j) OR (C2.Item1=j AND C2.Item2=i);
            
            
--  Association3_1 (A,B,C)->(D) (B,C,D)->(A) (A,D,C)->(B) (A,B,D)->(C)    
SET cont=0;
WHILE cont<4 DO
IF cont=0 THEN
SET j=D0;
SET w=D1;
SET S=D2;
SET i=D3;END IF;
IF cont=1 THEN
SET j=D1;
SET w=D2;
SET S=D3;
SET i=D0;END IF;
IF cont=2 THEN
SET j=D0;
SET w=D3;
SET S=D2;
SET i=D1; END IF;
IF cont=3 THEN
SET j=D0;
SET w=D1;
SET S=D3;
SET i=D2;END IF;

INSERT INTO association_rule(Antecedente, Conseguente, Confidenza)
			SELECT CONCAT(j,',',w,',',s) AS ant, i AS cons, Supp/C3.Support AS conf
			FROM C3  
			WHERE (C3.Item1=j AND C3.Item2=w AND C3.Item3=s) OR (C3.Item1=j AND C3.Item2=s AND C3.Item3=w) OR (C3.Item1=s AND C3.Item2=j AND C3.Item3=w)
				OR (C3.Item1=s AND C3.Item2=w AND C3.Item3=j) OR (C3.Item1=w AND C3.Item2=s AND C3.Item3=j) OR (C3.Item1=w AND C3.Item2=j AND C3.Item3=s);

SET cont=cont+1;
END WHILE;

END LOOP;
CLOSE Quat;
END $$
DELIMITER ;

-- ================================================================================ --
--            4)                  Algoritmo Apriori                                 --
-- ================================================================================ --  
DROP PROCEDURE IF EXISTS Apriori;
DELIMITER $$
CREATE PROCEDURE Apriori(IN max INT) -- max sono i passaggi massimi da fare
BEGIN
	DECLARE k INT DEFAULT 2;
    DECLARE i INT DEFAULT 2;
    
	-- tabella Item(ID, Item), serve per calcolare più velocemente il supporto
	SELECT GROUP_CONCAT( 
						CONCAT('SELECT ID, ', CodDisp,' as Item ' 
							   'FROM Transazione ',
							   'WHERE D', CodDisp, '<> 0') 
						SEPARATOR ' UNION ') INTO @transaction_items
	FROM Dispositivi;

	set @transaction_items = concat('create table Items as ',
										@transaction_items, ';');
                                        
	DROP TABLE IF EXISTS Items;
	PREPARE create_table_Items FROM @transaction_items;
	EXECUTE create_table_Items;
   
   #Debug per mostrare la tabella Items
    -- TABLE Items;
    
    -- CREO LA TABELLA C1(Item1, Support)
    DROP TABLE IF EXISTS C1;
    CREATE TABLE C1 AS
    SELECT Item AS Item1, COUNT(*) / (SELECT COUNT(*) FROM Transazione) AS Support
    FROM Items
    GROUP BY Item;
    
	-- CREO LA TABELLA L1(Item1, Support, ID)
    DROP TABLE IF EXISTS L1;
    CREATE TABLE L1 AS
    SELECT *, ROW_NUMBER() OVER(ORDER BY Item1) AS ID		-- assegno ad ogni record un ID univoco
    FROM C1
    WHERE Support > @Support;
    
    #Debug per mostrare le tabelle C1 e L1
    TABLE C1;
	TABLE L1;
    
    -- LOOP da k = 2 fino a max, per creare le tabelle C[k] e L[k]
    -- se L[k] è vuoto si ferma
    loop_label: LOOP
		IF k > max THEN
			LEAVE loop_label;
		END IF;
        
		SET @dropCk = concat('DROP TABLE IF EXISTS C', k, ';');
		SET @getCk = concat('CREATE TABLE C',k,' AS ', create_C(k));
		SET @dropLk = concat('DROP TABLE IF EXISTS L', k, ';');
		SET @getLk = concat('CREATE TABLE L',k,' AS ', create_L(k));

        -- CREO LA TABELLA C[k]
        PREPARE DropCk FROM @dropCk;
        EXECUTE DropCk;
        PREPARE GetCk FROM @getCk;
        EXECUTE GetCk;
        
        -- CREO LA TABELLA L[k]
		PREPARE DropLk FROM @dropLk;
        EXECUTE DropLk;
        PREPARE GetLk FROM @getLk;
        EXECUTE GetLk;
        
        -- mostra le tabelle C ed L ad ogni passo
        SET @C= concat('table C', k, ';');
        PREPARE debugC FROM @C;
        EXECUTE debugC;
         SET @L= concat('table L', k, ';');
        PREPARE debugL FROM @L;
        EXECUTE debugL;
        
        -- CONTROLLO che L[k] non sia vuoto. Se sì, esco dal loop
        SET @Lk_empty = CONCAT('SELECT EXISTS (SELECT 1 FROM L', k,') INTO @empty;');
        PREPARE Lk_empty FROM @Lk_empty;
        EXECUTE Lk_empty;
        IF @empty = 0 THEN
			LEAVE loop_label;
		END IF;
        
		SET k = k + 1;
    END LOOP;
	
    -- Creo la tabella Association_rule
   CREATE TABLE IF NOT EXISTS Association_rule
	(
		ID INT PRIMARY KEY AUTO_INCREMENT,
		Antecedente VARCHAR(100) DEFAULT " ",
		Conseguente VARCHAR(100) DEFAULT " ",
		Confidenza DOUBLE DEFAULT 0
	);
	 TRUNCATE Association_rule;

    SELECT k;
    WHILE i < k DO
		SET @rules= concat('CALL association', i,';');
        PREPARE rules FROM @rules;
        EXECUTE rules;
        SET i = i + 1;
	END WHILE;
	 -- TABLE Association_rule;
    
    -- Vengono eliminate le regole non forti
    -- E' mostrata la tabella risultante delle regole forti
   DELETE FROM Association_rule
   WHERE Confidenza < @Confidence;
   TABLE Association_rule;
    
END $$
DELIMITER ;


-- ================================ --
--    TEST STORED PROCEDURE       --
-- ================================ --
SELECT COUNT(*) INTO @num_disp
FROM Dispositivi;
CALL Apriori(@num_disp);



                