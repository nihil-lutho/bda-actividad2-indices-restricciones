/* =============================================================================
   Script   : 05_departments2_sesion.sql
   Conexión : hr@xepdb1
   Objetivo : Duplicar DEPARTMENTS, insertar tres tuplas, cerrar sesión y
              consultar de nuevo, observando el efecto de COMMIT / ROLLBACK.
   ============================================================================= */

/* ---------------------------- PARTE A (sesión 1) --------------------------- */

-- A1. Duplicado mediante CREATE TABLE ... AS SELECT (CTAS).
--     Es DDL: Oracle hace COMMIT implícito antes y después de ejecutarla.
CREATE TABLE departments2 AS
SELECT * FROM departments;

-- A2. Qué se copió: los datos y SOLO las restricciones NOT NULL.
--     No se copian PK, FK, UNIQUE ni índices.
SELECT COUNT(*) AS filas_copiadas FROM departments2;

SELECT constraint_name, constraint_type, search_condition_vc AS condicion
FROM   user_constraints
WHERE  table_name = 'DEPARTMENTS2';

SELECT index_name FROM user_indexes WHERE table_name = 'DEPARTMENTS2';  -- sin filas

-- A3. Tres tuplas nuevas, SIN COMMIT
INSERT INTO departments2 (department_id, department_name, manager_id, location_id)
VALUES (280, 'Analitica de Datos', 200, 1700);
INSERT INTO departments2 (department_id, department_name, manager_id, location_id)
VALUES (290, 'Ciberseguridad', 103, 1400);
INSERT INTO departments2 (department_id, department_name, manager_id, location_id)
VALUES (300, 'Soporte TI', NULL, 1700);

-- A4. La sesión que hizo los cambios SÍ los ve
SELECT * FROM departments2 WHERE department_id >= 280 ORDER BY department_id;

-- A5. (Opcional) Abrir una hoja NO compartida (Ctrl+Shift+N = otra sesión) y
--     ejecutar la misma consulta: devuelve 0 filas. Las filas no confirmadas
--     solo son visibles para la transacción que las creó.

-- A6. Cerrar sesión: clic derecho en la conexión > Desconectar.
--     SQL Developer detecta la transacción pendiente y pregunta si confirmar
--     (Commit) o deshacer (Rollback). Para el experimento se elige ROLLBACK.

/* ---------------------------- PARTE B (sesión 2) --------------------------- */
-- Reconectar como hr y consultar:

-- B1. La tabla existe (el CTAS se confirmó solo) pero las 3 filas NO están
SELECT COUNT(*) AS total FROM departments2;
SELECT * FROM departments2 WHERE department_id >= 280;

-- B2. Repetir las inserciones, ahora confirmándolas
INSERT INTO departments2 (department_id, department_name, manager_id, location_id)
VALUES (280, 'Analitica de Datos', 200, 1700);
INSERT INTO departments2 (department_id, department_name, manager_id, location_id)
VALUES (290, 'Ciberseguridad', 103, 1400);
INSERT INTO departments2 (department_id, department_name, manager_id, location_id)
VALUES (300, 'Soporte TI', NULL, 1700);
COMMIT;

-- B3. Desconectar, reconectar y consultar: las filas persisten (durabilidad)
SELECT * FROM departments2 WHERE department_id >= 280 ORDER BY department_id;
