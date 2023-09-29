#--------- Trigger Per Dispositivi Accesi ----------------

DROP TRIGGER IF EXISTS disp_accesi;			-- mantengo aggiornato l'attributo Stato
DELIMITER $$
CREATE TRIGGER disp_accesi
AFTER INSERT ON operazione 
FOR EACH ROW
BEGIN 
CALL agg_stato(new.Username,new.CodDisp,new.CodOp,new.Inizio,new.Fine);
END $$
DELIMITER ;


#-------------- Trigger per Energia Consumata---------------
DROP TRIGGER IF EXISTS pop_Cons;
DELIMITER $$
CREATE TRIGGER pop_Cons
AFTER INSERT ON operazione 
FOR EACH ROW
BEGIN 
CALL CalcoloConsumoOp(new.Username,new.CodOp,new.CodDisp,new.Inizio,new.Fine, @fascia, @Tot);
CALL AggConsumata(new.Inizio,@fascia, @Tot);
END $$
DELIMITER ;