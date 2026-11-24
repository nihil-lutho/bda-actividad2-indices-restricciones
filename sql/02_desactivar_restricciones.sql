/* =============================================================================
   Script   : 02_desactivar_restricciones.sql
   Conexión : hr@xepdb1
   Objetivo : Listar y desactivar todas las restricciones de EMPLOYEES y
              DEPARTMENTS.
   Notas    :
   - Se desactivan primero las claves foráneas (R), luego CHECK/NOT NULL (C) y
     UNIQUE (U) y por último las claves primarias (P) con CASCADE.
   - CASCADE es obligatorio en las PK porque otras restricciones dependen de
     ellas (p. ej. JOB_HISTORY.JHIST_EMP_FK y JHIST_DEPT_FK). Sin CASCADE Oracle
     devuelve ORA-02297. Esas FK de JOB_HISTORY quedan también desactivadas y
     hay que reactivarlas en el script 04.
   ============================================================================= */
SET SERVEROUTPUT ON

-- 1. Estado inicial de las restricciones
SELECT table_name, constraint_name, constraint_type, status, validated,
       r_constraint_name, search_condition_vc AS condicion
FROM   user_constraints
WHERE  table_name IN ('EMPLOYEES', 'DEPARTMENTS')
ORDER  BY table_name, constraint_type, constraint_name;

-- 2. Restricciones de OTRAS tablas que apuntan a las PK de estas dos
SELECT table_name, constraint_name, r_constraint_name
FROM   user_constraints
WHERE  constraint_type = 'R'
AND    r_constraint_name IN (SELECT constraint_name
                             FROM   user_constraints
                             WHERE  table_name IN ('EMPLOYEES', 'DEPARTMENTS')
                             AND    constraint_type = 'P');

-- 3. Desactivación. El bloque genera y ejecuta cada ALTER TABLE y lo imprime,
--    de modo que queda constancia de la sentencia SQL exacta ejecutada.
DECLARE
  v_sql VARCHAR2(400);
BEGIN
  FOR r IN (SELECT table_name, constraint_name, constraint_type
            FROM   user_constraints
            WHERE  table_name IN ('EMPLOYEES', 'DEPARTMENTS')
            AND    status = 'ENABLED'
            ORDER  BY DECODE(constraint_type, 'R', 1, 'C', 2, 'U', 3, 'P', 4),
                      table_name, constraint_name)
  LOOP
    v_sql := 'ALTER TABLE ' || r.table_name || ' DISABLE CONSTRAINT ' ||
             r.constraint_name ||
             CASE WHEN r.constraint_type = 'P' THEN ' CASCADE' END;
    EXECUTE IMMEDIATE v_sql;
    DBMS_OUTPUT.PUT_LINE(v_sql || ';');
  END LOOP;
END;
/

-- 4. Estado tras la desactivación (incluye JOB_HISTORY por el CASCADE)
SELECT table_name, constraint_name, constraint_type, status, validated
FROM   user_constraints
WHERE  table_name IN ('EMPLOYEES', 'DEPARTMENTS', 'JOB_HISTORY')
ORDER  BY status, table_name, constraint_name;

-- 5. ¿Qué pasó con los índices? Oracle elimina el índice de una PK/UNIQUE al
--    desactivarla SOLO si el índice lo creó la propia restricción. En HR,
--    EMP_EMP_ID_PK y DEPT_ID_PK se crearon antes con CREATE UNIQUE INDEX, por
--    lo que se conservan; EMP_EMAIL_UK lo creó la restricción y desaparece.
SELECT table_name, index_name, uniqueness
FROM   user_indexes
WHERE  table_name IN ('EMPLOYEES', 'DEPARTMENTS')
ORDER  BY table_name, index_name;
