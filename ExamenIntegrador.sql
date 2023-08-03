
--1)
create table Socios(
ID_Socio bigint primary key identity(1,1),
Apellidos varchar(50) not null,
Nombres varchar(50) not null,
FechaNacimiento datetime not null,
FechaAsociacion datetime not null,
Estado bit not null default 1
)
go
create table Actividad(
ID_Actividad bigint primary key identity(1,1),
Nombre varchar(50) not null,
FechaDisponibleDesde datetime not null,
CostoActividad money not null check(CostoActividad>=0),
Estado bit not null default 1
)
go
create table ActividadesXSocio(
ID_Socio bigint not null foreign key references Socios(ID_Socio),
ID_Actividad bigint not null foreign key references Actividad(ID_Actividad),
FechaInscripcion datetime not null
primary key (ID_Socio,ID_Actividad)
)
----------------------------------------------------------------------------------------------------
--2)
go
select S.ID_Socio,S.Apellidos,S.FechaNacimiento,S.FechaAsociacion,S.Estado from Socios S
where (select COUNT(*) from Actividad) = 
(select COUNT(*) from Actividad A
inner join ActividadesXSocio Axs on Axs.ID_Actividad=A.ID_Actividad
where Axs.ID_Socio=S.ID_Socio)

-------------------------------------------------------------------------------------------------------
--3)

create Trigger TG_InsertarDocente on PlantaDocente
after insert
as
begin 
	begin try
		begin transaction
			declare @LegajoDocente bigint
			declare @FechaRegistro int
			declare @Cargo tinyint
			declare @Materia bigint

			select @LegajoDocente= Legajo,@FechaRegistro=Año,@Cargo=ID_Cargo,@Materia=ID_Materia from inserted
			--no permita que un docente pueda tener una materia con el cargo de profesor
			--(IDCargo = 1) si no tiene una antigüedad de al menos 5 años
			if @Cargo=1 begin
				if (select YEAR(getdate())-AñoIngreso from Docentes where Legajo=@LegajoDocente) <5 begin
					raiserror('No tiene la antiguedad necesaria para tener el cargo de profesor',16,1)
				end

				--Tampoco debe permitir que haya más de un docente con el 
				--cargo de profesor (IDCargo = 1) en la misma materia y año
				if (select COUNT(*) from PlantaDocente where ID_Materia=@Materia and Año=@FechaRegistro)>1 begin
					raiserror('No puede haber mas de un docente en la misma materia y año',16,1)
				end

			end
			
		commit transaction
	end try
	begin catch
		rollback transaction
		print error_message()
	end catch
end

----------------------------------------------------------------------------------------------
--4)

create Function FN_CantHoras(
@Legajo bigint,
@Año int 
)
returns int
as
begin
	declare @HorasSemanales int
	select @HorasSemanales= isnull(sum(M.HorasSemanales),0) from PlantaDocente PD
	inner join Materias M on M.ID_Materia=Pd.ID_Materia
	where Pd.Legajo=@Legajo and PD.Año=@Año

	return @HorasSemanales
end

------------------------------------------------------------------
--5)

create procedure SP_ListarDocentes(
@IdMateria bigint
)
as
begin
	select COUNT(distinct Legajo) from PlantaDocente where ID_Materia=@IdMateria
end

