/* =============================================================================
   Script   : 01_consulta_indices.sql
   Conexión : hr@xepdb1
   Objetivo : Consultar los índices disponibles en EMPLOYEES y DEPARTMENTS,
              las columnas que indexan y su relación con las restricciones.
   Equivalente gráfico en SQL Developer: Tablas > EMPLOYEES > pestaña "Índices".
   ============================================================================= */

-- 1. Índices de ambas tablas con su tipo, unicidad y columnas (en orden)
SELECT i.table_name,
       i.index_name,
       i.index_type,
       i.uniqueness,
       i.status,
       LISTAGG(c.column_name, ', ') WITHIN GROUP (ORDER BY c.column_position) AS columnas
FROM   user_indexes     i
JOIN   user_ind_columns c ON c.index_name = i.index_name
WHERE  i.table_name IN ('EMPLOYEES', 'DEPARTMENTS')
GROUP  BY i.table_name, i.index_name, i.index_type, i.uniqueness, i.status
ORDER  BY i.table_name, i.index_name;

-- 2. Qué restricciones (PK / UNIQUE) se apoyan en qué índice
SELECT table_name, constraint_name, constraint_type, index_name
FROM   user_constraints
WHERE  table_name IN ('EMPLOYEES', 'DEPARTMENTS')
AND    constraint_type IN ('P', 'U')
ORDER  BY table_name;

-- 3. Comprobación del uso de un índice por el optimizador.
--    La búsqueda por apellido debería resolverse con EMP_NAME_IX
--    (INDEX RANGE SCAN) en lugar de recorrer toda la tabla (FULL TABLE SCAN).
EXPLAIN PLAN FOR
SELECT employee_id, first_name, last_name
FROM   employees
WHERE  last_name = 'King';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, NULL, 'BASIC'));
