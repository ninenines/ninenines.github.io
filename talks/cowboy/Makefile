all: clean
	for i in 1 2 3 4; do lout all.lt > cowboy.ps; done
	ps2pdf cowboy.ps

clean:
	-rm *.ld *.li *.ps *.pdf
