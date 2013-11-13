all: clean
	for i in 1 2 3 4; do lout all.lt > sheriff.ps; done
	ps2pdf sheriff.ps

clean:
	-rm *.ld *.li *.ps *.pdf
