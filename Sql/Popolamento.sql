-- Popolamento
USE SmartHome;

#-----------------Popolamento Utente-------------------
insert into utente (CodFiscale, Nome, Cognome, DataNascita, Telefono, DataIscrizione)
values ('aaa1','Paolo','Rossi','2000-01-5',3334441234,'2020-04-10'),
	   ('bbb2','Marta','Rossi','2001-05-10',3337891234,'2020-04-10'),
       ('ccc3','Francesco','Rossi','1980-06-24',3174541934, '2020-01-10'),
       ('ddd4','Giovanna','Bianchi','1985-12-5',3734041304, '2020-01-11');
 
#------------------Popolamento Documento-----------------
insert into documento (Tipo, CodiceId, Ente, DataScadenza, CodFiscale)
values ('IDcard',4352,'Motorizzazione','2030-01-5','aaa1'),
	   ('IDcard',3311,'Comune','2022-10-5','ccc3'),
	   ('Spid',4098,'Comune','2025-04-9','ddd4');
       
#-----------------Popolamento Account----------------------
insert into account (Username, Password, CodFiscale)
values ('Paolo','BientinaCapitale00','aaa1'),
	   ('Francesco','France1980','ccc3'),
	   ('Giovanna','GioBia85', 'ddd4');
       
#---------------Popolamento Recupero---------------------
insert into recupero (Username, Domanda, Risposta)
values ('Paolo','Animale preferito','gatto'),
	   ('Francesco','colore preferito','arancione'),
	   ('Giovanna','Cognome da nubile della madre', 'Granchi');

-- # --------------Popolamento Dispositivi ------------------
insert into dispositivi(NomeDisp,Tipologia,Posizione, CodDisp) 		
values ('Condizionatore','condizionamento',05,1),				-- 1-7 Condizionatori	
	   ('Condizionatore','condizionamento',06, 2),				
       ('Condizionatore','condizionamento',01,3),
       ('Condizionatore','condizionamento',02,4),
       ('Condizionatore','condizionamento',07,5),
       ('Condizionatore','condizionamento',05,6),
       ('Stufa','condizionamento',06,7),
       ('Lucesoggiorno', 'illuminazione', 06,8),			-- 8-12 Luci
       ('Lucesoggiorno','illuminazione', 06,9),
       ('Lucebagno','illuminazione', 04,10),
       ('Lucebagno','illuminazione', 04,11),
       ('Lucecucina','illuminazione', 05,12),
       ('Lavastoviglie','NONinterrompibile', 05,32),			-- 32-34 ciclo NON interr
       ('Lavatrice','NONinterrompibile',03,33),
       ('Asciugatrice','NONinterrompibile',03,34),
       ('Televisore','fisso',06,35),						-- 35 in poi Fisso
       ('Televisore','fisso', 05,36),
	   ('Televisore','fisso', 01,37),
	   ('Televisore','fisso', 02,38),
       ('MacchinaCaffe','fisso',05,39),
       ('Aspirapolvere','fisso',06,40),
       ('Microonde','variabile',05,51);

DROP PROCEDURE IF EXISTS agg_stato;
DELIMITER $$
CREATE PROCEDURE agg_stato(Username varchar(50),CodDisp integer,CodOp integer, Inizio datetime, Fine datetime)
BEGIN
IF (Date(Fine)<=current_date AND hour(fine)<current_time)  THEN
	UPDATE dispositivi D
    SET Stato=0
    WHERE D.CodDisp=CodDisp;
END IF;
IF (Date(Inizio)<= current_date AND hour(Inizio)<current_time AND Date(Fine)>current_date AND hour(Fine)>current_time) THEN
	UPDATE dispositivi D
    SET Stato=1
    WHERE D.CodDisp=CodDisp; 
END IF;
END $$
DELIMITER ;

       
	
#---------------Popolamento Settaggio---------------------       
insert into settaggio (CodOp,CodDisp)
 values (1,1),(2,1),(3,1),(4,1),(5,1),(6,1),
         (1,2),(2,2),(3,2),(4,2),(5,2),(6,2),
        (1,3),(2,3),(3,3),(4,3),(5,3),(6,3),
        (1,4),(2,4),(3,4),(4,4),(5,4),(6,4),
        (1,5),(2,5),(3,5),(4,5),(5,5),(6,5),
		(1,6),(2,6),(3,6),(4,6),(5,6),(6,6),
        (1,7),(2,7),(3,7),(4,7),(5,7),(6,7),
        (1,8),(2,8),(3,8),(4,8),
		(1,9),(2,9),(3,9),(4,9),
		(1,10),(2,10),(3,10),(4,10),
		(1,11),(2,11),(3,11),(4,11),
		(1,12),(2,12),(3,12),(4,12),
        (1,33),(2,33),(3,33),(4,33),(5,33),
		(1,34),(2,34),(3,34),(4,34),(5,34),
		(1,35),(2,35),(3,35),(4,35),(5,35),
        (1, 36),(2,36),(3,36),(4,36),(5,36),  
		(1, 37),(2,37),(3,37),(4,37),(5,37),
        (1, 38),(2,38),(3,38),(4,38),(5,38),
        (1, 39),(2,39),(3,39),(4,39),(5,39),
        (1, 40),(2,40),(3,40),(4,40),(5,40),
        (1,51), (1,52),(1,53),(1,54),(1,55),(1,56),(1,57),(1,58),(1,59),(1,60);

#------------------------Popolamento Codizionatore -----------------------------
insert into condizionatore(CodOp,CodDisp,Temperatura,Umidità,ConsCond)    -- consCond in Wh
values (1,1,18,65,1000),(2,1,20,55,1100),(3,1,22,45,1200),(4,1,24,35,1200), (5,1,25,30,1150),(6,1,28,20,1500),
       (1,2,18,65,1000),(2,2,20,55,1000),(3,2,22,45,1300),(4,2,24,35,1000), (5,2,25,30,1300),(6,2,28,20,1500),
        (1,3,18,65,1100),(2,3,20,55,1000),(3,3,22,45,1300),(4,3,24,35,1000),(5,3,25,30,1400),(6,3,28,20,1200),
        (1,4,18,65,1100),(2,4,20,55,1200),(3,4,22,45,1200),(4,4,24,35,1100),(5,4,25,30,1200),(6,4,28,20,1300),
        (1,5,18,65,1150),(2,5,20,55,1100),(3,5,22,45,1500),(4,5,24,35,1200),(5,5,25,30,1300),(6,5,28,20,1400),
		(1,6,18,65,1000),(2,6,20,55,1200),(3,6,22,45,1400),(4,6,24,35,1100),(5,6,25,30,1200),(6,6,28,20,1400),
        (1,7,18,65,1150),(2,7,20,55,1300),(3,7,22,45,1350),(4,7,24,35,1150),(5,7,25,30,1200),(6,7,28,20,1100);
        

#-------------------Popolamento Luce-----------------------------------------------

insert into luce (CodOp,CodDisp,TColore,Intensità,ConsLuce)  -- consLuce in WH
values(1,8,2700,65,15),(2,8,2300,80,22),(3,8,2222,43,12),(4,8,1000,30,17),
(1,9,2700,65,11),(2,9,2300,80,23),(3,9,2222,43,28),(4,9,'1000',30,20),
(1,10,2700,65,21),(2,10,2300,80,10),(3,10,2222,43,15),(4,10,1000,30,25),
(1,11,2700,65,18),(2,11,2300,80,22),(3,11,2222,43,20),(4,11,1000,30,11),
(1,12,2700,65,33),(2,12,2300,80,21),(3,12,2222,43,19),(4,12,1000,30,11);

#--------------------Popolamento Programma-----------------------------
insert into programma(CodOp,CodDisp,NomeP,ConsMedio,Durata) -- ConsMedio in Wh 
values (1,33,'Ammollo','1','10'),(2,33,'Intensivo','1700','95'),(3,33,'Normale_Prelavaggio','1500','60'),(4,33,'Leggero_Prelavaggio','850','45'),(5,33,'Economico_Prelavaggio','1250','100'),
(1,34,'Cotone_20','280','150'),(2,34,'Cotone_40','800','150'),(3,34,'Cotone_60','1130','150'),(4,34,'Cotone_90','2020','165'),(5,34,'Sintetici_40','640','105'),
(1,35,'Rapido/misto','460','75'),(2,35,'Delicati/Seta','240','45'),(3,35,'Lana','220','45'),(4,35,'Super15','100','15'),(5,35,'Cotone','235','100');

#--------------------Popolamento Livello--------------------------
insert into livello(CodOp,CodDisp,Consumo) -- Consumo in Wh
values (1, 36,'150'),(2,36,'600'),(3,36,'1200'),(4,36,'600'),(5,36,'700'),  
		(1, 37,'150'),(2,37,'600'),(3,37,'1200'),(4,37,'600'),(5,37,'700'),
        (1, 38,'150'),(2,38,'600'),(3,38,'1200'),(4,38,'600'),(5,38,'700'),
        (1, 39,'150'),(2,39,'600'),(3,39,'1200'),(4,39,'600'),(5,39,'700'),
        (1, 40,'150'),(2,40,'600'),(3,40,'1200'),(4,40,'600'),(5,40,'700'),
        (1,51, 1000), (1,52,70),(1,53,400),(1,54,400),(1,55,900),(1,56,60),(1,57,950),(1,58,300),(1,59,1500),(1,60,1600);

#----------------------Popolamento Stanza-----------------------------
insert into stanza (Nome, Lunghezza, Larghezza, Altezza, Piano, CodSt)
 values ('Camera',125.6,200.9,225,1,01),
        ('Camera',177,198.66,195.5,2,02),
        ('Bagno',195.6,250.9,225,1,03),
        ('Bagno',175.6,200.9,225,2,04),
        ('Cucina',125.6,200.9,225,0,05),
        ('Sala',125.6,266.9,275,0,06),
        ('Camera',300.6,204.9,225,1,07);
        
#-------------------Popolamento Puntiingresso-----------------------
insert into puntiingresso (CodIngresso, CodSt, TipoApert, PCardinale)
 values (01, 01, 'porta', 'N'),
		(02, 01, 'finestra', 'E'),
        (03, 02, 'porta', 'N'), 
        (04, 02, 'finestra', 'O'),
        (05, 03, 'porta', 'NO'),
        (06, 03, 'finestra', 'E'),
        (07, 04, 'porta', 'NO'),
        (08, 04, 'finestra', 'E'),
        (09, 05, 'portafinestra', 'SE'),
        (10, 05, 'porta', 'NO'),
        (11, 06, 'portafinestra', 'S'),
        (12, 07, 'porta', 'O'),
        (13, 07, 'finestra', 'SO');
        
-- #------------- Popolamento SmartPlug-----------------
insert into smartplug(StatoSP, CodDisp)  
values ('ON',1),							 
       ('ON',2),
       ('OFF',3),
       ('OFF',4),
       ('OFF',5),
       ('ON',6),
       ('ON',7),
	   ('ON',8),
       ('ON',9),
       ('ON',10),
       ('ON',11),
       ('ON',12),
       ('ON',13),
       ('OFF',14),
       ('OFF',15),
       ('OFF',16),
       ('ON',17),
       ('ON',18),
       ('OFF',19),
       ('OFF',20),
       ('OFF',21),
       ('ON',22);


#---------------- Popolamento Ricorsione ------------------

insert into ricorsione
values (1,55,'2021-08-29 8:00','2021-09-20 9:00');
     
-- #----------------- Popolamento Energia Consumata--------------------
insert into energiaconsumata(FasciaOraria,Data)
values('F1','2021-08-01'),('F2','2021-08-01'),('F3', '2021-08-01'),('F4','2021-08-01'),
('F1','2021-08-02'),('F2','2021-08-02'),('F3', '2021-08-02'),('F4','2021-08-02'),
('F1','2021-08-03'),('F2','2021-08-03'),('F3', '2021-08-03'),('F4','2021-08-03'),
('F1','2021-08-04'),('F2','2021-08-04'),('F3', '2021-08-04'),('F4','2021-08-04'),
('F1','2021-08-05'),('F2','2021-08-05'),('F3', '2021-08-05'),('F4','2021-08-05'),
('F1','2021-08-06'),('F2','2021-08-06'),('F3', '2021-08-06'),('F4','2021-08-06'),
('F1','2021-08-07'),('F2','2021-08-07'),('F3', '2021-08-07'),('F4','2021-08-07'),
('F1','2021-08-08'),('F2','2021-08-08'),('F3', '2021-08-08'),('F4','2021-08-08'),
('F1','2021-08-09'),('F2','2021-08-09'),('F3', '2021-08-09'),('F4','2021-08-09'),
('F1','2021-08-10'),('F2','2021-08-10'),('F3', '2021-08-10'),('F4','2021-08-10'),
('F1','2021-08-11'),('F2','2021-08-11'),('F3', '2021-08-11'),('F4','2021-08-11'),
('F1','2021-08-12'),('F2','2021-08-12'),('F3', '2021-08-12'),('F4','2021-08-12'),
('F1','2021-08-13'),('F2','2021-08-13'),('F3', '2021-08-13'),('F4','2021-08-13'),
('F1','2021-08-14'),('F2','2021-08-14'),('F3', '2021-08-14'),('F4','2021-08-14'),
('F1','2021-08-15'),('F2','2021-08-15'),('F3', '2021-08-15'),('F4','2021-08-15'),
('F1','2021-08-16'),('F2','2021-08-16'),('F3', '2021-08-16'),('F4','2021-08-16'),
('F1','2021-08-17'),('F2','2021-08-17'),('F3', '2021-08-17'),('F4','2021-08-17'),
('F1','2021-08-18'),('F2','2021-08-18'),('F3', '2021-08-18'),('F4','2021-08-18'),
('F1','2021-08-19'),('F2','2021-08-19'),('F3', '2021-08-19'),('F4','2021-08-19'),
('F1','2021-08-20'),('F2','2021-08-20'),('F3', '2021-08-20'),('F4','2021-08-20'),
('F1','2021-08-21'),('F2','2021-08-21'),('F3', '2021-08-21'),('F4','2021-08-21'),
('F1','2021-08-22'),('F2','2021-08-22'),('F3', '2021-08-22'),('F4','2021-08-22'),
('F1','2021-08-23'),('F2','2021-08-23'),('F3', '2021-08-23'),('F4','2021-08-23'),
('F1','2021-08-24'),('F2','2021-08-24'),('F3', '2021-08-24'),('F4','2021-08-24'),
('F1','2021-08-25'),('F2','2021-08-25'),('F3', '2021-08-25'),('F4','2021-08-25'),
('F1','2021-08-26'),('F2','2021-08-26'),('F3', '2021-08-26'),('F4','2021-08-26'),
('F1','2021-08-27'),('F2','2021-08-27'),('F3', '2021-08-27'),('F4','2021-08-27'),
('F1','2021-08-28'),('F2','2021-08-28'),('F3', '2021-08-28'),('F4','2021-08-28'),
('F1','2021-08-29'),('F2','2021-08-29'),('F3', '2021-08-29'),('F4','2021-08-29'),
('F1','2021-08-30'),('F2','2021-08-30'),('F3', '2021-08-30'),('F4','2021-08-30'),
('F1','2021-08-31'),('F2','2021-08-31'),('F3', '2021-08-31'),('F4','2021-08-31');




#-----------------------Popolamento Operazione-----------------------
insert into operazione (CodDisp,Inizio,Fine,Username,CodOp)
values (1,'2021-08-05 18:19','2021-08-05 18:27','Paolo',5), (8,'2021-08-04 10:10','2021-08-04 12:24','Paolo',3),
	   (3,'2021-08-05 21:19','2021-08-05 23:27','Paolo',2), (6,'2021-08-03 15:19','2021-08-03 16:27','Paolo',8),  
       (9,'2021-08-07 13:19','2021-08-07 14:24','Paolo',1), (7,'2021-08-03 17:51','2021-08-03 18:27','Paolo',1),  
       (10,'2021-08-10 17:17','2021-08-10 20:27','Paolo',3), (1,'2021-08-05 21:19','2021-08-05 23:57','Paolo',4),
       (35,'2021-08-06 9:19','2021-08-06 12:27','Francesco',2), (2,'2021-08-08 11:19','2021-08-08 14:21','Francesco',6),
	   (6,'2021-08-06 10:19','2021-08-06 12:20','Francesco',5), (2,'2021-08-09 11:19','2021-08-09 14:21','Francesco',3),
       (5,'2021-08-07 22:12','2021-08-07 23:26','Francesco',4), (10,'2021-08-09 11:19','2021-08-09 14:21','Francesco',5),
       (3,'2021-08-08 16:45','2021-08-08 18:33','Francesco',5), (11,'2021-08-09 11:19','2021-08-09 14:21','Francesco',7),
       (60,'2021-08-08 9:19','2021-08-08 12:27','Francesco',1), (5,'2021-08-09 11:19','2021-08-09 14:21','Francesco',4),
	   (9,'2021-08-09 13:12','2021-08-09 14:24','Paolo',5),  (7,'2021-08-13 17:51','2021-08-13 18:27','Paolo',1),  
       (10,'2021-08-12 16:17','2021-08-12 20:27','Paolo',3),  (1,'2021-08-15 21:19','2021-08-15 23:57','Paolo',2),
       (35,'2021-08-12 9:19','2021-08-12 11:27','Giovanna',2), (2,'2021-08-15 11:03','2021-08-15 15:21','Giovanna',4),
	   (6,'2021-08-12 10:19','2021-08-12 13:20','Giovanna',5), (2,'2021-08-15 11:05','2021-08-15 16:21','Giovanna',3),
       (5,'2021-08-13 22:12','2021-08-13 22:26','Giovanna',4), (10,'2021-08-15 11:10','2021-08-15 14:21','Giovanna',5),
       (3,'2021-08-14 16:45','2021-08-14 17:33','Giovanna',4),  (11,'2021-08-16 11:19','2021-08-16 14:21','Giovanna',7),
       (2,'2021-08-14 9:19','2021-08-14 12:27','Giovanna',4), (5,'2021-08-16 11:19','2021-08-16 14:21','Giovanna',4),
       (10,'2021-08-15 18:19','2021-08-15 18:27','Paolo',3),(8,'2021-08-15 10:10','2021-08-15 12:24','Paolo',3),
	   (9,'2021-08-15 21:19','2021-08-15 23:27','Paolo',3),  (6,'2021-08-15 15:19','2021-08-15 16:27','Paolo',7),  
       (9,'2021-08-16 13:19','2021-08-16 14:24','Paolo',3),  (7,'2021-08-16 17:51','2021-08-16 18:27','Paolo',3), 
       (10,'2021-08-16 17:17','2021-08-16 20:27','Paolo',3),  (16,'2021-08-16 21:19','2021-08-16 23:57','Paolo',2),
       (5,'2021-08-16 9:19','2021-08-16 12:27','Francesco',4),(15,'2021-08-16 11:19','2021-08-16 14:21','Francesco',1),
	   (6,'2021-08-17 10:19','2021-08-17 12:20','Francesco',5),(16,'2021-08-17 11:19','2021-08-17 14:21','Francesco',1),
       (5,'2021-08-17 22:12','2021-08-17 23:26','Francesco',4),(10,'2021-08-17 11:19','2021-08-17 14:21','Francesco',2),
       (7,'2021-08-17 16:45','2021-08-17 18:33','Francesco',2),(11,'2021-08-17 11:19','2021-08-17 14:21','Francesco',7),
       (15,'2021-08-18 9:19','2021-08-18 12:27','Francesco',2),(5,'2021-08-18 11:19','2021-08-18 14:21','Francesco',4),
	   (9,'2021-08-18 13:12','2021-08-18 14:24','Paolo',3),  (7,'2021-08-18 17:51','2021-08-18 18:27','Paolo',10),  
       (10,'2021-08-19 16:17','2021-08-19 20:27','Paolo',3),  (16,'2021-08-19 21:19','2021-08-19 23:57','Paolo',2),
       (15,'2021-08-19 9:19','2021-08-19 11:27','Giovanna',4), (15,'2021-08-19 11:03','2021-08-19 15:21','Giovanna',1),
	   (6,'2021-08-20 10:19','2021-08-20 13:20','Giovanna',7), (16,'2021-08-20 11:05','2021-08-20 16:21','Giovanna',2),
       (5,'2021-08-20 22:12','2021-08-20 22:26','Giovanna',4), (10,'2021-08-20 11:10','2021-08-20 14:21','Giovanna',2),
       (15,'2021-08-20 16:45','2021-08-20 17:33','Giovanna',2), (11,'2021-08-20 11:19','2021-08-20 14:21','Giovanna',7),
       (16,'2021-08-21 9:19','2021-08-21 12:27','Giovanna',1), (5,'2021-08-21 11:19','2021-08-21 14:21','Giovanna',3),
       (10,'2021-08-22 18:19','2021-08-22 18:27','Paolo',3),(8,'2021-08-22 10:10','2021-08-22 12:24','Paolo',3),
	   (9,'2021-08-22 21:19','2021-08-22 23:27','Paolo',1),  (6,'2021-08-22 15:19','2021-08-22 16:27','Paolo',7),  
       (9,'2021-08-23 13:19','2021-08-23 14:24','Paolo',1),  (7,'2021-08-23 17:51','2021-08-23 18:27','Paolo',1),  
       (10,'2021-08-23 17:17','2021-08-23 20:27','Paolo',3),  (16,'2021-08-23 21:19','2021-08-23 23:57','Paolo',2),
       (5,'2021-08-24 9:19','2021-08-24 12:27','Francesco',4),(15,'2021-08-24 11:19','2021-08-24 14:21','Francesco',1),
	   (6,'2021-08-25 10:19','2021-08-25 12:20','Francesco',5),(16,'2021-08-25 11:19','2021-08-25 14:21','Francesco',3),
       (5,'2021-08-25 22:12','2021-08-25 23:26','Francesco',4),(10,'2021-08-25 11:19','2021-08-25 14:21','Francesco',2),
       (10,'2021-08-26 18:19','2021-08-26 18:27','Paolo',3),(8,'2021-08-26 10:10','2021-08-26 12:24','Paolo',1),
	   (9,'2021-08-26 21:19','2021-08-26 23:27','Paolo',1),  (6,'2021-08-26 15:19','2021-08-26 16:27','Paolo',7),  
       (9,'2021-08-27 13:19','2021-08-27 14:24','Paolo',1),  (7,'2021-08-27 17:51','2021-08-27 18:27','Paolo',1),  
       (10,'2021-08-27 17:17','2021-08-27 20:27','Paolo',3),  (16,'2021-08-27 21:19','2021-08-27 23:57','Paolo',3),
       (5,'2021-08-28 9:19','2021-08-28 12:27','Francesco',4),(15,'2021-08-28 11:19','2021-08-28 14:21','Francesco',2),
	   (6,'2021-08-28 10:19','2021-08-28 12:20','Francesco',5),(16,'2021-08-28 11:19','2021-08-28 14:21','Francesco',1);

insert into operazione(CodDisp,Inizio,Fine,Username,CodOp,Differita)
values (55,'2021-08-29 8:00','2021-08-29 9:00','Paolo',1,'Si');


-- #------------------Popolamento Utilizzo ------------------
insert into utilizzo(FasciaOraria,Data,Preferenza)
values ('F1','2021-08-01','Autoconsumare'),('F2','2021-08-01','Immettere'),('F3', '2021-08-01','Autoconsumare'),('F4','2021-08-01','Immettere'),
('F1','2021-08-02','Immettere'),('F2','2021-08-02','Autoconsumare'),('F3', '2021-08-02','Immettere'),('F4','2021-08-02','Autoconsumare'),
('F1','2021-08-03','Autoconsumare'),('F2','2021-08-03','Autoconsumare'),('F3', '2021-08-03','Autoconsumare'),('F4','2021-08-03','Immettere'),
('F1','2021-08-04','Immettere'),('F2','2021-08-04','Autoconsumare'),('F3', '2021-08-04','Immettere'),('F4','2021-08-04','Immettere'),
('F1','2021-08-05','Immettere'),('F2','2021-08-05','Immettere'),('F3', '2021-08-05','Immettere'),('F4','2021-08-05','Immettere'),
('F1','2021-08-06','Immettere'),('F2','2021-08-06','Immettere'),('F3', '2021-08-06','Autoconsumare'),('F4','2021-08-06','Immettere'),
('F1','2021-08-07','Autoconsumare'),('F2','2021-08-07','Immettere'),('F3', '2021-08-07','Immettere'),('F4','2021-08-07','Immettere'),
('F1','2021-08-08','Immettere'),('F2','2021-08-08','Immettere'),('F3', '2021-08-08','Immettere'),('F4','2021-08-08','Immettere'),
('F1','2021-08-09','Immettere'),('F2','2021-08-09','Autoconsumare'),('F3', '2021-08-09','Immettere'),('F4','2021-08-09','Autoconsumare'),
('F1','2021-08-10','Immettere'),('F2','2021-08-10','Immettere'),('F3', '2021-08-10','Immettere'),('F4','2021-08-10','Immettere'),
('F1','2021-08-11','Autoconsumare'),('F2','2021-08-11','Immettere'),('F3', '2021-08-11','Autoconsumare'),('F4','2021-08-11','Immettere'),
('F1','2021-08-12','Immettere'),('F2','2021-08-12','Immettere'),('F3', '2021-08-12','Autoconsumare'),('F4','2021-08-12','Immettere'),
('F1','2021-08-13','Autoconsumare'),('F2','2021-08-13','Immettere'),('F3', '2021-08-13','Autoconsumare'),('F4','2021-08-13','Immettere'),
('F1','2021-08-14','Autoconsumare'),('F2','2021-08-14','Autoconsumare'),('F3', '2021-08-14','Immettere'),('F4','2021-08-14','Autoconsumare'),
('F1','2021-08-15','Immettere'),('F2','2021-08-15','Immettere'),('F3', '2021-08-15','Immettere'),('F4','2021-08-15','Immettere'),
('F1','2021-08-16','Autoconsumare'),('F2','2021-08-16','Immettere'),('F3', '2021-08-16','Immettere'),('F4','2021-08-16','Immettere'),
('F1','2021-08-17','Immettere'),('F2','2021-08-17','Immettere'),('F3', '2021-08-17','Autoconsumare'),('F4','2021-08-17','Immettere'),
('F1','2021-08-18','Autoconsumare'),('F2','2021-08-18','Immettere'),('F3', '2021-08-18','Autoconsumare'),('F4','2021-08-18','Immettere'),
('F1','2021-08-19','Immettere'),('F2','2021-08-19','Autoconsumare'),('F3', '2021-08-19','Immettere'),('F4','2021-08-19','Autoconsumare'),
('F1','2021-08-20','Immettere'),('F2','2021-08-20','Immettere'),('F3', '2021-08-20','Autoconsumare'),('F4','2021-08-20','Immettere'),
('F1','2021-08-21','Autoconsumare'),('F2','2021-08-21','Autoconsumare'),('F3', '2021-08-21','Immettere'),('F4','2021-08-21','Immettere'),
('F1','2021-08-22','Autoconsumare'),('F2','2021-08-22','Immettere'),('F3', '2021-08-22','Immettere'),('F4','2021-08-22','Autoconsumare'),
('F1','2021-08-23','Immettere'),('F2','2021-08-23','Immettere'),('F3', '2021-08-23','Immettere'),('F4','2021-08-23','Immettere'),
('F1','2021-08-24','Autoconsumare'),('F2','2021-08-24','Autoconsumare'),('F3', '2021-08-24','Immettere'),('F4','2021-08-24','Autoconsumare'),
('F1','2021-08-25','Autoconsumare'),('F2','2021-08-25','Immettere'),('F3', '2021-08-25','Autoconsumare'),('F4','2021-08-25','Immettere'),
('F1','2021-08-26','Autoconsumare'),('F2','2021-08-26','Autoconsumare'),('F3', '2021-08-26','Immettere'),('F4','2021-08-26','Immettere'),
('F1','2021-08-27','Autoconsumare'),('F2','2021-08-27','Immettere'),('F3', '2021-08-27','Autoconsumare'),('F4','2021-08-27','Immettere'),
('F1','2021-08-28','Autoconsumare'),('F2','2021-08-28','Immettere'),('F3', '2021-08-28','Immettere'),('F4','2021-08-28','Immettere'),
('F1','2021-08-29','Autoconsumare'),('F2','2021-08-29','Autoconsumare'),('F3', '2021-08-29','Immettere'),('F4','2021-08-29','Immettere'),
('F1','2021-08-30','Immettere'),('F2','2021-08-30','Autoconsumare'),('F3', '2021-08-30','Autoconsumare'),('F4','2021-08-30','Immettere'),
('F1','2021-08-31','Autoconsumare'),('F2','2021-08-31','Autoconsumare'),('F3', '2021-08-31','Autoconsumare'),('F4','2021-08-31','Immettere');


#------------Popolamento Energia Prodotta -------------------------------------------------
DROP PROCEDURE IF EXISTS pop_enProd;
DELIMITER $$
CREATE PROCEDURE pop_enProd(temp1 timestamp,temp2 timestamp)
begin

	DECLARE tot DOUBLE DEFAULT 0;
    DECLARE fascia varchar(2) default ' ';
    
    WHILE temp1<= temp2 DO
    
    IF (HOUR(temp1)>=0 AND HOUR(temp1)<=5) THEN 
    SET tot=0; end if;
    IF (HOUR(temp1)>=21 AND HOUR(temp1)<=23 )THEN
    SET tot=0; END IF;
    
    IF (HOUR(temp1)>=6 AND HOUR(temp1)<8) THEN
    SET tot=459.4; END IF;
    
    IF (HOUR(temp1)>=8 AND HOUR(temp1)<10) THEN
    SET tot=903.7; END IF;
    
    IF (HOUR(temp1)>=10 AND HOUR(temp1)<12) THEN
    SET tot=1323.4; end if;
    
    IF (HOUR(temp1)>=12 AND HOUR (temp1)<=15)THEN
    SET tot=1476.2; END IF;
    
    IF (HOUR(temp1)>=16 AND HOUR (temp1)<18) THEN
    SET tot=963.3; END IF;
    
    IF(HOUR(temp1)>=18 AND HOUR(temp1)<21)THEN
    SET tot=400.3; END IF;
    
IF (HOUR(temp1)>=0 AND HOUR(temp1)<=6) THEN SET fascia='F1'; END IF;
IF (HOUR(temp1)>=7 AND HOUR(temp1)<=12) THEN SET fascia='F2'; END IF;
IF (HOUR(temp1)>12 AND HOUR(temp1)<=18) THEN SET fascia='F3'; END IF;
IF(HOUR(temp1)>18 AND HOUR(temp1)<24) THEN SET fascia='F4'; END IF;
    
    INSERT INTO energiaprodotta(Timestamp,Quantita,FasciaOraria)
    VALUES (temp1,tot,fascia);
    SET temp1=timestampadd(minute,15,temp1);
    END WHILE;
    END $$
    delimiter ;
     CALL pop_enProd('2021-08-01 04:00:00' ,'2021-08-12 21:00:00');		-- Popolo solo 12 giorni altrimenti perdo la connesione al server
     DROP PROCEDURE pop_enProd;
     
     
     #----------------- Popolamento Spesa ----------------
DROP PROCEDURE IF EXISTS pop_Spesa;
DELIMITER $$
CREATE PROCEDURE pop_Spesa(temp1 timestamp,temp2 timestamp)

BEGIN
DECLARE Costo DOUBLE DEFAULT 0;
    DECLARE fascia varchar(2) default ' ';
    WHILE temp1<=temp2 DO
    
IF (HOUR(temp1)>=0 AND HOUR(temp1)<=6) THEN SET fascia='F1'; SET Costo=30; END IF;
IF (HOUR(temp1)>=7 AND HOUR(temp1)<=12) THEN SET fascia='F2';SET Costo=100; END IF;
IF (HOUR(temp1)>12 AND HOUR(temp1)<=18) THEN SET fascia='F3'; SET Costo=110;END IF;
IF(HOUR(temp1)>18 AND HOUR(temp1)<=24) THEN SET fascia='F4';SET Costo=50; END IF;
	
	
insert into spesa(FasciaOraria,Data,CostoUnitperFascia)
values (fascia,Date(temp1),Costo);

SET temp1=timestampadd(HOUR,6,temp1);
END WHILE;
END $$
DELIMITER ;
CALL pop_Spesa('2021-08-01 04:00:00' , '2021-08-12 21:00:00');
DROP PROCEDURE pop_Spesa;


#------------- Popolamento Efficenza Energetica --------------------
DROP PROCEDURE IF EXISTS pop_Efft;
DELIMITER $$
CREATE PROCEDURE pop_Efft(temp1 timestamp)

BEGIN
-- variabili per il calcolo
DECLARE cod  int DEFAULT 1;
DECLARE _lung double DEFAULT 1; -- lunghezza
DECLARE _larg double DEFAULT 1; -- larghezza
DECLARE _alt double DEFAULT 1; -- altezza
DECLARE _p double DEFAULT 1.29; -- densità
DECLARE _Cp integer DEFAULT 1; -- calore specifico
DECLARE Eff double DEFAULT 0; -- Energia necessaria

WHILE cod<=7 DO
-- calcolo effettivo
SELECT Altezza,Larghezza,Lunghezza INTO _alt,_larg,_lung -- ricavo i dati volumetrici della stanza
FROM stanza S  
WHERE CodSt=cod;

SET Eff=_alt*_larg*_lung*_p*_Cp; -- è unitaria (1 grado)

-- aggiornamento Efficienza energetica
insert into efficienzaenergetica(CodSt,TempoMis,ENecessaria)
values (cod,temp1,Eff); 
SET cod=cod+1;
END WHILE;
END $$
delimiter ;
DROP PROCEDURE IF EXISTS popoEff;
DELIMITER $$

CREATE PROCEDURE popoEff(temp1 timestamp, temp2 timestamp)
BEGIN
WHILE temp1<=temp2 DO
CALL pop_Efft(temp1);
SET temp1=timestampadd(HOUR,1,temp1);
END WHILE;
END $$

CALL popoEff('2021-08-01 04:00:00' , '2021-08-12 21:00:00');
DROP PROCEDURE pop_Efft;
DROP PROCEDURE popoEff;

    
    #---------- Popolamento ContBidirezionale ---------------
   
   DROP PROCEDURE IF EXISTS pop_Cont;
    DELIMITER $$
    CREATE PROCEDURE pop_Cont(temp1 timestamp,temp2 timestamp)
	begin

	DECLARE En_Disp,En_Cons,En_Rete,Conteggio DOUBLE DEFAULT 0;
    DECLARE fascia varchar(2) default ' ';
    
    WHILE temp1<=temp2 DO 
    
IF (HOUR(temp1)>=0 AND HOUR(temp1)<=6) THEN SET fascia='F1'; END IF;
IF (HOUR(temp1)>=7 AND HOUR(temp1)<=12) THEN SET fascia='F2'; END IF;
IF (HOUR(temp1)>12 AND HOUR(temp1)<=18) THEN SET fascia='F3'; END IF;
IF(HOUR(temp1)>18 AND HOUR(temp1)<=24) THEN SET fascia='F4'; END IF;
    

    SET EN_Disp=( SELECT SUM( EP.Quantita) 
				FROM energiaprodotta EP INNER JOIN utilizzo U ON 
                (Date(EP.Timestamp)=U.Data
                AND U.FasciaOraria=EP.FasciaOraria)
                WHERE (Date(EP.Timestamp)=Date(temp1)
                AND EP.FasciaOraria=fascia
                AND U.Preferenza='Autoconsumare')
                );
	
      SET EN_Cons=(SELECT  QuantitaConsumata
						FROM energiaconsumata EC
                        WHERE EC.Data=Date(temp1)
                AND fascia=EC.FasciaOraria);
	IF EN_Cons IS NULL THEN
    SET EN_Cons=0;END IF;
    IF EN_Disp IS NULL THEN
    SET EN_Disp =0;END IF;
    
    
    SET Conteggio=En_Disp-En_Cons;
    
		SET EN_Rete=(SELECT SUM( EP.Quantita) 
				FROM energiaprodotta EP INNER JOIN utilizzo U ON 
                (Date(EP.Timestamp)=U.Data
                AND U.FasciaOraria=EP.FasciaOraria)
                WHERE Date(EP.Timestamp)=Date(temp1)
                AND fascia=EP.FasciaOraria
                AND U.Preferenza='Immettere'
                );
                
	IF EN_Rete IS NULL THEN
    SET EN_Rete=0;END IF;
                
CALL ins_contBid (fascia,Date(temp1),Conteggio,En_Rete);
SET temp1=timestampadd(HOUR,6,temp1);

    END WHILE;
    END $$
    DELIMITER ;
CALL pop_Cont('2021-08-01 04:00:00' , '2021-08-12 21:00:00');
DROP procedure pop_Cont;


