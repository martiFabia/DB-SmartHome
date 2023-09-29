SET NAMES latin1;
SET FOREIGN_KEY_CHECKS = 0;
SET SQL_SAFE_UPDATES = 0;
set global event_scheduler = on;


BEGIN;
CREATE DATABASE IF NOT EXISTS SmartHome;
COMMIT;

USE SmartHome;

-- Creazione Tabella Utente

DROP TABLE IF EXISTS `utente` ;
CREATE TABLE `utente` (
CodFiscale varchar (50) NOT NULL,
Nome varchar(50) NOT NULL,
Cognome varchar(50) NOT NULL,
DataNascita date NOT NULL,
Telefono double NOT NULL,
DataIscrizione date NOT NULL,
PRIMARY KEY(CodFiscale)
) Engine=InnoDB DEFAULT CHARSET=latin1;

-- Creazione Tabella Documento

DROP TABLE IF EXISTS documento;
CREATE TABLE documento(
CodFiscale varchar (50) NOT NULL, 
CodiceId varchar(50) NOT NULL,
Tipo varchar (50) NOT NULL,
Ente varchar (50) NOT NULL,
DataScadenza date NOT NULL,
check(Tipo='IDCard' or Tipo='Passport' or Tipo='DLicense' or Tipo='Spid'),
PRIMARY KEY(CodFiscale),
FOREIGN KEY (CodFiscale) REFERENCES utente (CodFiscale) ON DELETE CASCADE
) Engine=InnoDB DEFAULT CHARSET=latin1;

-- Creazione Tabella Account
DROP TABLE IF EXISTS account;
CREATE TABLE account(
Username varchar(25) NOT NULL,
Password varchar(50) NOT NULL,
CodFiscale varchar (50) NOT NULL,
PRIMARY KEY (Username),
FOREIGN KEY (CodFiscale) REFERENCES documento (CodFiscale) ON DELETE CASCADE
)Engine=InnoDB DEFAULT CHARSET=latin1;

-- Creazione Tabella Recupero
DROP TABLE IF EXISTS recupero;
CREATE TABLE recupero(
Username varchar(25) NOT NULL,
Domanda varchar(50) NOT NULL,
Risposta varchar(50) NOT NULL,
PRIMARY KEY (Username,Domanda),
FOREIGN KEY(Username) REFERENCES account(Username) ON DELETE CASCADE
)Engine=InnoDB DEFAULT CHARSET=latin1;

-- Creazione tabella Operazione 

DROP TABLE IF EXISTS operazione;
CREATE TABLE operazione (
Username varchar(25) NOT NULL,
CodOp integer NOT NULL,
CodDisp integer NOT NULL,
Inizio datetime NOT NULL,
Fine datetime DEFAULT null,
Differita varchar (2) DEFAULT 'No',
check(Differita='Si' or Differita='No'),
PRIMARY KEY (Username,CodDisp,CodOp,Inizio),
FOREIGN KEY(Username)REFERENCES account(Username) ON DELETE CASCADE,
FOREIGN KEY(CodOp,CodDisp) REFERENCES settaggio(CodOp,CodDisp) ON DELETE CASCADE
)Engine=InnoDB DEFAULT CHARSET=latin1;

-- Creazione Tabella Settaggio

DROP TABLE IF EXISTS settaggio;
CREATE TABLE settaggio(
CodOp integer NOT NULL ,
CodDisp integer NOT NULL,
PRIMARY KEY(CodOp,CodDisp)
)Engine=InnoDB DEFAULT CHARSET=latin1;

--  CREAZIONE TABELLA Condizionatore
DROP TABLE IF EXISTS condizionatore;
CREATE TABLE condizionatore(
CodOp integer NOT NULL,
CodDisp integer NOT NULL,
Temperatura double NOT NULL,
Umidità double NOT NULL,
ConsCond double DEFAULT 0,         -- in Wh
PRIMARY KEY(CodDisp,CodOp),
FOREIGN KEY(CodOp,CodDisp) REFERENCES settaggio(CodOp,CodDisp) ON DELETE CASCADE
)Engine=InnoDB DEFAULT CHARSET=latin1;

-- Creazione Tabella Ricorsione

DROP TABLE IF EXISTS ricorsione;
CREATE TABLE ricorsione(
CodOp integer NOT NULL,
CodDisp integer NOT NULL,
DataI datetime NOT NULL,
Dataf datetime NOT NULL,
PRIMARY KEY(CodDisp,CodOp),
FOREIGN KEY(CodOp,CodDisp) REFERENCES condizionatore(CodOp,CodDisp) ON DELETE CASCADE
)Engine=InnoDB DEFAULT CHARSET=latin1;

-- CREAZIONE TABELLA LIVELLO

DROP TABLE IF EXISTS livello;
CREATE TABLE livello(
CodOp integer NOT NULL,
CodDisp integer NOT NULL,
Consumo double DEFAULT 0,
PRIMARY KEY(CodDisp,CodOp),
FOREIGN KEY(CodOp,CodDisp) REFERENCES settaggio(CodOp,CodDisp) ON DELETE CASCADE
)Engine=InnoDB DEFAULT CHARSET=latin1;

-- CREAZIONE TABELLA Programma

DROP TABLE IF EXISTS programma;
CREATE TABLE programma(
CodOp integer NOT NULL,
CodDisp integer NOT NULL,
NomeP varchar(50) NOT NULL,
Durata integer NOT NULL,				-- Durata espressa in minuti
ConsMedio double NOT NULL,    -- in Wh
PRIMARY KEY(CodDisp,CodOp),
FOREIGN KEY(CodOp,CodDisp) REFERENCES settaggio(CodOp,CodDisp) ON DELETE CASCADE
)Engine=InnoDB DEFAULT CHARSET=latin1;

-- CREAZIONE TABELLA Luce

DROP TABLE IF EXISTS luce;
CREATE TABLE luce(
CodOp integer NOT NULL,
CodDisp integer NOT NULL,
TColore double NOT NULL,
Intensità double NOT NULL,
ConsLuce double DEFAULT 0,				-- Wh
PRIMARY KEY(CodDisp,CodOp),
FOREIGN KEY(CodOp,CodDisp) REFERENCES settaggio(CodOp,CodDisp) ON DELETE CASCADE
)Engine=InnoDB DEFAULT CHARSET=latin1;

#--------------dispositivi------------------------

DROP TABLE IF EXISTS `dispositivi`;
CREATE TABLE `dispositivi` (
  `CodDisp` integer NOT NULL AUTO_INCREMENT,
  `NomeDisp` varchar(50) NOT NULL,
  `Tipologia` varchar(50) NOT NULL,
  `Posizione` integer NOT NULL,
  `Stato` integer DEFAULT 0,
  CHECK ( Stato=1 or Stato=0),
  CHECK(Tipologia='Variabile' or Tipologia='NONInterrompibile' or Tipologia='Fisso' or Tipologia='Condizionamento' or Tipologia='Illuminazione'),
  PRIMARY KEY (`CodDisp`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

#-------------smartPlug-------------------------

DROP TABLE IF EXISTS `smartPlug`;
CREATE TABLE `smartPlug` (
  `CodSmart` integer NOT NULL AUTO_INCREMENT,
  `CodDisp` integer DEFAULT NULL, 
  `StatoSP` varchar(3) DEFAULT 'OFF',
  CHECK (StatoSP = 'ON' or StatoSP = 'OFF'), 
  PRIMARY KEY (`CodSmart`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

#-------------stanza-------------------------

DROP TABLE IF EXISTS `stanza`;
CREATE TABLE `stanza` (
  `CodSt` integer NOT NULL AUTO_INCREMENT,
  `Nome` varchar(50) NOT NULL,
  `Piano` integer NOT NULL,
  `Altezza` double NOT NULL,
  `Larghezza` double NOT NULL,
  `Lunghezza` double NOT NULL,
  PRIMARY KEY (`CodSt`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

#-------------puntiingresso-------------------------

DROP TABLE IF EXISTS `puntiingresso`;
CREATE TABLE `puntiingresso` (
  `CodIngresso` integer NOT NULL AUTO_INCREMENT,
  `CodSt` integer NOT NULL, 
  `TipoApert` varchar(50) NOT NULL,
   CHECK (TipoApert = 'Finestra' or 
	      TipoApert = 'PortaFinestra' or
          TipoApert = 'Porta'),
	`PCardinale` varchar(2) NOT NULL,
     CHECK (PCardinale = 'N' or
		 PCardinale = 'NO' or
         PCardinale = 'O' or
         PCardinale = 'SO' or
         PCardinale = 'S' or
         PCardinale = 'SE' or
         PCardinale = 'E' or 
         PCardinale = 'NE'), 
  PRIMARY KEY (`CodIngresso`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


#----------------efficienzaEnergetica----------------------

DROP TABLE IF EXISTS `efficienzaEnergetica`;
CREATE TABLE `efficienzaEnergetica` (
  `CodSt` integer NOT NULL,
   `TempoMis` timestamp NOT NULL,
  `TempEsterna` double NOT NULL DEFAULT 0,
  `TempInterna` double NOT NULL DEFAULT 0,
  `ENecessaria` double NOT NULL DEFAULT 0,
  check(ENecessaria>=0),
  PRIMARY KEY (`CodSt`,`TempoMis` ),
  FOREIGN KEY (`CodSt`) REFERENCES stanza(`CodSt`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


#-----------suggerimento---------------------------

DROP TABLE IF EXISTS `suggerimento`;
CREATE TABLE `suggerimento` (
  `DataOra` datetime NOT NULL,
  `CodDisp` integer NOT NULL,
  `Messaggio` varchar(255) NOT NULL,
  `Scelta` varchar(2) not null default 'No',
   check(Scelta='Si' or Scelta='No'),
  `Username` varchar(50) NOT NULL,
  `Inizio` varchar(2) default ' ',
  `CodOp` integer NOT NULL,
  PRIMARY KEY (`DataOra`,`CodDisp`, CodOp, Username)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

#--------------contatoreBidirezionale------------------------ 

DROP TABLE IF EXISTS `contatoreBidirezionale`;
CREATE TABLE `contatoreBidirezionale` (
  `FasciaOraria` varchar(3) NOT NULL,
   check(FasciaOraria='F1' or FasciaOraria='F2' or FasciaOraria='F3' or FasciaOraria='F4'),
  `Data` date NOT NULL,
  `ConteggioEn` double DEFAULT 0,
  `EnRete` double DEFAULT 0,
  PRIMARY KEY (`FasciaOraria`, `Data` )
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


#--------------EnergiaConsumata------------------------

DROP TABLE IF EXISTS `EnergiaConsumata`;
CREATE TABLE `EnergiaConsumata` (
  `QuantitaConsumata` double DEFAULT 0, 		-- in Wh
  `FasciaOraria` varchar(3) NOT NULL,
  `Data` date NOT NULL,
   CHECK (QuantitaConsumata>=0),
  PRIMARY KEY (`FasciaOraria`, `Data` ), 
  FOREIGN KEY (`FasciaOraria`, `Data` ) REFERENCES contatoreBidirezionale(`FasciaOraria`, `Data`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


#------------EnergiaProdotta--------------------------

DROP TABLE IF EXISTS `EnergiaProdotta`;
CREATE TABLE `EnergiaProdotta` (
  `Timestamp` timestamp NOT NULL,
  `Quantita` double NOT NULL,   -- in wh/m^2
   check(Quantita>=0),
  `FasciaOraria` varchar(3) NOT NULL,
  PRIMARY KEY (`Timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


#--------------------utilizzo------------------

DROP TABLE IF EXISTS `utilizzo`;
CREATE TABLE `utilizzo` (
  `FasciaOraria` varchar(3) NOT NULL,
  `Data` date NOT NULL,
  `Preferenza` varchar(50) NOT NULL,
   CHECK (Preferenza = 'Immettere' or
		 Preferenza = 'Autoconsumare'),
  PRIMARY KEY (`FasciaOraria`, `Data`),
  FOREIGN KEY (`FasciaOraria`, `Data` ) REFERENCES contatoreBidirezionale(`FasciaOraria`, `Data`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


#-------------spesa--------------------

DROP TABLE IF EXISTS `spesa`;
CREATE TABLE `spesa` (
  `Data` date NOT NULL,
  `FasciaOraria` varchar(3) NOT NULL,
  `CostoUnitperFascia` double NOT NULL,  -- euro per KW
PRIMARY KEY (`FasciaOraria`, `Data`),
  FOREIGN KEY (`FasciaOraria`, `Data` ) REFERENCES contatoreBidirezionale(`FasciaOraria`, `Data`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
