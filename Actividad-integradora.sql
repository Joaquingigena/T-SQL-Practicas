--Modelo de examen integrador 
select *from Fotografias
select *from Concursos
select *from Votaciones
select *from Participantes

--1)
--Hacer un procedimiento almacenado llamado SP_Ranking que a partir de un IDParticipante se pueda obtener las tres mejores 
--fotografías publicadas (si las hay). Indicando el nombre del concurso, apellido y nombres del participante, el título de 
--la publicación, la fecha de publicación y el puntaje promedio obtenido por esa publicación.
--(20 puntos)

alter procedure SP_Ranking(
@IDParticipante int 
)
as
begin
	
	select top 3 C.Titulo,P.Nombres,P.Apellidos,f.Titulo,f.Publicacion, isnull(AVG(V.Puntaje),0) as Promedio from Fotografias F
	inner join Concursos C on C.ID=F.IDConcurso
	inner join Participantes P on P.ID=F.IDParticipante
	LEFT join Votaciones V on V.IDFotografia=f.ID
	where P.ID=@IDParticipante
	group by  C.Titulo,P.Nombres,P.Apellidos,f.Titulo,f.Publicacion
	order by Promedio desc
end

exec SP_Ranking 7

select F.ID,isnull(avg(V.Puntaje),0) as promedio from Fotografias F
inner join Votaciones V on V.IDFotografia=F.ID
group by F.ID

select *from Votaciones where IDFotografia=1

----------------------------------------------------------------------
--2)
--Hacer un procedimiento almacenado llamado SP_Descalificar que reciba un ID de fotografía y realice 
--la descalificación de la misma. También debe eliminar todas las votaciones registradas a la fotografía en cuestión.
--Sólo se puede descalificar una fotografía si pertenece a un concurso no finalizado.

alter procedure SP_Descalificar(
@IdFotografia int 
)
as
begin
	begin transaction
		if (select Fin from Concursos C
		inner join Fotografias F on F.IDConcurso=C.ID
		where F.ID=@IdFotografia) < GETDATE()
		begin
			rollback transaction
			raiserror('El concurso yafinalizo',16,1)
		end
		else
		begin
			update Fotografias set Descalificada=1 where ID=@IdFotografia
			delete Votaciones where IDFotografia=@IdFotografia

			commit transaction
		end
end

select *from Fotografias
select *from Concursos
select *from Votaciones


exec SP_Descalificar 2

update Concursos set Fin='2023-11-15' where ID=3

select Fin from Concursos C
		inner join Fotografias F on F.IDConcurso=C.ID
		where F.ID=7


--------------------------------------------------------------
4)

--Al insertar una votación, verificar que el usuario que vota no lo haga más de una vez para el mismo 
--concurso ni se pueda votar a sí mismo. Tampoco puede votar una fotografía descalificada.
--Si ninguna validación lo impide insertar el registro de lo contrario, informarlo con un mensaje de error.

alter trigger TG_InsertarVotacion on Votaciones
after insert
as
begin
	begin try
		begin transaction
		declare @IdVotante int
		declare @IdFotografia int 
		declare @idConcurso bigint

		select @IdVotante= IDVotante,@IdFotografia=IDFotografia from inserted
		select @idConcurso= IDConcurso from Fotografias where ID=@IdFotografia
		

		--No se puede votar a una fotografia descalificada
		if (select Descalificada from Fotografias where ID=@IdFotografia) =1 begin
			raiserror('La fotografia se encuetra descalificada',16,1)
		end
		--No se puede votar a si mismo
		if @IdVotante = (select IDParticipante from Fotografias where @IdFotografia=ID)begin
			raiserror('No se puede votar a si mismo',16,1)
		end
		
		commit transaction
	end try
	begin catch
		rollback transaction
		print error_message()
	end catch
end

 where IDParticipante=1

insert into Votaciones (IDVotante,IDFotografia,Fecha,Puntaje)
values (2,3,GETDATE(),7)

select v.ID,v.IDVotante,f.id,f.IDConcurso,c.Titulo from Votaciones V
inner join Fotografias F on F.ID= V.IDFotografia
inner join Concursos C on C.ID=F.IDConcurso
where v.IDFotografia=1

select *from Fotografias
select *from Votaciones
select *from Concursos

select count(*) from Fotografias F 
inner join Votaciones V on V.IDFotografia= F.ID
where v.IDVotante=4
--------------------------------------------------------------
--Hacer un listado en el que se obtenga: ID de participante, apellidos y nombres de los participantes 
--que hayan registrado al menos dos fotografías descalificadas.

select P.ID,P.Apellidos,P.Nombres from Participantes P 
where (select isnull(count(*),0) from Fotografias where IDParticipante=P.ID and Descalificada=1 )>=2

select *from Votaciones
select *from Concursos
select *from Fotografias

update Fotografias set Descalificada=1 where ID=2

--3)
--Al insertar una fotografía verificar que el usuario creador de la fotografía tenga el ranking suficiente 
--para participar en el concurso. También se debe verificar que el concurso haya iniciado y no finalizado.
--Si ocurriese un error, mostrarlo con un mensaje aclaratorio. De lo contrario, insertar el registro teniendo 
--en cuenta que la fecha de publicación es la fecha y hora del sistema.

alter trigger TG_InsertFotografia on Fotografias
after insert
as
begin
	begin try
	declare @idParticipante bigint
	declare @idConcurso bigint
	select @idParticipante = IDParticipante,@idConcurso=IDConcurso from inserted
		begin transaction
		--Usuario tiene que tener el ranking suficiente (mayor que el minimo)
		if (select RankingMinimo from Concursos where ID=@idConcurso) <=
			(select isnull(AVG(V.Puntaje),0) from Fotografias F
			inner join Votaciones V on V.IDFotografia= F.ID
			where IDParticipante=@idParticipante)
		begin
			--El concurso tiene que haber iniciado y no terminado
			if (select Inicio from Concursos where ID=@idConcurso ) > GETDATE() or
			(select Fin from Concursos where ID=@idConcurso) < GETDATE()
			begin
				raiserror('El concurso no esta en el rango de fechas',16,1)
			end
			
			commit transaction
		end
		else
		begin
			raiserror('El usuario no supera el ranking minimo',16,1)
		end
		
		
	end try
	begin catch
		rollback transaction
		print error_message()
	end catch
end


select *from Concursos
select *from Fotografias
select *from Participantes
select *from Votaciones

select F.IDParticipante, isnull(AVG(V.Puntaje),0) from Fotografias F
inner join Votaciones V on V.IDFotografia= F.ID
group by F.IDParticipante


--participante 5 concurso 3
insert into Fotografias (IDParticipante,IDConcurso,Titulo,Descalificada,Publicacion)
values (1,4,'',0,getdate())

update Concursos set RankingMinimo=8,Fin='2023-11-20' where ID=4


