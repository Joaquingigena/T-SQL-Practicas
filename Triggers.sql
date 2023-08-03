--Actividad 3.2 Triggers
select *from Agentes
--1
--Hacer un trigger que al eliminar un Agente su estado Activo pase de True a False.
create trigger TG_EliminarAgente on Agentes
instead of delete
as
begin
	declare @IdAgente int 
	 select @IdAgente = IdAgente from deleted

	 update Agentes set Activo=0 where IdAgente=@IdAgente
end

delete Agentes where IdAgente=1
--2
--Modificar el trigger anterior para que al eliminar un Agente y si su estado Activo ya se encuentra previamente en 
--False entonces realice las siguientes acciones:
--Cambiar todas las multas efectuadas por ese agente y establecer el valor NULL al campo IDAgente.
--Eliminar físicamente al agente en cuestión.
--Utilizar una transacción
create trigger TG_EliminarAgente on Agentes
instead of delete
as
begin
	begin try
		begin transaction
		declare @IdAgente int
		declare @Estado bit 
		 select @IdAgente = IdAgente,@Estado=Activo from deleted
	 
		 if @Estado= 0 begin
			update Multas set IdAgente=null where IdAgente=@IdAgente
			delete Agentes where IdAgente=@IdAgente
			
		 end
		 else begin
			update Agentes set Activo=0 where IdAgente=@IdAgente 
		 end	 
		 commit transaction
	end try
	begin catch 
		rollback transaction 
		raiserror('No se pudo modificar',16,1)
	end catch
end

select *from Agentes
select *from Multas
delete Agentes where IdAgente=7
--3
--Hacer un trigger que al insertar una multa realice las siguientes acciones:
--No permitir su ingreso si el Agente asociado a la multa no se encuentra Activo.
--Indicarlo con un mensaje claro que sea considerado una excepción.
--Establecer el Monto de la multa a partir del tipo de infracción.
--Aplicar un recargo del 20% al monto de la multa si no es la primera multa del vehículo en el año.
--Aplicar un recargo del 25% al monto de la multa si no es la primera multa del mismo tipo de infracción 
--del vehículo en el año.
--Establecer el estado Pagada como False.
alter trigger TG_insertMultas on Multas
after insert
as
begin
	--begin try
		begin transaction
			declare @Estado bit
			declare @IdAgente int
			declare @MontoReal money
			declare @IdTdi int 
			declare @idMulta int 
			declare @Patente varchar(10)
			declare @Año datetime
			declare @CantMultas int 

			select @IdAgente= IdAgente,@IdTdi=IdTipoInfraccion,@idMulta=IdMulta,@Patente=Patente,@Año=FechaHora from inserted
			select @Estado= Activo from Agentes where IdAgente=@IdAgente			
			select @MontoReal=ImporteReferencia from TipoInfracciones where IdTipoInfraccion= @IdTdi
			

			if @Estado = 1
			begin
				update Multas set Monto=@MontoReal,Pagada=0 where IdMulta=@idMulta
				--exec SP_MultasAño @Patente,@Año,@idMulta
				
				if (select isnull(count(*),0) from Multas where Patente=@Patente and YEAR(FechaHora)= YEAR(@Año))>0
				begin
					update Multas set Monto= Monto*1.2 where IdMulta=@idMulta
				end

				if dbo.FN_RecargoTdi (@Patente,@Año,@IdTdi,@IdMulta) >0begin
					update Multas set Monto= Monto*1.25 where IdMulta=@idMulta
				end

				commit transaction
			end
			else begin 
				rollback transaction
				raiserror('El agente se encuentra inactivo',16,1)
			end
	--end try
	--begin catch
	--		rollback transaction
	--end catch
end

------------------------------------------------------
--Aplicar un recargo del 25% al monto de la multa si no es la primera multa del mismo tipo de infracción 
--del vehículo en el año.
create function FN_RecargoTdi(
@Patente varchar(10),
@Año datetime,
@IdTDI int,
@IdMulta int
)
returns int
as
begin
	declare @Cant int
 	set @Cant= (select isnull(count(*),0) from Multas where Patente=@Patente and YEAR(FechaHora)= YEAR(@Año) and IdTipoInfraccion=@IdTDI)
	return @Cant
end


----------------------------------------------------------
declare @Fecha datetime
select @Fecha= GETDATE()
set @Fecha= @Fecha- YEAR(2)
select @Fecha
exec SP_MultasAño 'AB123CD',@Fecha 
---------------------------------------------------------------
--Pruebas
select *from agentes
select *from multas	where Patente ='AB123CD'
select *from TipoInfracciones

declare @Fecha datetime
select @Fecha= GETDATE()
set @Fecha= @Fecha- YEAR(2)
insert into Multas (IdTipoInfraccion,IdLocalidad,IdAgente,Patente,FechaHora,Monto,Pagada)
values (1,1,2,'AB123CD',@Fecha,1,1)

--4
--Hacer un trigger que al insertar un pago realice las siguientes verificaciones:
--Verificar que la multa que se intenta pagar se encuentra no pagada.
--Verificar que el Importe del pago sumado a los importes anteriores de la misma multa no superen el Monto a abonar.
--En ambos casos impedir el ingreso y mostrar un mensaje acorde.
--Si el pago cubre el Monto de la multa ya sea con un pago único o siendo la suma de pagos anteriores sobre la misma multa.
--Además de registrar el pago se debe modificar el estado Pagada de la multa relacionada.

alter trigger TG_InsertarPago on Pagos
after insert
as
begin
	
		begin transaction

			declare @Pagos money
			declare @IdMulta int
			select @Pagos= Importe,@IdMulta=IDMulta from inserted

			if (select isnull(sum(importe),0)-@Pagos from Pagos where IDMulta=@IdMulta)>=(select Monto from Multas where IdMulta=@IdMulta)
			begin
				rollback transaction
				raiserror('La multa ya se encuentra pagada',16,1)
			end

			if (select isnull(sum(importe),0) from Pagos where IDMulta=@IdMulta)>(select Monto from Multas where IdMulta=@IdMulta)
			begin
				rollback transaction
				raiserror('El pago supera al monto de la multa',16,1)
			end
			if (select isnull(sum(importe),0) from Pagos where IDMulta=@IdMulta)=(select Monto from Multas where IdMulta=@IdMulta)
			begin
				update Multas set Pagada=1 where IdMulta=@IdMulta
			end
			
			commit transaction
	
end

select *from Pagos where IDMulta=7
select *from Multas

insert into Pagos (IDMulta,Importe,Fecha,IDMedioPago) 
values (7,1,GETDATE(),1)


