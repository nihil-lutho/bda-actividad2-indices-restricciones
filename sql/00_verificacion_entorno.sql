/* =============================================================================
   Actividad 2 - Índices y restricciones en Oracle
   Asignatura : Bases de Datos Avanzadas
   Script     : 00_verificacion_entorno.sql
   Conexión   : hr@xepdb1 (SQL Developer)  |  Oracle Database 21c XE
   Objetivo   : Confirmar que la sesión está iniciada con el usuario HR, en la
                PDB correcta, y que las tablas del esquema están disponibles.
   ============================================================================= */

-- 1. Usuario y contenedor de la sesión actual
SELECT USER                                   AS usuario,
       SYS_CONTEXT('USERENV', 'CON_NAME')     AS contenedor,
       SYS_CONTEXT('USERENV', 'SID')          AS sid_sesion
FROM   dual;

-- 2. Tablas del esquema HR y número de filas (estadísticas del diccionario)
SELECT table_name, num_rows
FROM   user_tables
ORDER  BY table_name;

-- 3. Disparadores de EMPLOYEES. En el esquema HR original SECURE_EMPLOYEES
--    está deshabilitado; si estuviera ENABLED, las inserciones fuera del
--    horario 08:00-18:00 fallarían con ORA-20205.
SELECT trigger_name, triggering_event, status
FROM   user_triggers
WHERE  table_name = 'EMPLOYEES';

-- Solo si SECURE_EMPLOYEES aparece ENABLED:
-- ALTER TRIGGER secure_employees DISABLE;
