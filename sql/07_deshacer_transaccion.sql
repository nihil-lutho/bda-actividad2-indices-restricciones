/* =============================================================================
   Script   : 07_deshacer_transaccion.sql
   Conexión : hr@xepdb1
   Objetivo : Ejemplos prácticos de cómo deshacer una transacción en Oracle.
   Ejecutar : sentencia a sentencia (Ctrl+Enter) para observar cada resultado.
   ============================================================================= */
COMMIT;  -- punto de partida limpio

-- 1. ROLLBACK total: deshace todos los cambios no confirmados -----------------
SELECT COUNT(*) AS antes FROM departments2;                     -- p. ej. 31
DELETE FROM departments2 WHERE location_id = 1700;              -- borra muchas filas
SELECT COUNT(*) AS tras_delete FROM departments2;
ROLLBACK;
SELECT COUNT(*) AS tras_rollback FROM departments2;             -- vuelve al valor inicial

-- 2. SAVEPOINT + ROLLBACK TO: deshacer solo una parte -------------------------
UPDATE departments2
SET    department_name = 'Administration (rev)'
WHERE  department_id = 10;
SAVEPOINT sp_tras_update;

DELETE FROM departments2 WHERE department_id = 20;
SELECT department_id, department_name FROM departments2 WHERE department_id IN (10, 20);
-- -> 10 renombrado y 20 ya no aparece

ROLLBACK TO SAVEPOINT sp_tras_update;
SELECT department_id, department_name FROM departments2 WHERE department_id IN (10, 20);
-- -> el DELETE se deshizo (20 vuelve), el UPDATE de 10 sigue pendiente

ROLLBACK;  -- deshace también el UPDATE y cierra la transacción
SELECT department_id, department_name FROM departments2 WHERE department_id = 10;

-- 3. Límite: una sentencia DDL confirma implícitamente lo anterior -----------
INSERT INTO departments2 (department_id, department_name, location_id)
VALUES (340, 'Prueba DDL', 1700);
CREATE TABLE tmp_ddl (x NUMBER);      -- COMMIT implícito
ROLLBACK;                              -- ya no hay nada que deshacer
SELECT * FROM departments2 WHERE department_id = 340;          -- la fila sigue

-- Limpieza
DROP TABLE tmp_ddl PURGE;
DELETE FROM departments2 WHERE department_id = 340;
COMMIT;
