--Actividad 2.4 Subconsultas

select *from Multas
select *from Agentes
--1
--La patente, apellidos y nombres del agente que labró la multa y monto de aquellas multas que superan el monto promedio.
select avg(Monto) from Multas

select M.Patente,M.monto,A.Apellidos,A.Nombres from Multas M 
inner join Agentes A on A.IdAgente=M.IdAgente
where M.Monto>(select avg(Monto) from Multas)
--2
--Las multas que sean más costosas que la multa más costosa por 'No respetar señal de stop'.
select max(Monto) from Multas
select *from TipoInfracciones

select * from Multas where Monto>(select top 1 M.Monto from Multas M
inner join TipoInfracciones TDI on TDI.IdTipoInfraccion=M.IdTipoInfraccion
where TDI.Descripcion='No respetar señal de stop'
order by M.Monto desc)

--3
--Los apellidos y nombres de los agentes que no hayan labrado multas en los dos primeros meses de 2023.
select *from Agentes
select A.IdAgente,A.Apellidos,A.Nombres from Agentes A where A.IdAgente in (
select distinct IdAgente from Multas where MONTH(FechaHora)!=1 and MONTH(FechaHora)!=2)
select *from Multas

--Sin subconsulta
select distinct A.IdAgente,A.Apellidos,A.Nombres from Agentes A
inner join Multas M on M.IdAgente=A.IdAgente
where MONTH(m.FechaHora)!=1 and MONTH(m.FechaHora)!=2

--4
--Los apellidos y nombres de los agentes que no hayan labrado multas por 'Exceso de velocidad'.
select * from TipoInfracciones


select * from Multas M
inner join TipoInfracciones TDI on TDI.IdTipoInfraccion=M.IdTipoInfraccion
where TDI.Descripcion='Exceso de velocidad'

--Este es
select A.IdAgente,A.Apellidos,A.Nombres from agentes A where A.IdAgente!=all(
select IdAgente from Multas M
inner join TipoInfracciones TDI on TDI.IdTipoInfraccion=M.IdTipoInfraccion
where TDI.Descripcion='Exceso de velocidad')

--5
--Los legajos, apellidos y nombre de los agentes que hayan labrado multas de todos los tipos de infracciones existentes.
select * from Multas M 
inner join TipoInfracciones TDI on TDI.IdTipoInfraccion=M.IdTipoInfraccion
having M.IdMulta=AlmacenBebidas
--6
--Los legajos, apellidos y nombres de los agentes que hayan labrado más cantidad de multas que la cantidad de 
--multas generadas por un radar (multas con IDAgente con valor NULL)
select *from Multas
--Cantidad de multas de radar
select COUNT(*) from Multas where IdAgente is null
--Sin subconsultas
select A.IdAgente,count(M.IdMulta) as CantidadMultas from Agentes A
inner join Multas M on M.IdAgente=A.IdAgente
group by A.IdAgente
having count(M.IdMulta)> (select COUNT(*) from Multas where IdAgente is null)

select A.Legajo,A.Apellidos,A.Nombres from Agentes A where A.IdAgente in(
select A.IdAgente from Agentes A
inner join Multas M on M.IdAgente=A.IdAgente
group by A.IdAgente
having count(M.IdMulta)> (select COUNT(*) from Multas where IdAgente is null))

--7
--Por cada agente, listar legajo, apellidos, nombres, cantidad de multas realizadas durante el día y 
--cantidad de multas realizadas durante la noche.
--NOTA: El turno noche ocurre pasadas las 20:00 y antes de las 05:00.
select IdMulta,DATEPART(HOUR,FechaHora) as Hora from Multas
select *from Multas

select count(*) from Multas where DATEPART(HOUR,FechaHora) between 05 and 20

select A.IdAgente,A.IdAgente,COUNT(M.IdMulta) as MultasNoche from Agentes A
inner join Multas M on M.IdAgente=A.IdAgente
where DATEPART(HOUR,FechaHora) not between 05 and 20
group by A.IdAgente,A.IdAgente

--El que anda
select A.Legajo,A.Apellidos,A.Nombres,
(select count(M.IdMulta) from Multas M where A.IdAgente=M.IdAgente and  DATEPART(HOUR,FechaHora)  between 05 and 20 ) as CantMultasDia,
(select count(M.IdMulta) from Multas M where A.IdAgente=M.IdAgente and  DATEPART(HOUR,FechaHora) not between 05 and 20) as CantMultasNoche
from Agentes A

--8
--Por cada patente, el total acumulado de pagos realizados con medios de pago no electrónicos y 
--el total acumulado de pagos realizados con algún medio de pago electrónicos.
select *from MediosPago
select *from Multas
select *from Pagos
select COUNT(distinct M.Patente) from Multas M

select COUNT(p.IDPago) from pagos P
inner join MediosPago Mp on Mp.IDMedioPago=P.IDMedioPago
where Mp.MedioPagoElectronico =1

select  distinct M.Patente,M.idMulta,
(select COUNT(p.IDPago) from pagos P
inner join MediosPago Mp on Mp.IDMedioPago=P.IDMedioPago
where Mp.MedioPagoElectronico =1 and P.IDMulta=M.IdMulta
) as PagosElectronicos,
(select COUNT(p.IDPago) from pagos P
inner join MediosPago Mp on Mp.IDMedioPago=P.IDMedioPago
where Mp.MedioPagoElectronico =0 and P.IDMulta=M.IdMulta) as PagosEfectivo
from Multas M

--9
--La cantidad de agentes que hicieron igual cantidad de multas por la noche que durante el día.
select count(*) from agentes A where
(select count(M.IdMulta) from Multas M where A.IdAgente=M.IdAgente and  DATEPART(HOUR,FechaHora)  between 05 and 20 ) 
=
(select count(M.IdMulta) from Multas M where A.IdAgente=M.IdAgente and  DATEPART(HOUR,FechaHora) not between 05 and 20) 

--10
--Las patentes que, en total, hayan abonado más en concepto de pagos con medios no electrónicos que pagos con medios electrónicos. 
--Pero debe haber abonado tanto con medios de pago electrónicos como con medios de pago no electrónicos.
select count(*) from MediosPago where MedioPagoElectronico=0
select *from Pagos

select M.IdMulta,M.Patente from Multas M
inner join Pagos P on P.IDMulta=M.IdMulta
inner join MediosPago Mp on Mp.IDMedioPago=P.IDMedioPago
having COUNT(mp.MedioPagoElectronico)>0 and

--11
--Los legajos, apellidos y nombres de agentes que hicieron más de dos multas durante el día y ninguna multa durante la noche.
select A.IdAgente,A.Legajo,A.Apellidos,A.Nombres from Agentes A where
(select count(M.IdMulta) from Multas M where A.IdAgente=M.IdAgente and  DATEPART(HOUR,FechaHora)  between 05 and 20 ) >2
and
(select count(M.IdMulta) from Multas M where A.IdAgente=M.IdAgente and  DATEPART(HOUR,FechaHora) not between 05 and 20) =0

select *from Multas
--12
--La cantidad de agentes que hayan registrado más multas que la cantidad de multas generadas por un radar 
--(multas con IDAgente con valor NULL)
select count(*) from Agentes A where 
(select count (*) from Multas M where M.IdAgente=A.IdAgente) >(select count (*) from Multas where IdAgente is null )

select count (*) from Multas M where M.IdAgente=A.IdAgente
select count (*) from Multas where IdAgente is null 
select *from Multas
--
--