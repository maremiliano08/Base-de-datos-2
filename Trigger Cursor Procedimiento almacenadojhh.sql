-------------------------------------------------------------------TRIGGER---------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION tg_cupoMaximo () RETURNS TRIGGER AS
$$
DECLARE
acumCupos int;
BEGIN
   Select  count (*) into acumCupos FROM matricula WHERE id_nivel = new.id_nivel;
   if ( acumCupos >= 15 ) then
    RAISE  EXCEPTION 'Matricula no permitida, se alcanzo el maximo de matriculas por este periodo';
    END if;
RETURN new;
END
$$
LANGUAGE plpgsql;
CREATE trigger tg_cupoMaximo before insert
on MATRICULA FOR EACH ROW
execute procedure tg_cupoMaximo ();
-------------------------------------------------------------------CURSOR----------------------------------------------------------------------------------
DO $$
DECLARE
		VIGENCIA RECORD;
		CURSOR_FECHA CURSOR FOR
							  SELECT 
							  nivel.fecha_inicio as inicio,
							  nivel.fecha_fin as fin,
							  ano_dios.vigencia as vigencia,
							  catequista.nom_catequista as nom_catequista,
							  catequista.apll_catequista as apll_catequista
							  from catequista
							  inner join nivel on nivel.fecha_inicio = nivel.fecha_inicio
							  inner join ano_dios on ano_dios.vigencia = ano_dios.vigencia
							  group by nivel.fecha_inicio,nivel.fecha_fin,ano_dios.vigencia,catequista.nom_catequista,catequista.apll_catequista;
BEGIN							  
OPEN CURSOR_FECHA;
FETCH CURSOR_FECHA INTO VIGENCIA;
WHILE(FOUND)LOOP
RAISE NOTICE 'nom_catequista: %, apll_catequista: %, inicio: %, fin: %, vigencia: %',
	VIGENCIA.nom_catequista,
	VIGENCIA.apll_catequista,
	VIGENCIA.inicio,
	VIGENCIA.fin,
	VIGENCIA.vigencia;
FETCH CURSOR_FECHA INTO VIGENCIA;
END LOOP;
END $$
LANGUAGE PLPGSQL;
----------------------------------------------PROCEDIMIENTO ALMACENADO---------------------------------------------------------------------------------

CREATE or replace  FUNCTION obtenerCursoCatequista(varchar)	RETURNS varchar
AS $BODY$
DECLARE
	apellido alias for $1;
	datos RECORD;
	cur_datos cursor FOR select c2.cur_nivel as nivel, sum( c2.cur_cant_alumno) as cantidad
								from catequista as c1 
								inner join registro_curso as r1 on c1.cat_id = r1.cat_id
								inner join curso as c2 on r1.cur_id = c2.cur_id 
								where c1.cat_apellido = $1
								group by nivel	order by nivel , cantidad asc;		
begin
	for datos in cur_datos loop
	Raise notice 'Nivel: %, Cantidad alumnos: %', datos.nivel, datos.cantidad;
	end loop;
end; $BODY$
language 'plpgsql';
