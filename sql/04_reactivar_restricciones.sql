/* =============================================================================
   Script   : 04_reactivar_restricciones.sql
   Conexión : hr@xepdb1
   Objetivo : Volver a establecer las restricciones y analizar qué ocurre cuando
              existen filas que no las cumplen.
   Idea     : ENABLE equivale a ENABLE VALIDATE: Oracle revisa TODAS las filas
              existentes. Si alguna incumple la regla, la restricción NO se
              activa (ORA-02293 CHECK, ORA-02298 FK, ORA-02299 UNIQUE).
              Con EXCEPTIONS INTO, Oracle registra el ROWID de cada fila culpable.
   ============================================================================= */
SET SERVEROUTPUT ON

-- 1. Tabla de excepciones (misma estructura que $ORACLE_HOME/rdbms/admin/utlexcpt.sql)
CREATE TABLE exceptions (
  row_id     ROWID,
  owner      VARCHAR2(128),
  table_name VARCHAR2(128),
  constraint VARCHAR2(128)
);

-- 2. Primer intento: reactivar todo, registrando las filas que fallan.
--    Orden: PK -> UNIQUE -> CHECK -> FK (una FK necesita su PK activa).
DECLARE
  v_sql VARCHAR2(400);
BEGIN
  FOR r IN (SELECT table_name, constraint_name, constraint_type
            FROM   user_constraints
            WHERE  table_name IN ('EMPLOYEES', 'DEPARTMENTS', 'JOB_HISTORY')
            AND    status = 'DISABLED'
            ORDER  BY DECODE(constraint_type, 'P', 1, 'U', 2, 'C', 3, 'R', 4),
                      table_name, constraint_name)
  LOOP
    v_sql := 'ALTER TABLE ' || r.table_name || ' ENABLE VALIDATE CONSTRAINT ' ||
             r.constraint_name || ' EXCEPTIONS INTO exceptions';
    BEGIN
      EXECUTE IMMEDIATE v_sql;
      DBMS_OUTPUT.PUT_LINE('OK    ' || r.constraint_name);
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('FALLA ' || r.constraint_name || ' -> ' || SQLERRM);
    END;
  END LOOP;
END;
/

-- 3. Estado tras el primer intento
SELECT table_name, constraint_name, status, validated
FROM   user_constraints
WHERE  table_name IN ('EMPLOYEES', 'DEPARTMENTS', 'JOB_HISTORY')
ORDER  BY status, table_name, constraint_name;

-- 4. Filas culpables identificadas por su ROWID
SELECT x.constraint, x.table_name, x.row_id,
       d.department_id AS dept_id, e.employee_id AS emp_id, e.email
FROM   exceptions x
LEFT   JOIN departments d ON d.ROWID = x.row_id
LEFT   JOIN employees   e ON e.ROWID = x.row_id
ORDER  BY x.table_name, x.constraint;

-- 5. Corrección de los datos.
--    OJO: no se borra "todo lo que aparece en EXCEPTIONS". Para EMP_EMAIL_UK
--    Oracle registra las DOS filas con email SKING, incluida la del empleado
--    100 (Steven King), que es válida. Se eliminan solo las filas de prueba.
DELETE FROM employees   WHERE employee_id   IN (900, 901, 902);
DELETE FROM departments WHERE department_id IN (500, 510);
COMMIT;

-- 6. Segundo intento: ya sin filas inválidas, todas deben activarse
DECLARE
  v_sql VARCHAR2(400);
BEGIN
  FOR r IN (SELECT table_name, constraint_name, constraint_type
            FROM   user_constraints
            WHERE  table_name IN ('EMPLOYEES', 'DEPARTMENTS', 'JOB_HISTORY')
            AND    status = 'DISABLED'
            ORDER  BY DECODE(constraint_type, 'P', 1, 'U', 2, 'C', 3, 'R', 4),
                      table_name, constraint_name)
  LOOP
    v_sql := 'ALTER TABLE ' || r.table_name || ' ENABLE VALIDATE CONSTRAINT ' ||
             r.constraint_name;
    EXECUTE IMMEDIATE v_sql;
    DBMS_OUTPUT.PUT_LINE(v_sql || ';');
  END LOOP;
END;
/

-- 7. Comprobación final: todas ENABLED / VALIDATED y el índice EMP_EMAIL_UK
--    vuelve a existir (Oracle lo recrea al activar la restricción UNIQUE)
SELECT table_name, constraint_name, status, validated
FROM   user_constraints
WHERE  table_name IN ('EMPLOYEES', 'DEPARTMENTS', 'JOB_HISTORY')
ORDER  BY table_name, constraint_name;

SELECT table_name, index_name, uniqueness
FROM   user_indexes
WHERE  table_name IN ('EMPLOYEES', 'DEPARTMENTS')
ORDER  BY table_name, index_name;

-- 8. Prueba de que las reglas vuelven a aplicarse: debe fallar con ORA-02290
INSERT INTO employees (employee_id, last_name, email, hire_date, job_id, salary)
VALUES (903, 'Control', 'CONTROL', SYSDATE, 'IT_PROG', -1);

-- Limpieza de la tabla auxiliar
DROP TABLE exceptions PURGE;

/* Alternativa conceptual (no ejecutada): ENABLE NOVALIDATE activa la regla
   solo para los datos NUEVOS y deja intactas las filas existentes, aunque
   la incumplan. Ej.: ALTER TABLE departments ENABLE NOVALIDATE CONSTRAINT dept_loc_fk; */
