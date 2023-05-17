# Main makefile for Speedy.f90

.PHONY:clean
all: 
	$(MAKE) -C speedy.f90

.PHONY:clean
test:	
	pytest -s -v pyspeedyaqua

.PHONY:clean
clean:   
	$(MAKE) -C speedy.f90 clean
	@rm -f pyspeedyaqua/*.so

