/* =============================================================================
   Script   : 03_insertar_tuplas_invalidas.sql
   Conexión : hr@xepdb1
   Objetivo : Con las restricciones desactivadas, insertar filas que las violan.
              Cada INSERT indica qué restricción incumple.
   Ejecutar : como script (F5) para que un error no detenga el resto.
   ============================================================================= */

-- ---------------------------- DEPARTMENTS -----------------------------------
-- (D1) Viola DEPT_NAME_NN: department_name es obligatorio
INSERT INTO departments (department_id, department_name, manager_id, location_id)
VALUES (500, NULL, NULL, 1700);

-- (D2) Viola DEPT_MGR_FK (no existe el empleado 999) y DEPT_LOC_FK
--      (no existe la localización 9999)
INSERT INTO departments (department_id, department_name, manager_id, location_id)
VALUES (510, 'Investigacion', 999, 9999);

-- (D3) Intenta violar DEPT_ID_PK repitiendo el id 10.
--      Resultado esperado: ORA-00001. Aunque la restricción está desactivada,
--      el índice único DEPT_ID_PK sigue existiendo y es él quien impide el
--      duplicado (ver punto 5 del script 02).
INSERT INTO departments (department_id, department_name, manager_id, location_id)
VALUES (10, 'Administracion Duplicada', 200, 1700);

-- ----------------------------- EMPLOYEES ------------------------------------
-- (E1) Viola EMP_SALARY_MIN (salario negativo), EMP_JOB_FK (cargo inexistente),
--      EMP_DEPT_FK (departamento 999) y EMP_MANAGER_FK (jefe 9999)
INSERT INTO employees (employee_id, first_name, last_name, email, phone_number,
                       hire_date, job_id, salary, commission_pct, manager_id,
                       department_id)
VALUES (900, 'Ana', 'Prueba', 'APRUEBA', '515.123.0000',
        SYSDATE, 'XX_JOB', -500, NULL, 9999, 999);

-- (E2) Viola EMP_LAST_NAME_NN, EMP_EMAIL_NN, EMP_HIRE_DATE_NN y EMP_JOB_NN
INSERT INTO employees (employee_id, first_name)
VALUES (901, 'SinDatos');

-- (E3) Viola EMP_EMAIL_UK: el correo SKING ya pertenece al empleado 100.
--      Se permite porque el índice EMP_EMAIL_UK se eliminó al desactivar.
INSERT INTO employees (employee_id, last_name, email, hire_date, job_id)
VALUES (902, 'Duplicado', 'SKING', SYSDATE, 'IT_PROG');

COMMIT;

-- Verificación: filas "inválidas" que quedaron almacenadas
SELECT department_id, department_name, manager_id, location_id
FROM   departments
WHERE  department_id >= 500 OR department_name IS NULL;

SELECT employee_id, first_name, last_name, email, hire_date, job_id, salary,
       manager_id, department_id
FROM   employees
WHERE  employee_id >= 900;
