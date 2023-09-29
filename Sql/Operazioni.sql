USE SmartHome;

#--- OP 1 --------CREAZIONE di un ACCOUNT -----------------------
DROP PROCEDURE IF EXISTS CreazioneAccount; 
DELIMITER $$
CREATE PROCEDURE CreazioneAccount 	(
									in codfiscale varchar(50), --
									in nome varchar(50), --
                                    in cognome varchar(50), --
                                    in datanascita date, --
									in telefono double, --
                                    in Username varchar(50), 
                                    in Password varchar(50), 
                                    in domanda varchar(255), 
                                    in risposta varchar(255), 
                                    in tipo varchar(50), 
                                    in Datascadenza date, 
                                    in ente varchar(50), 
                                    in CodiceId varchar(50) -- 
									)
BEGIN
    
    if datediff(current_date, Datascadenza) < 0 && (length(Password) > 7 && length(Username) > 3) then 
		begin 
			insert into utente values (codfiscale, nome, cognome, datanascita, telefono, current_date);
            insert into documento values (codFiscale, CodiceId, tipo,ente, Datascadenza); 
            insert into account values (Username, password, codFiscale); 
            insert into recupero values (Username, domanda, risposta);
        end ; 
	else 
    signal sqlstate '45000'
    set message_text='Errore, dati non corretti. Indicare un documento non scaduto e/o una password lunga almeno 8 caratteri e/o un nome utente lungo 4';
	end if;

END $$
DELIMITER ; 

#--------- Operazione 2------------CALCOLO COSNUMO DI UN OPERAZIONE-------
DROP PROCEDURE IF EXISTS CalcoloConsumoOp;
DELIMITER $$
CREATE PROCEDURE CalcoloConsumoOp(Username varchar(50),CodDisp integer,CodOp integer, Inizio datetime, Fine datetime,OUT fasciaOp varchar (3),OUT Tot double)
BEGIN 
DECLARE toth double default 0;
DECLARE durata double default 0;

IF (HOUR(Inizio)>=0 AND HOUR(Inizio)<=6) THEN SET fasciaOp='F1'; END IF;
IF (HOUR(Inizio)>=7 AND HOUR(Inizio)<=12) THEN SET fasciaOp='F2'; END IF;
IF (HOUR(Inizio)>12 AND HOUR(Inizio)<=18) THEN SET fasciaOp='F3'; END IF;
IF(HOUR(Inizio)>18 AND HOUR(Inizio)<=24) THEN SET fasciaOp='F4'; END IF;

IF (CodDisp<=6) THEN 
SET toth=(SELECT C.ConsCond
		FROM settaggio S NATURAL JOIN condizionatore C
        WHERE (S.CodDisp =CodDisp AND S.CodOP=CodOp));END IF;
IF (CodDisp>6 AND CodDisp<=31) THEN 
SET toth=(SELECT L.ConsLuce
		FROM settaggio S NATURAL JOIN luce L
        WHERE (S.CodDisp =CodDisp AND S.CodOP=CodOp));END IF;
IF (CodDisp>31 AND CodDisp<=34) THEN 
SET Tot=(SELECT P.ConsMedio*(P.Durata/60)
		FROM settaggio S NATURAL JOIN programma P
        WHERE (S.CodDisp =CodDisp AND S.CodOP=CodOp));END IF;
        IF (CodDisp>34) THEN 
SET toth=(SELECT L.Consumo
		FROM settaggio S NATURAL JOIN livello L
        WHERE (S.CodDisp =CodDisp AND S.CodOP=CodOp));END IF;
IF Fine IS NOT NULL THEN
SET durata= HOUR(TIMEDIFF(Inizio,Fine));
SET Tot=toth*durata;
END IF;
IF Tot IS NULL THEN SET Tot=0; END IF;
END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS AggConsumata;
DELIMITER $$
CREATE PROCEDURE AggConsumata(Inizio datetime,fascia varchar(3),Tot double)
BEGIN 
UPDATE energiaconsumata
SET QuantitaConsumata=QuantitaConsumata+Tot
WHERE FasciaOraria=fascia AND Data=Date(Inizio);
END $$ DELIMITER ;



#-----OP 3 ------- Calcolo EnConsumata dalla casa nell'ultima settimana ---------------

DROP PROCEDURE IF EXISTS energia_settimana;
DELIMITER $$ 
CREATE PROCEDURE  energia_settimana (in _data date, out TotEnergia double)
BEGIN 

set TotEnergia= ( SELECT sum(EC.Quantitaconsumata)
				  FROM energiaconsumata EC
                  WHERE EC.Data between _data - interval 7 day AND _data
						AND EC.QuantitaConsumata is not null);

END $$
DELIMITER ;


-- call energia_settimana('2021-08-05',@consumo);
-- select @consumo AS ConsumoSett; -- */



#------------------Operazione 4----------SETTAGGIO PIU FREQUENTE DI UN DISPOSITIVO------ 

DROP PROCEDURE IF EXISTS SettPiuFreq;
DELIMITER $$
CREATE PROCEDURE SettPiuFreq(Codice integer)
BEGIN

		SELECT O.CodOp AS SettaggioPiuFreq 
         FROM operazione O
            WHERE O.CodDisp=Codice
            GROUP BY O.CodOp,O.CodDisp
            HAVING count(*)>= ALL(SELECT count(*)
							FROM operazione P
							WHERE P.CodDisp=Codice 
							GROUP BY P.CodOp,P.CodDisp);

END$$
DELIMITER ;

-- CALL SettPiuFreq(3);


#----- OP 5 ------- Vedere dispositivi accesi ------------------------

DROP PROCEDURE IF EXISTS dispositivi_accesi;
DELIMITER $$
CREATE PROCEDURE dispositivi_accesi()
BEGIN
	select CodDisp, NomeDisp
	from dispositivi
	where Stato='1';
END $$
DELIMITER ;

-- call dispositivi_accesi();

#----------Operazione 6-----------CLASSIFICA MENSILE DEI CONSUMI------
DROP PROCEDURE IF EXISTS ClassificaConsumi;
DELIMITER $$
CREATE PROCEDURE ClassificaConsumi(temp date)
BEGIN 
DECLARE Usern varchar (50) default ' ';
DECLARE Inizio,Fine Datetime;
DECLARE CodOp,CodDisp,finito integer default 0;
DECLARE Tot,toth double default 0;
DECLARE durata double default 1;
DECLARE cursore CURSOR FOR 
	SELECT Username
	FROM account;
    
DECLARE cursoreCons CURSOR FOR
	SELECT O.Username,O.CodOp,O.CodDisp,O.Inizio,O.Fine
    FROM operazione O 
    WHERE DATE(O.Inizio)>=DATE_SUB(temp,INTERVAL 30 DAY)
	AND DATE(O.Inizio)<=temp;
    
DECLARE CONTINUE HANDLER 
FOR NOT FOUND SET finito=1;
-- DROP temporary table classifica;
CREATE TEMPORARY TABLE IF NOT EXISTS classifica(
Username varchar (50) Not NULL,
Consumo double default 0,
PRiMARY KEY (Username)
)Engine=InnoDB DEFAULT CHARSET=latin1;

OPEN cursore;
preleva:LOOP
		FETCH cursore INTO Usern;
         IF finito=1 THEN leave preleva; END IF;
        insert into classifica (Username)
        value (Usern);
       END LOOP preleva;
CLOSE cursore;

SET finito=0;
OPEN cursoreCons;
prel: LOOP
	FETCH cursoreCons INTO Usern,CodOp,CodDisp,Inizio,Fine;
    IF finito=1 THEN LEAVE prel;END IF;
IF (CodDisp<=6) THEN 
	SET toth=(SELECT C.ConsCond
		FROM settaggio S NATURAL JOIN condizionatore C
        WHERE (S.CodDisp =CodDisp AND S.CodOP=CodOp));END IF;
IF (CodDisp>6 AND CodDisp<=31) THEN 
	SET toth=(SELECT L.ConsLuce
		FROM settaggio S NATURAL JOIN luce L
        WHERE (S.CodDisp =CodDisp AND S.CodOP=CodOp));END IF;
IF (CodDisp>31 AND CodDisp<=34) THEN 
	SET Tot=(SELECT P.ConsMedio*(P.Durata/60)
		FROM settaggio S NATURAL JOIN programma P
        WHERE (S.CodDisp =CodDisp AND S.CodOP=CodOp));END IF;
IF (CodDisp>34) THEN 
	SET toth=(SELECT L.Consumo
		FROM settaggio S NATURAL JOIN livello L
        WHERE (S.CodDisp =CodDisp AND S.CodOP=CodOp));END IF;

IF Fine IS NOT NULL THEN
	SET durata= HOUR(TIMEDIFF(Inizio,Fine));
	SET Tot=toth*durata;
END IF;

IF Tot IS NOT NULL THEN
	UPDATE classifica
	SET Consumo=Consumo+Tot
	WHERE Username=Usern; END IF;
END LOOP prel;
SELECT Username,Consumo, DENSE_RANK() OVER(ORDER BY Consumo DESC) AS Posizione
 FROM classifica;
END $$
DELIMITER ;

-- CALL ClassificaConsumi('2021-08-30');

#----- OP 7 ------- Inserimento in Contatore Bidirezionale ---------
DROP PROCEDURE IF EXISTS ins_contBid;
DELIMITER $$
CREATE PROCEDURE ins_contBid (in _FasciaOraria varchar(2),in _Data date,in _ConteggioEn double, in _EnRete double)
BEGIN 
	insert into contatorebidirezionale (FasciaOraria,Data,ConteggioEn,EnRete)
	values (_FasciaOraria,_Data,_ConteggioEn,_EnRete);
    
END $$
DELIMITER ;



#----------------Operazione 8----------CALCOLO SPESA MENSILE-------
DROP PROCEDURE IF EXISTS CalcoloSpesaMens;
DELIMITER $$
CREATE PROCEDURE CalcoloSpesaMens(temp1 timestamp)
BEGIN
DECLARE I integer default 0;
DECLARE SpesaTot double default 0;
DECLARE SpesaFascia double default 0;
DECLARE CostoFascia integer default 0;
DECLARE Conteggio, EnImmessa double default 0;
DECLARE fascia varchar (3) default ' ';
WHILE I<=120 DO
IF (HOUR(temp1)>=0 AND HOUR(temp1)<=6) THEN SET fascia='F1';  END IF;
IF (HOUR(temp1)>=7 AND HOUR(temp1)<=12) THEN SET fascia='F2'; END IF;
IF (HOUR(temp1)>12 AND HOUR(temp1)<=18) THEN SET fascia='F3'; END IF;
IF(HOUR(temp1)>18 AND HOUR(temp1)<=24) THEN SET fascia='F4'; END IF;

SET Conteggio =(SELECT ConteggioEn
				FROM contatorebidirezionale
                WHERE FasciaOraria=fascia AND Data=DATE(temp1));
SET Conteggio=(Conteggio/1000); -- IN KWh;

SET CostoFascia=(SELECT CostoUnitperFascia
				FROM spesa
                WHERE FasciaOraria=fascia AND Data=DATE(temp1));
                
IF(Conteggio<0) THEN		-- ho consumato energia extra quindi ho una spesa
	SET SpesaFascia=(Conteggio *CostoFascia)*-1; END IF;
IF (Conteggio>0) THEN 
    SET SpesaFascia=0;		-- energia prodotta mi è bastata a coprire il mio consumo quindi spesa nulla
    END IF;
IF (Conteggio=0) THEN 		-- l'utente ha scelto di immettere energia in rete quindi si ha un "guadagno"
	SET EnImmessa=(SELECT EnRete
				   FROM contatorebidirezionale
				   WHERE FasciaOraria=fascia AND Data=DATE(temp1));
	SET EnImmessa=EnImmessa/1000;
	SET SpesaFascia= (EnImmessa*(CostoFascia*0.8))*-1;			-- negativo perchè fa diminuire la spesa totale, 
																-- quando immetto energia in rete guadagno l'80% del costo che spenderei se consumassi energia
    END IF;
    
SET SpesaTot=SpesaTot+SpesaFascia;
SET temp1=timestampadd(HOUR,6,temp1);
SET I=I+1;
END WHILE;

IF (SpesaTot>=0) THEN 
	SELECT SpesaTot AS SpesaMensile;
ELSE 										-- se ho una spesa negativa vuoldire che ho guadagnato grazie alla produzione di energia dei pannelli fotovoltaici
	SET SpesaTot=SpesaTot*-1;
	SELECT SpesaTot AS GuadagnoMensile;
END IF;
END $$
DELIMITER ;

-- CALL CalcoloSpesaMens('2021-08-01 04:00');
