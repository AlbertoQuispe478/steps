# ============================================================
#  Makefile — compila toda la documentación de Albert
#  Uso: make all | make arquitectura | make bitacoras | make fichas
# ============================================================

LATEX = pdflatex -interaction=nonstopmode -file-line-error

all: arquitectura bitacoras fichas

arquitectura:
	cd Arquitectura && $(LATEX) arquitectura.tex && $(LATEX) arquitectura.tex

bitacoras:
	cd Bitacoras && for f in semana*.tex; do \
		$(LATEX) $$f && $(LATEX) $$f; \
	done

fichas:
	cd Fichas/sprint1 && for f in hu*.tex; do $(LATEX) $$f && $(LATEX) $$f; done
	cd Fichas/sprint2 && for f in hu*.tex; do $(LATEX) $$f && $(LATEX) $$f; done
	cd Fichas/sprint3 && for f in hu*.tex; do $(LATEX) $$f && $(LATEX) $$f; done
	cd Fichas/sprint4 && for f in hu*.tex; do $(LATEX) $$f && $(LATEX) $$f; done
	cd Fichas/sprint5 && for f in hu*.tex; do $(LATEX) $$f && $(LATEX) $$f; done

clean:
	find . -name "*.aux" -delete
	find . -name "*.log" -delete
	find . -name "*.toc" -delete
	find . -name "*.out" -delete

.PHONY: all arquitectura bitacoras fichas clean
