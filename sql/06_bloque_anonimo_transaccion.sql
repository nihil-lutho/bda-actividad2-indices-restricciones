/* =============================================================================
   Script   : 06_bloque_anonimo_transaccion.sql
   Conexión : hr@xepdb1
   Objetivo : Bloque anónimo PL/SQL que marca el comienzo y la finalización de
              una transacción sobre DEPARTMENTS2.
   Claves   :
   - SET TRANSACTION NAME debe ser la primera sentencia de la transacción, por
     eso se ejecuta un COMMIT previo que cierra cualquier transacción abierta.
   - DBMS_TRANSACTION.LOCAL_TRANSACTION_ID devuelve el identificador de la
     transacción activa (NULL si no hay ninguna). Permite "ver" que la
     transacción empieza con el primer DML y termina con COMMIT o ROLLBACK.
   ============================================================================= */
SET SERVEROUTPUT ON
COMMIT;

-- Bloque 1: transacción que termina en COMMIT
DECLARE
  v_inicio TIMESTAMP := SYSTIMESTAMP;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Transacción activa antes de empezar: ' ||
                       NVL(DBMS_TRANSACTION.LOCAL_TRANSACTION_ID, 'ninguna'));

  SET TRANSACTION NAME 'TX_DEPARTMENTS2';
  DBMS_OUTPUT.PUT_LINE('>> INICIO de la transacción TX_DEPARTMENTS2 - ' ||
                       TO_CHAR(v_inicio, 'HH24:MI:SS.FF3'));

  INSERT INTO departments2 (department_id, department_name, manager_id, location_id)
  VALUES (310, 'Innovacion', NULL, 1700);
  DBMS_OUTPUT.PUT_LINE('   INSERT 310 -> id transacción: ' ||
                       DBMS_TRANSACTION.LOCAL_TRANSACTION_ID);

  UPDATE departments2 SET location_id = 2500 WHERE department_id = 310;
  DBMS_OUTPUT.PUT_LINE('   UPDATE 310 -> filas afectadas: ' || SQL%ROWCOUNT);

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('>> FIN de la transacción (COMMIT) - ' ||
                       TO_CHAR(SYSTIMESTAMP, 'HH24:MI:SS.FF3'));
  DBMS_OUTPUT.PUT_LINE('Transacción activa después del COMMIT: ' ||
                       NVL(DBMS_TRANSACTION.LOCAL_TRANSACTION_ID, 'ninguna'));
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('>> FIN de la transacción (ROLLBACK): ' || SQLERRM);
END;
/

-- Bloque 2: transacción que falla y termina en ROLLBACK (atomicidad).
-- El segundo INSERT viola el NOT NULL de department_name (ORA-01400), así
-- que también se deshace el primer INSERT (320).
BEGIN
  SET TRANSACTION NAME 'TX_DEPARTMENTS2_ERROR';
  DBMS_OUTPUT.PUT_LINE('>> INICIO de la transacción TX_DEPARTMENTS2_ERROR');

  INSERT INTO departments2 (department_id, department_name, location_id)
  VALUES (320, 'Calidad', 1700);
  DBMS_OUTPUT.PUT_LINE('   INSERT 320 correcto (pendiente de confirmar)');

  INSERT INTO departments2 (department_id, department_name, location_id)
  VALUES (330, NULL, 1700);

  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('>> FIN de la transacción (ROLLBACK): ' || SQLERRM);
END;
/

-- Verificación: 310 existe (confirmado); 320 y 330 no existen (deshechos)
SELECT * FROM departments2 WHERE department_id IN (310, 320, 330);
