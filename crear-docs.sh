#!/usr/bin/env bash
# ============================================================
#  crear-docs.sh — Crea la estructura completa de docs/ para Albert/Tuulapp
#  Ejecutar UNA VEZ desde ~/Albert/
# ============================================================
set -e

DOCS=~/Albert/docs

if [ -d "$DOCS" ]; then
  echo "⚠️  La carpeta $DOCS ya existe. ¿Sobrescribir? (s/n)"
  read -r resp
  [ "$resp" != "s" ] && echo "Cancelado." && exit 0
  rm -rf "$DOCS"
fi

mkdir -p "$DOCS"/{Propuesta,Arquitectura,Bitacoras,Fichas/sprint1/mockups,Fichas/sprint2/mockups,Fichas/sprint3/mockups,Fichas/sprint4/mockups,Fichas/sprint5/mockups}

# ============================================================
# 1. PROPUEStA — comun.tex
# ============================================================
cat > "$DOCS/Propuesta/comun.tex" << 'EOF'
% ============================================================
%  comun.tex — configuración compartida para Albert / Tuulapp
% ============================================================
\usepackage[utf8]{inputenc}
\usepackage[T1]{fontenc}
\usepackage[spanish]{babel}
\usepackage{geometry}
\geometry{letterpaper, margin=2.5cm}
\usepackage{graphicx}
\usepackage{fancyhdr}
\usepackage{lastpage}
\usepackage{hyperref}
\hypersetup{colorlinks=true, linkcolor=blue, urlcolor=cyan}
\usepackage{array}
\usepackage{booktabs}
\usepackage{longtable}
\usepackage{enumitem}
\usepackage{xcolor}
\usepackage{listings}
\usepackage{tikz}
\usetikzlibrary{positioning, shapes, arrows.meta, calc}

\definecolor{albertblue}{RGB}{30, 90, 160}
\definecolor{albertgray}{RGB}{100, 100, 100}
\definecolor{albertgreen}{RGB}{0, 130, 80}

\lstdefinestyle{albert}{
    backgroundcolor=\color{gray!10},
    basicstyle=\ttfamily\footnotesize,
    keywordstyle=\color{albertblue}\bfseries,
    stringstyle=\color{albertgreen},
    commentstyle=\color{albertgray}\itshape,
    numbers=left, numberstyle=\tiny\color{albertgray},
    breaklines=true, frame=single
}
\lstset{style=albert}

\newcommand{\LogoHorizontal}[1]{%
  \IfFileExists{logo-horizontal.png}{%
    \includegraphics[height=#1]{logo-horizontal.png}%
  }{\textbf{\color{albertblue}ALBERT/TUULAPP}}%
}

\newcolumntype{L}[1]{>{\raggedright\arraybackslash}p{#1}}
\newcolumntype{C}[1]{>{\centering\arraybackslash}p{#1}}
\newcolumntype{R}[1]{>{\raggedleft\arraybackslash}p{#1}}

\input{datos.tex}
EOF

# ============================================================
# 2. PROPUEStA — datos.tex
# ============================================================
cat > "$DOCS/Propuesta/datos.tex" << 'EOF'
% ============================================================
%  datos.tex — datos del proyecto Albert / Tuulapp
% ============================================================
\newcommand{\Sistema}{Albert/Tuulapp}
\newcommand{\NombreProyecto}{Sistema de Gestión de Taller Mecánico}
\newcommand{\NombreLargo}{NexaSoft S.R.L.}
\newcommand{\Semestre}{2/2026}
\newcommand{\Universidad}{Universidad Mayor de San Simón}
\newcommand{\Materia}{Taller de Ingeniería de Software}
\newcommand{\RepLegal}{Alberto Quispe Ramírez}
\newcommand{\ConsultorTIS}{Ing.\ Docente}
EOF

# ============================================================
# 3. ARQUITECTURA — cuerpo.tex
# ============================================================
cat > "$DOCS/Arquitectura/cuerpo.tex" << 'EOF'
\documentclass[11pt,letterpaper]{article}
\input{../Propuesta/comun}

\pagestyle{fancy}
\fancyhf{}
\fancyhead[L]{\raisebox{-3pt}{\LogoHorizontal{2.5cm}}}
\fancyhead[R]{\footnotesize Documento de Arquitectura \,$\cdot$\, \Sistema}
\fancyfoot[C]{\footnotesize \thepage\ de \pageref{LastPage}}
\renewcommand{\headrulewidth}{0.4pt}

\begin{document}

\begin{titlepage}
    \centering
    \vspace*{2cm}
    {\Large \textbf{\Universidad}}\\[0.3cm]
    {\large \Materia\ --- \Semestre}\\[2cm]
    \LogoHorizontal{4cm}\\[1cm]
    {\Huge \textbf{Documento de Arquitectura}}\\[0.5cm]
    {\LARGE \Sistema}\\[0.3cm]
    {\large \NombreProyecto}\\[3cm]
    {\large Equipo: \NombreLargo}\\[0.2cm]
    {\large \today}
    \vfill
\end{titlepage}

\tableofcontents
\newpage

\section{Introducción}
Este documento describe la arquitectura de \Sistema\ siguiendo el modelo C4 (Contexto, Contenedores, Componentes, Código), conforme a la asignatura \Materia.

\section{Modelo C4}

\subsection{Nivel 1: Diagrama de Contexto}
El sistema interactúa con cuatro actores (cliente, mecánico, recepcionista, administrador) y con tres sistemas externos (Supabase, pasarela de notificaciones, pasarela de pagos).

\begin{figure}[htbp]
\centering
\begin{tikzpicture}[
    person/.style={circle, draw=albertblue, fill=albertblue!20, minimum size=1.4cm, align=center, font=\scriptsize},
    system/.style={rectangle, rounded corners, draw=albertblue, fill=albertblue!30, minimum width=3cm, minimum height=1.2cm, align=center, font=\scriptsize},
    external/.style={rectangle, dashed, draw=red!60, fill=red!10, minimum width=2.2cm, minimum height=1cm, align=center, font=\scriptsize},
    arrow/.style={-{Stealth[scale=1.2]}, thick}
]
    \node[person] (cliente) {Cliente};
    \node[person, right=2.5cm of cliente] (mecanico) {Mecánico};
    \node[person, below=1.3cm of cliente] (admin) {Admin};
    \node[system, right=3cm of mecanico] (sistema) {\textbf{Albert/Tuulapp}};
    \node[external, below=1.3cm of sistema] (supa) {Supabase};
    \node[external, above=1.3cm of sistema] (notif) {Notificaciones};

    \draw[arrow] (cliente) -- (sistema);
    \draw[arrow] (mecanico) -- (sistema);
    \draw[arrow] (admin) -- (sistema);
    \draw[arrow, dashed] (sistema) -- (supa);
    \draw[arrow, dashed] (sistema) -- (notif);
\end{tikzpicture}
\caption{Diagrama de Contexto (C4 Nivel 1).}
\end{figure}

\subsection{Nivel 2: Diagrama de Contenedores}
\begin{figure}[htbp]
\centering
\begin{tikzpicture}[
    container/.style={rectangle, rounded corners, draw=albertblue, fill=albertgreen!20, minimum width=3cm, minimum height=1.2cm, align=center, font=\scriptsize},
    arrow/.style={-{Stealth[scale=1.2]}, thick}
]
    \node[container] (app) {\textbf{App Móvil}\\React Native};
    \node[container, right=2cm of app] (api) {\textbf{API Backend}\\Node.js + Express};
    \node[container, below=1.5cm of api] (db) {\textbf{PostgreSQL 15}\\32 tablas};

    \draw[arrow] (app) -- node[above, font=\tiny]{HTTPS} (api);
    \draw[arrow] (api) -- node[right, font=\tiny]{SQL} (db);
\end{tikzpicture}
\caption{Diagrama de Contenedores (C4 Nivel 2).}
\end{figure}

\subsection{Nivel 3: Diagrama de Componentes}
El backend se organiza en módulos de negocio: Auth, Taller, Presupuesto, Citas, Notificaciones, Pagos y BI.

\subsection{Nivel 4: Diagrama de Código (ER)}
El modelo de datos consta de 32 tablas documentadas en \texttt{database/schema.sql}.

\section{Atributos de Calidad}
\begin{itemize}
    \item \textbf{Mantenibilidad:} código modular por capas (routes, controllers, models).
    \item \textbf{Escalabilidad:} arquitectura preparada para microservicios.
    \item \textbf{Seguridad:} JWT + bcrypt + Helmet + Rate Limit.
    \item \textbf{Testeabilidad:} Jest + Supertest.
\end{itemize}

\begin{thebibliography}{9}
\bibitem{brown} Simon Brown. \textit{The C4 model for visualising software architecture}. \url{https://c4model.com/}, 2022.
\end{thebibliography}

\end{document}
EOF

cat > "$DOCS/Arquitectura/arquitectura.tex" << 'EOF'
\input{cuerpo}
EOF

# ============================================================
# 4. BITACORAS — cuerpo.tex
# ============================================================
cat > "$DOCS/Bitacoras/cuerpo.tex" << 'EOF'
\documentclass[11pt,letterpaper]{article}
\input{../Propuesta/comun}

\pagestyle{fancy}
\fancyhf{}
\fancyhead[L]{\raisebox{-3pt}{\LogoHorizontal{2.5cm}}}
\fancyhead[R]{\footnotesize Bitácora \,$\cdot$\, Semana \SemanaNro\ \,$\cdot$\, Sprint \SprintNro}
\fancyfoot[C]{\footnotesize \thepage}
\renewcommand{\headrulewidth}{0.4pt}

\usepackage{needspace}
\newcommand{\apartado}[1]{\vspace{0.65em}\needspace{6\baselineskip}\noindent{\bfseries #1}\par\vspace{-0.4em}\noindent\rule{\textwidth}{0.5pt}\par\vspace{0.1em}}
\newcommand{\caja}[1]{\begin{center}\begin{tabular}{@{}p{15.4cm}@{}}\hline \rule{0pt}{#1} \\ \hline\end{tabular}\end{center}}

\begin{document}

\begin{center}
{\Large\bfseries Bitácora de Seguimiento de Proyecto}
\end{center}

\apartado{1. Información General}
\begin{center}
\begin{tabular}{@{}>{\bfseries}p{4cm}p{11cm}@{}}
\hline
Nombre del proyecto & \Sistema\ (\NombreProyecto) \\
\hline
Grupo / Equipo      & \NombreLargo \\
\hline
Semana N.\textsuperscript{o} & \SemanaNro\ \quad({\itshape sprint} \SprintNro) \\
\hline
Fecha               & \FechaIni\ -- \FechaFin \\
\hline
\end{tabular}
\end{center}

\apartado{2. Avance semanal}
\BitAvanceTexto

\apartado{3. Actividades realizadas}
\begin{longtable}{@{}C{1cm}L{8cm}L{4cm}C{2cm}@{}}
\hline
\textbf{N.} & \textbf{Actividad} & \textbf{Responsable(s)} & \textbf{Estado} \\
\hline
\endhead
\BitActividades
\end{longtable}

\apartado{4. Acuerdos alcanzados}
\BitAcuerdosTexto

\apartado{5. Dificultades encontradas}
\BitDificultadesTexto

\apartado{6. Tareas pendientes}
\begin{longtable}{@{}C{1cm}L{8cm}L{3.6cm}C{2.6cm}@{}}
\hline
\textbf{N.} & \textbf{Actividad} & \textbf{Responsable(s)} & \textbf{Fecha límite} \\
\hline
\endhead
\BitPendientes
\end{longtable}

\apartado{7. Aportes individuales}
\begin{longtable}{@{}L{4.6cm}L{5.6cm}L{3cm}C{2cm}@{}}
\hline
\textbf{Apellido Nombre} & \textbf{Aporte} & \textbf{Rol} & \textbf{Nivel} \\
\hline
\endhead
\BitAportes
\end{longtable}

\apartado{8. Evaluación interna}
\begin{tabular}{@{}L{3.6cm}C{2cm}L{3.6cm}C{2cm}@{}}
\hline
Organización & \BitEvalOrganizacion & Comunicación & \BitEvalComunicacion \\
\hline
Cumplimiento & \BitEvalCumplimiento & Compromiso & \BitEvalCompromiso \\
\hline
\end{tabular}

\apartado{9. Reflexión del equipo}
\BitReflexionTexto

\apartado{10. Observaciones del docente}
\caja{3.6cm}

\end{document}
EOF

# ============================================================
# 5. FICHAS — cuerpo.tex
# ============================================================
cat > "$DOCS/Fichas/cuerpo.tex" << 'EOF'
\documentclass[11pt,letterpaper]{article}
\input{../Propuesta/comun}

\pagestyle{fancy}
\fancyhf{}
\fancyhead[L]{\raisebox{-3pt}{\LogoHorizontal{2.5cm}}}
\fancyhead[R]{\footnotesize Ficha de Historia de Usuario}
\fancyfoot[C]{\footnotesize \thepage}
\renewcommand{\headrulewidth}{0.4pt}

\usepackage[breakable,skins]{tcolorbox}
\newtcolorbox{CajaCriterios}{breakable, enhanced jigsaw, sharp corners,
  colback=white, colframe=black, boxrule=0.8pt,
  left=6pt, right=6pt, top=4pt, bottom=4pt}

\newcommand{\CajaMockup}[1]{%
  \begin{center}
  \IfFileExists{../Fichas/#1.png}{%
    \includegraphics[width=0.94\linewidth]{../Fichas/#1}%
  }{\parbox[c][5cm][c]{0.9\linewidth}{\centering\itshape
      Mockup pendiente en \texttt{Fichas/#1.png}}}
  \end{center}}

\begin{document}
\noindent{\Large\bfseries Historia de Usuario \HUNro}

\vspace{0.3em}
\begin{center}
\begin{tabular}{|p{1.7cm}|p{13cm}|p{1.5cm}|}
\hline
\rule{0pt}{1.6em}\textbf{HU-\HUNro} & \textbf{TÍTULO:} \HUTitulo &
  {\footnotesize\HUModulo\ $\cdot$ Req. \HUReq\ $\cdot$ \HUPuntos\ pts} \\
\hline
\end{tabular}
\end{center}

\vspace{0.2em}
\begin{center}
\begin{tabular}{|p{16.6cm}|}
\hline
\rule{0pt}{1.2em}\textbf{Como} \HUComo \par\vspace{0.5em}
\textbf{Quiero} \HUQuiero \par\vspace{0.5em}
\textbf{Para} \HUPara\par\vspace{0.3em} \\
\hline
\end{tabular}
\end{center}

\vspace{0.6em}
\noindent{\Large\bfseries MOCKUP}
\begin{center}
\begin{tabular}{|p{16.6cm}|}
\hline
\rule{0pt}{0.3em}\CajaMockup{\HUMockupArchivo}\vspace{0.3em} \\
\hline
\end{tabular}
\end{center}

\vspace{0.6em}
\noindent{\Large\bfseries CRITERIOS DE ACEPTACIÓN}
\begin{center}
\begin{CajaCriterios}
\begin{itemize}[leftmargin=1.4em, itemsep=3pt, topsep=0.2em]
\HUCriterios
\end{itemize}
\end{CajaCriterios}
\end{center}

\end{document}
EOF

# ============================================================
# 6. FICHAS SPRINT 1
# ============================================================
cat > "$DOCS/Fichas/sprint1/hu01.tex" << 'EOF'
\def\HUNro{01}\def\HUTitulo{Auth > Registro > Registrar cliente}
\def\HUModulo{M1-Auth}\def\HUReq{RF-01}\def\HUPuntos{3}
\def\HUComo{persona que desea solicitar servicios de mecánico}
\def\HUQuiero{registrarme con mis datos personales}
\def\HUPara{solicitar servicios, aprobar presupuestos y calificar}
\def\HUMockupArchivo{sprint1/mockups/hu01}
\def\HUCriterios{%
\item Formulario: tipo de identificación, número, nombre, apellido, email, teléfono, contraseña.
\item La contraseña se almacena con hash (bcrypt).
\item El email debe ser único; si existe, error.
\item Se crea en tablas \texttt{persona} + \texttt{usuario} con rol CLIENTE.
\item Tras registro exitoso, redirige al login.
}
\input{../cuerpo}
EOF

cat > "$DOCS/Fichas/sprint1/hu02.tex" << 'EOF'
\def\HUNro{02}\def\HUTitulo{Auth > Login > Iniciar sesión}
\def\HUModulo{M1-Auth}\def\HUReq{RF-02}\def\HUPuntos{3}
\def\HUComo{usuario registrado}
\def\HUQuiero{ingresar mi usuario y contraseña}
\def\HUPara{acceder a las funciones según mi rol}
\def\HUMockupArchivo{sprint1/mockups/hu02}
\def\HUCriterios{%
\item Campos: username y password.
\item Cinco intentos fallidos bloquean la cuenta 15 minutos.
\item La sesión dura 120 minutos sin actividad.
\item Se registra el acceso en bitácora.
}
\input{../cuerpo}
EOF

# ============================================================
# 7. FICHAS SPRINT 2
# ============================================================
cat > "$DOCS/Fichas/sprint2/hu03.tex" << 'EOF'
\def\HUNro{03}\def\HUTitulo{Taller > Vehículos > Registrar vehículo}
\def\HUModulo{M2-Taller}\def\HUReq{RF-03}\def\HUPuntos{5}
\def\HUComo{recepcionista del taller}
\def\HUQuiero{registrar un vehículo con placa, marca, modelo y kilometraje}
\def\HUPara{asociarlo al cliente y crear órdenes de trabajo}
\def\HUMockupArchivo{sprint2/mockups/hu03}
\def\HUCriterios{%
\item Campos: placa, marca, modelo, año, color, kilometraje.
\item La placa es única.
\item Se crea en tabla \texttt{vehiculo} asociado a \texttt{cliente}.
}
\input{../cuerpo}
EOF

cat > "$DOCS/Fichas/sprint2/hu04.tex" << 'EOF'
\def\HUNro{04}\def\HUTitulo{Taller > Órdenes > Crear orden de trabajo}
\def\HUModulo{M2-Taller}\def\HUReq{RF-04}\def\HUPuntos{8}
\def\HUComo{recepcionista}
\def\HUQuiero{crear una orden de trabajo con recepción de vehículo}
\def\HUPara{registrar el ingreso, kilometraje, gasolina y observaciones}
\def\HUMockupArchivo{sprint2/mockups/hu04}
\def\HUCriterios{%
\item Campos: vehículo, recepcionista, kilometraje ingreso, nivel gasolina, observación.
\item Estado inicial: REC (Recibido).
\item Se crea en tabla \texttt{orden\_trabajo}.
\item Si hay mecánico asignado, se notifica.
}
\input{../cuerpo}
EOF

# ============================================================
# 8. FICHAS SPRINT 3
# ============================================================
cat > "$DOCS/Fichas/sprint3/hu05.tex" << 'EOF'
\def\HUNro{05}\def\HUTitulo{Presupuesto > Crear y enviar presupuesto}
\def\HUModulo{M3-Presupuesto}\def\HUReq{RF-05}\def\HUPuntos{8}
\def\HUComo{mecánico}
\def\HUQuiero{crear un presupuesto con repuestos y servicios}
\def\HUPara{que el cliente lo apruebe o rechace antes de reparar}
\def\HUMockupArchivo{sprint3/mockups/hu05}
\def\HUCriterios{%
\item El presupuesto se asocia a una orden de trabajo.
\item Detalle: servicio o repuesto, cantidad, precio unitario.
\item Estado inicial: BOR (Borrador).
\item Al enviar, pasa a ENV (Enviado al Cliente).
\item Se envía notificación WhatsApp con plantilla.
}
\input{../cuerpo}
EOF

cat > "$DOCS/Fichas/sprint3/hu06.tex" << 'EOF'
\def\HUNro{06}\def\HUTitulo{Presupuesto > Aprobar o rechazar}
\def\HUModulo{M3-Presupuesto}\def\HUReq{RF-06}\def\HUPuntos{5}
\def\HUComo{cliente}
\def\HUQuiero{aprobar o rechazar un presupuesto}
\def\HUPara{autorizar la reparación de mi vehículo}
\def\HUMockupArchivo{sprint3/mockups/hu06}
\def\HUCriterios{%
\item El cliente ve el detalle del presupuesto.
\item Botones: Aprobar / Rechazar.
\item Al aprobar, estado APR y orden pasa a REP (En Reparación).
\item Al rechazar, estado REC y orden pasa a ANU (Anulado).
}
\input{../cuerpo}
EOF

# ============================================================
# 9. FICHAS SPRINT 4
# ============================================================
cat > "$DOCS/Fichas/sprint4/hu07.tex" << 'EOF'
\def\HUNro{07}\def\HUTitulo{Agenda > Agendar cita}
\def\HUModulo{M4-Agenda}\def\HUReq{RF-07}\def\HUPuntos{5}
\def\HUComo{recepcionista}
\def\HUQuiero{agendar una cita para un vehículo}
\def\HUPara{organizar la capacidad del taller}
\def\HUMockupArchivo{sprint4/mockups/hu07}
\def\HUCriterios{%
\item Campos: vehículo, fecha inicio, fecha fin, motivo.
\item No puede haber solapamiento de citas del mismo mecánico.
\item Se crea en tabla \texttt{cita} con estado PRO.
\item Se envía recordatorio al cliente.
}
\input{../cuerpo}
EOF

cat > "$DOCS/Fichas/sprint4/hu08.tex" << 'EOF'
\def\HUNro{08}\def\HUTitulo{Inventario > Gestionar repuestos}
\def\HUModulo{M5-Inventario}\def\HUReq{RF-08}\def\HUPuntos{8}
\def\HUComo{recepcionista}
\def\HUQuiero{gestionar el inventario de repuestos}
\def\HUPara{controlar stock y generar movimientos}
\def\HUMockupArchivo{sprint4/mockups/hu08}
\def\HUCriterios{%
\item CRUD de repuestos: código, nombre, stock, precios.
\item Movimientos: ENTRADA, SALIDA, AJUSTE.
\item Se registra en \texttt{movimiento\_stock} con stock anterior y nuevo.
\item Alerta cuando stock < stock\_minimo.
}
\input{../cuerpo}
EOF

# ============================================================
# 10. FICHAS SPRINT 5
# ============================================================
cat > "$DOCS/Fichas/sprint5/hu09.tex" << 'EOF'
\def\HUNro{09}\def\HUTitulo{Pagos > Generar QR y confirmar pago}
\def\HUModulo{M6-Pagos}\def\HUReq{RF-09}\def\HUPuntos{8}
\def\HUComo{recepcionista}
\def\HUQuiero{generar un código QR para que el cliente pague}
\def\HUPara{cobrar el servicio y emitir factura}
\def\HUMockupArchivo{sprint5/mockups/hu09}
\def\HUCriterios{%
\item El pago se asocia a una orden de trabajo.
\item Se genera código QR con monto y referencia.
\item Al confirmar, estado CON (Confirmado).
\item Se puede emitir factura (opcional).
}
\input{../cuerpo}
EOF

cat > "$DOCS/Fichas/sprint5/hu10.tex" << 'EOF'
\def\HUNro{10}\def\HUTitulo{BI > Dashboard de KPIs}
\def\HUModulo{M7-BI}\def\HUReq{RF-10}\def\HUPuntos{5}
\def\HUComo{administrador}
\def\HUQuiero{ver un dashboard con KPIs del taller}
\def\HUPara{tomar decisiones sobre ventas, mecánicos y presupuestos}
\def\HUMockupArchivo{sprint5/mockups/hu10}
\def\HUCriterios{%
\item KPIs: ventas diarias, rendimiento por mecánico, tasa de aprobación.
\item Se usan las vistas SQL: \texttt{v\_kpi\_venta\_diaria}, \texttt{v\_kpi\_mecanico}, \texttt{v\_kpi\_presupuesto}.
\item Gráficos de líneas y barras.
}
\input{../cuerpo}
EOF

# ============================================================
# 11. BITACORAS SEMANALES (5 ejemplos)
# ============================================================
for i in 1 2 3 4 5; do
  cat > "$DOCS/Bitacoras/semana0$i.tex" << EOF
\def\SemanaNro{$i}
\def\SprintNro{$((i))}
\def\FechaIni{Semana $i — fecha inicio}
\def\FechaFin{Semana $i — fecha fin}
\def\BitAvanceTexto{Avance de la semana $i del proyecto Albert/Tuulapp. Se trabajó en las historias planificadas para el sprint $i.}
\def\BitActividades{1 & Actividad ejemplo semana $i & Equipo & Cerrado \\\\ \\hline}
\def\BitAcuerdosTexto{Acuerdos alcanzados en la semana $i.}
\def\BitDificultadesTexto{Dificultades encontradas en la semana $i.}
\def\BitPendientes{1 & Tarea pendiente semana $i & Equipo & Próxima semana \\\\ \\hline}
\def\BitAportes{Quispe Ramírez, Alberto & Desarrollo backend y documentación & Arquitecto & Alta \\\\ \\hline}
\def\BitEvalOrganizacion{Alta}
\def\BitEvalComunicacion{Alta}
\def\BitEvalCumplimiento{Alta}
\def\BitEvalCompromiso{Alta}
\def\BitReflexionTexto{Reflexión de la semana $i del equipo.}
\input{cuerpo}
EOF
done

# ============================================================
# 12. MAKEFILE
# ============================================================
cat > "$DOCS/Makefile" << 'EOF'
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
EOF

chmod +x "$DOCS/Makefile"

echo ""
echo "✅ Estructura creada en $DOCS"
echo ""
echo "📁 Contenido:"
find "$DOCS" -type f | sed "s|$DOCS/||" | sort
echo ""
echo "📝 Próximos pasos:"
echo "  1. Agrega tu logo en: $DOCS/Propuesta/logo-horizontal.png"
echo "  2. Compila con:        cd $DOCS && make all"
echo "  3. O individual:       cd $DOCS/Arquitectura && pdflatex arquitectura.tex"
EOF
