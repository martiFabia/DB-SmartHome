
USE SmartHome;

-- Per ogni utente guardo i dispositivi più frequenti e suggerisco la fascia oraria giusta 
-- in cui utilizzarli , tenendo conto del consumo,dell'energia prodotta e dei costi.

DROP TABLE IF EXISTS MV_DispPiuFreq;
CREATE TABLE MV_DispPiuFreq(
Username varchar (50) NOT NULL,
Dispositivo integer not null,
Settaggio integer not null,
Inizio datetime not null,
Fine datetime default null,
Consumo double default 0,
PRIMARY KEY(Username,Dispositivo,Settaggio))
Engine=InnoDB DEFAULT CHARSET=latin1;


DROP PROCEDURE IF EXISTS AggMv;
DELIMITER $$
CREATE PROCEDURE AggMv(temp timestamp)
BEGIN 
DECLARE Nome varchar (50) default ' ';
DECLARE Dispositivo,Settaggio integer default 0;
DECLARE Inizio,Fine datetime default null;
DECLARE Totale double default 0;
DECLARE finito integer default 0;

DECLARE cursore CURSOR FOR 
	SELECT Username
	FROM account;
DECLARE cursoreMV CURSOR FOR
	SELECT MV.Username,MV.Dispositivo,MV.Settaggio,MV.Inizio,MV.Fine
    FROM MV_DispPiuFreq MV;

DECLARE CONTINUE handler for not found SET finito=1;
OPEN cursore;
preleva : LOOP
fetch cursore into Nome;
	IF finito=1 THEN LEAVE preleva; END IF;
	INSERT INTO MV_DispPiuFreq (Username,Dispositivo,Settaggio,Inizio,Fine)  -- Per ogni utente si calcola il o i dispositivi più frequenti
	SELECT O.Username,O.CodDisp,O.CodOp,O.Inizio,O.Fine
        FROM operazione O
        WHERE DATE(O.Inizio)<DATE(temp) AND DATE(O.Inizio)>=DATE_SUB(DATE(temp),INTERVAL 7 DAY)
        AND O.Username=Nome
        GROUP BY O.Username,O.CodDisp,O.CodOp
        HAVING count(*)>=ALL(SELECT count(*)
							FROM operazione O
							WHERE DATE(O.Inizio)<DATE(temp) AND DATE(O.Inizio)>=DATE_SUB(DATE(temp),INTERVAL 7 DAY)
                             AND O.Username=Nome
							GROUP BY O.Username,O.CodDisp,O.CodOp);

    END LOOP;
    CLOSE cursore;
SET finito=0;

OPEN cursoreMV;
prel:LOOP
	fetch cursoreMV into Nome,Dispositivo,Settaggio,Inizio,Fine;
  
    if finito=1 THEN LEAVE prel;END IF;
    CALL CalcoloConsumoOp(Nome,Dispositivo,Settaggio,Inizio,Fine,@fascia,Totale);     -- Calcola il consumo dei dispositivi più frequenti inseriti sopra
   
    UPDATE MV_DispPiuFreq MV
    SET MV.Consumo=Totale
    WHERE MV.Username=Nome AND MV.Dispositivo=Dispositivo AND MV.Settaggio=Settaggio
		AND MV.Inizio=Inizio AND MV.Fine=Fine;
        END LOOP;
        CLOSE cursoreMV;
END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS CreaSugg;
DELIMITER $$
CREATE PROCEDURE CreaSugg(temp datetime)
BEGIN 
	DECLARE Contatore,finito,Dispositivo,Settaggio integer default 0; -- Contatore
	DECLARE EnCons,EnProd,Costo,Rendimento,RendimentoMax double default 0;
    DECLARE fascia,fasciaMax varchar(3) default ' ';
    DECLARE Username varchar(25) default ' ';
    
		DECLARE cursore CURSOR FOR
        SELECT MV.Username,MV.Dispositivo,MV.Settaggio,MV.Consumo
        FROM mv_disppiufreq MV;
        
	DECLARE CONTINUE HANDLER FOR 
    NOT FOUND SET finito=1;
	
OPEN cursore;
Prel:LOOP
	 DROP TABLE IF EXISTS rend;
    CREATE TABLE rend(			-- Tabella per il rendimento massimo
	fascia varchar(3) default ' ',
	Rendimento double default 0);

FETCH cursore INTO Username,Dispositivo,Settaggio,EnCons;
IF finito=1 THEN leave Prel; END IF;
    SET Contatore=0;
    WHILE Contatore<4 DO		-- Così facendo iteri una volta per fascia
    SET Rendimento=0;       -- lo azzero tutte le volte per evitare bug
    IF (HOUR(temp)>=0 AND HOUR(temp)<=6) THEN SET fascia='F1';  END IF;
IF (HOUR(temp)>=7 AND HOUR(temp)<=12) THEN SET fascia='F2'; END IF;
IF (HOUR(temp)>12 AND HOUR(temp)<=18) THEN SET fascia='F3'; END IF;
IF(HOUR(temp)>18 AND HOUR(temp)<=24) THEN SET fascia='F4'; END IF;

    SET EnProd=(SELECT AVG(EP.Quantita)					-- Media dell'energia prodotta nella determinata fascia oraria durante la settimana
				FROM energiaprodotta EP
                WHERE EP.FasciaOraria=fascia AND DATE(EP.Timestamp)<DATE(temp) AND DATE(EP.Timestamp)>=DATE_SUB(DATE(temp),INTERVAL 7 DAY)
                );
           
    IF(EnCons>EnProd) THEN    -- se l'energia prodotta basta non fa niente --> rendimento=0;
    
    SET Costo=(SELECT avg(S.CostoUnitPerFascia)         -- Costo della fascia selezionata
			FROM spesa S
			WHERE S.FasciaOraria=fascia AND S.Data<DATE(temp) AND S.Data>=DATE_SUB(DATE(temp),INTERVAL 7 DAY)
                );
    SET Rendimento=EnProd/Costo;
   
			 END IF;
            
	insert into rend 
    values (fascia,Rendimento);
    SET Contatore=Contatore+1;
    SET temp=timestampadd(HOUR,6,temp);
    END WHILE;
    
	SELECT max(P.Rendimento) into RendimentoMax
	FROM rend P
	LIMIT 1;
    
	select R.fascia INTO fasciaMax
   FROM rend R 
   WHERE R.Rendimento=RendimentoMax
   LIMIT 1; 
  

       #-------------------Creazione Suggerimento---------------------------
     INSERT INTO suggerimento(DataOra,CodDisp,CodOp,Messaggio,Username,Inizio)
     VALUES (current_timestamp(),Dispositivo,Settaggio,'Vuoi accendere il dispositivo?',Username,fasciaMax);
     

 END LOOP; 
 CLOSE cursore;
 
END $$
DELIMITER ;


-- SELECT * 
-- FROM suggerimento;

-- ==================================== --
-- 		EVENT AGGIORNAMENTO TABELLA SUGGERIMENTO 	--
-- ==================================== --

DROP EVENT IF EXISTS OTTIMIZZA;
DELIMITER $$
CREATE EVENT OTTIMIZZA
ON SCHEDULE EVERY 7 DAY
DO
BEGIN 
	TRUNCATE MV_DispPiuFreq;
	CALL AggMv('2021-08-15 4:00');
    CALL CreaSugg('2021-08-15 4:00');
END $$
    


-- ==================================== --
-- 		TRIGGER GESTIONE RISPOSTA SUGGERIMENTO		--
-- ==================================== --

DROP TRIGGER IF EXISTS RispSugg;
DELIMITER $$
CREATE TRIGGER RispSugg
AFTER UPDATE ON suggerimento
FOR EACH ROW
BEGIN 
	DECLARE InizioOp datetime;
    DECLARE DurataOp integer default 0;

	IF(new.Scelta='Si') THEN 
    
	IF (new.Inizio='F1') THEN SET InizioOp='date(new.DataOra) 00:00';  END IF;
	IF (new.Inizio='F2') THEN SET InizioOp='date(new.DataOra) 06:00'; END IF;
	IF (new.Inizio='F3') THEN SET InizioOp='date(new.DataOra) 12:00'; END IF;
	IF(new.Inizio='F4') THEN SET InizioOp='date(new.DataOra) 18:00'; END IF;
    
    IF EXISTS (SELECT *
				FROM Operazione O
				WHERE O.CodDisp = NEW.CodDisp AND
						 O.Inizio <= InizioOp AND
                         (O.Fine IS NULL OR O.Fine > InizioOp)) THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Non è possibile avviare il programma poiché il dispositivo è già in funzione.';
	END IF;
    
	SET DurataOp= ( SELECT Durata
					FROM Programma P
                    WHERE P.CodDisp=new.CodDisp AND  P.CodOp=new.CodOp);
	IF (DuaratOp is null) THEN 
		SET DurataOp=120; 		-- se il dispositivo non è a ciclo non interrompibile l'operazione viene fatta durare 2h di deafault
	END IF;
    
    INSERT INTO operazione (Username, CodOp, CodDisp, Inizio, Fine)
    values (new.Username, new.CodOp, new.CodDisp, InizioOp, InizioOp+ interval DurataOp minute);
    END IF;
    END $$ 
    DELIMITER ;
    


