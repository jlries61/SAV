PC = gpc
sav:sav.p queues.gpi ranklist.gpi
	$(PC) -o sav sav.p

queues.gpi:queues.p
	$(PC) -c queues.p

ranklist.gpi:ranklist.p
	$(PC) -c ranklist.p

clean: 
	rm sav *.o *.gpi

