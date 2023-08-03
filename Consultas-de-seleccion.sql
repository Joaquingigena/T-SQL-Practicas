select *from Agentes
select *from TipoInfracciones
--1
--Listado con la cantidad de agentes
select count(*)from Agentes

--2
--Listado con importe de referencia promedio de los tipos de infracciones
select avg(ImporteReferencia) from TipoInfracciones

select SUM(ImporteReferencia)/COUNT(ImporteReferencia) from TipoInfracciones

--3
--Listado con la suma de los montos de las multas. Indistintamente de si fueron pagadas o no.
select SUM(Monto) from Multas

--4
--Listado con la cantidad de pagos que se realizaron.
select *from Pagos
select COUNT(*) from Pagos
--5
--Listado con la cantidad de multas realizadas en la provincia de Buenos Aires.
--NOTA: Utilizar el nombre 'Buenos Aires' de la provincia.
select COUNT(M.IdMulta) from Multas M
inner join Localidades L on L.IDLocalidad=M.IDLocalidad
inner join Provincias P on P.IDProvincia=L.IDProvincia
where P.Provincia = 'Buenos Aires'

select *from Multas
select *from Localidades
select *from Provincias
--6
--Listado con el promedio de antigüedad de los agentes que se encuentren activos.
select *from Agentes
--Antiguedad
select Apellidos, DateDiff(Year, 0, GETDATE()- Cast(FechaIngreso as Datetime)) as Antiguedad from Agentes where activo=1

select avg(DateDiff(Year, 0, GETDATE() - Cast(FechaIngreso as Datetime))) from Agentes where Activo=1

--7
--Listado con el monto más elevado que se haya registrado en una multa.
select MAX(Monto) from Multas
--8
--Listado con el importe de pago más pequeño que se haya registrado.
select *from Pagos
select MIN(Importe) from Pagos
--9
--Por cada agente, listar Legajo, Apellidos y Nombres y la cantidad de multas que registraron.
select A.Legajo,A.Apellidos,A.Nombres,COUNT(*) as CantMultas from Agentes A
inner join Multas M on M.IdAgente=A.IdAgente
group by A.Legajo,A.Apellidos,A.Nombres

select *from Agentes
--10
--Por cada tipo de infracción, listar la descripción y el promedio de montos de las multas asociadas a dicho tipo de infracción.
select *from TipoInfracciones
select TI.Descripcion, avg(M.Monto) as PromedioMultas from TipoInfracciones TI
inner join Multas M on M.IdTipoInfraccion=TI.IdTipoInfraccion
group by TI.Descripcion
--11
--Por cada multa, indicar la fecha, la patente, el importe de la multa y la cantidad de pagos realizados.
--Solamente mostrar la información de las multas que hayan sido pagadas en su totalidad.
select *from Multas
select *from Pagos
select M.IdMulta, M.FechaHora,M.Patente,M.Monto, COUNT(P.IDPago) as CantPagos from Multas M
left join Pagos P on P.IDMulta=M.IdMulta
group by M.IdMulta,M.FechaHora,M.Patente,M.Monto
having sum(P.Importe) >= M.Monto
--12
--Listar todos los datos de las multas que hayan registrado más de un pago.
select *from Multas
select *from Pagos
select M.IdMulta,M.IdTipoInfraccion,m.Patente,m.FechaHora from Multas M
inner join Pagos P on P.IDMulta=M.IdMulta
group by M.IdMulta,M.IdTipoInfraccion,m.Patente,m.FechaHora
having COUNT(p.IDPago)>1

--13
--Listar todos los datos de todos los agentes que hayan registrado multas con un monto que en promedio supere los $10000
select *from Agentes
select *from Multas
select A.IdAgente,A.Legajo,A.Nombres,A.Apellidos,A.FechaIngreso,A.FechaNacimiento from Agentes A
inner join Multas M on M.IdAgente=a.IdAgente
group by A.IdAgente,A.Legajo,A.Nombres,A.Apellidos,A.FechaIngreso,A.FechaNacimiento
having AVG(m.Monto)>10000
no salioooo
--14
--Listar el tipo de infracción que más cantidad de multas haya registrado.
select *from TipoInfracciones
select top 1 TDI.IdTipoInfraccion,TDI.Descripcion, COUNT(m.IdMulta)as CantidadMultas from TipoInfracciones TDI
inner join Multas M on M.IdTipoInfraccion=TDI.IdTipoInfraccion
group by TDI.IdTipoInfraccion,TDI.Descripcion
order by CantidadMultas desc


--15
--Listar por cada patente, la cantidad de infracciones distintas que se cometieron.
select *from Multas
select distinct M.Patente,COUNT(distinct Tdi.IdTipoInfraccion) from Multas M
inner join TipoInfracciones Tdi on tdi.IdTipoInfraccion=m.IdTipoInfraccion
group by m.Patente

--16
--Listar por cada patente, el texto literal 'Multas pagadas' y el monto total de los pagos registrados por esa patente.
--Además, por cada patente, el texto literal 'Multas por pagar' y el monto total de lo que se adeuda.
select distinct M.Patente,sum(m.Monto) as MultasPagadas from Multas M where Pagada=1
group by M.Patente
no saliooo
--17
--Listado con los nombres de los medios de pagos que se hayan utilizado más de 3 veces.
select *from MediosPago
select *from Pagos
select mp.IDMedioPago,mp.Nombre  from MediosPago MP
inner join Pagos P on P.IDMedioPago=MP.IDMedioPago
group by mp.IDMedioPago,mp.Nombre
having COUNT(p.IDPago)>3

--18
--Los legajos, apellidos y nombres de los agentes que hayan labrado más de 2 multas con tipos de infracciones distintas.
select *from Agentes
select *from Multas
select A.IdAgente,A.Legajo,A.Apellidos,A.Nombres from Agentes A
inner join Multas M on M.IdAgente=A.IdAgente
group by A.IdAgente,A.Legajo,A.Apellidos,A.Nombres
having COUNT(distinct m.IdTipoInfraccion)>2

--19
--El total recaudado en concepto de pagos discriminado por nombre de medio de pago.
select *from Pagos
select  mp.IDMedioPago,MP.Nombre,sum(P.Importe) as TotalRecaudado from MediosPago MP
inner join Pagos P on P.IDMedioPago=mp.IDMedioPago
group by mp.IDMedioPago,Mp.Nombre


--20
--Un listado con el siguiente formato:
--
--Descripción        Tipo           Recaudado
-------------------------------------------------
--Tigre              Localidad      $xxxx
--San Fernando       Localidad      $xxxx
--Rosario            Localidad      $xxxx
--Buenos Aires       Provincia      $xxxx
--Santa Fe           Provincia      $xxxx
--Argentina          País           $xxxx
--
select *from Localidades
select P.Provincia as Descripcion,'Provincia' as Tipo,sum(M.Monto) as TotalRecaudado from Provincias P
inner join Localidades L on L.IDProvincia=p.IDProvincia
inner join Multas M on M.IDLocalidad=L.IDLocalidad
group by P.Provincia
union
select L.Localidad  as Descripcion,'Localidad' as Tipo,sum(M.Monto) as TotalRecaudado from Localidades L
inner join Multas M on M.IDLocalidad=L.IDLocalidad
group by L.Localidad
order by Tipo asc
