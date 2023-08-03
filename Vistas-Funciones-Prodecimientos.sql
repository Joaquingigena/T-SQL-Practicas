--Actividad 3.1
--1
--Crear una vista llamada VW_Multas que permita visualizar la información de las multas con los datos del 
--agente incluyendo apellidos y nombres, nombre de la localidad, patente del vehículo, fecha y monto de la multa.
select *from Multas

create view VW_Multas
as
select A.Nombres,A.Apellidos,L.Localidad,M.Patente,M.FechaHora,M.Monto from Multas M
inner join Agentes A on A.IdAgente=M.IdAgente
inner join Localidades L on L.IDLocalidad=M.IDLocalidad

--2
--Modificar la vista VW_Multas para incluir el legajo del agente, la antigüedad en años, el nombre de la 
--provincia junto al de la localidad y la descripción del tipo de multa.
select Nombres,Apellidos,datediff(year,0,GETDATE()-cast(FechaIngreso as datetime)) as Antiguedad from Agentes
datediff(year(),0,)
select *from Agentes
alter view VW_Multas
as
select A.Nombres,A.Apellidos,A.Legajo,DATEDIFF(YEAR,0,GETDATE()-cast(A.FechaIngreso as datetime)) as Antiguedad ,L.Localidad,P.Provincia,M.Patente,M.FechaHora,M.Monto,TDi.Descripcion from Multas M
inner join Agentes A on A.IdAgente=M.IdAgente
inner join Localidades L on L.IDLocalidad=M.IDLocalidad
inner join Provincias P on P.IDProvincia=L.IDProvincia
inner join TipoInfracciones TDI on TDI.IdTipoInfraccion=M.IdTipoInfraccion

select *from VW_Multas
--3
--Crear un procedimiento almacenado llamado SP_MultasVehiculo que reciba un parámetro que 
--representa la patente de un vehículo. Listar las multas que registra. Indicando fecha y hora de la multa, 
--descripción del tipo de multa e importe a abonar. También una leyenda que indique si la multa fue abonada o no.
create procedure SP_MultasVehiculo(
@Patente varchar(10)
)
as
begin 
select M.IdMulta,M.Patente,M.FechaHora,TDi.Descripcion,M.Monto,
case
	when (select SUM(Importe) from Pagos P where P.IDMulta=M.IdMulta and @Patente=M.Patente) >M.Monto then 'Abonada'
	when (select SUM(Importe) from Pagos P where P.IDMulta=M.IdMulta and @Patente=M.Patente) >0 then 'Pago parcial'
	else 'No abonada'
end as EstadoMulta
from Multas M
inner join TipoInfracciones TDI on TDi.IdTipoInfraccion=M.IdTipoInfraccion
where M.Patente=@Patente
end
select *from Pagos
select *from Multas
exec SP_MultasVehiculo 'AB123CD'
--4
--Crear una función que reciba un parámetro que representa la patente de un vehículo y devuelva el 
--total adeudado por ese vehículo en concepto de multas.
create function FN_DeudaXPatente(
@Patente varchar(10)
)
returns money
as
begin
select M.Monto -sum(P.Importe) from Multas M
inner join Pagos P on P.IDMulta=M.IdMulta
where M.Patente='AB123CD'
end

select sum(M.Monto- P.Importe) from Multas M
inner join Pagos P on P.IDMulta=M.IdMulta
where M.Patente='AB123CD'
group by M.Monto

--5
--Crear un procedimiento almacenado llamado SP_AgregarMulta que reciba IDTipoInfraccion, IDLocalidad, IDAgente, 
--Patente, Fecha y hora, Monto a abonar y registre la multa.
create procedure SP_AgregarMulta(
@IdTipoInfraccion int,
@IdLocalidad int,
@IdAgente int,
@Patente varchar(10),
@FechaHora datetime,
@Monto money
)as
begin
insert into Multas (IdTipoInfraccion,IDLocalidad,IdAgente,Patente,FechaHora,Monto,Pagada) values(@IdTipoInfraccion,@IdLocalidad,@IdAgente,@Patente,@FechaHora,@Monto,0)
end

select *from TipoInfracciones
select *from Multas
declare @FechaHora datetime
set @FechaHora= GETDATE()
exec SP_AgregarMulta 20,1,1,'111aaa11',@FechaHora,1
--
--
--6
--Crear un procedimiento almacenado llamado SP_ProcesarPagos que determine el estado Pagada de 
--todas las multas a partir de los pagos que se encuentran registrados 
--(La suma de todos los pagos de una multa debe ser igual o mayor al monto de la multa para considerarlo Pagado).
create procedure SP_ProcesarPagos
as
begin
select distinct M.IdMulta,M.Patente,M.Monto,
case
	when (select sum(Importe) from Pagos where IdMulta=M.IdMulta)>=M.Monto then 'Pagada'
	else 'No pagada'
end as Estado
from Multas M
left join Pagos P on P.IDMulta=M.IdMulta

end

select *from Multas
select distinct M.IdMulta,M.Patente,M.Monto,
case
	when (select sum(Importe) from Pagos where IdMulta=M.IdMulta)>=M.Monto then 'Pagada'
	else 'No pagada'
end as Estado
from Multas M
left join Pagos P on P.IDMulta=M.IdMulta


select distinct M.IdMulta,M.Patente,M.Monto,P.IDMulta,P.IDPago,P.Importe from Multas M
inner join Pagos P on P.IDMulta=M.IdMulta

update Multas set Monto=50000 where IdMulta=1

exec SP_ProcesarPagos