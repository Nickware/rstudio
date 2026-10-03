# Agente mantenedor del repositorio

Esta guía explica cómo crear en Visual Studio Code un agente personalizado de GitHub Copilot para ayudar a mantener este repositorio. El agente podrá revisar documentación y código de varios proyectos, detectar tareas repetibles y proponer mejoras sin asumir que las carpetas comparten arquitectura.

La configuración se guarda en `.github/` y se versiona con el repositorio. El primer modo será de solo lectura; los permisos para editar o ejecutar comandos se habilitan después de validar su comportamiento.

## Alcance inicial

El agente ayudará a:

- revisar si cada README describe el código actual;
- identificar dependencias, validaciones o pruebas que faltan;
- sugerir tareas de mantenimiento específicas por proyecto;
- redactar un plan con archivos afectados y comprobaciones recomendadas.

No debe instalar paquetes, ejecutar scrapers, publicar aplicaciones ni modificar el sistema operativo. Tampoco debe afirmar que una hipótesis científica está comprobada o que resultados históricos de Baloto predicen sorteos futuros.

## Requisitos

- Visual Studio Code actualizado.
- GitHub Copilot Chat habilitado en VS Code y acceso a la vista **Chat** en modo agente.
- Este repositorio abierto como carpeta raíz en VS Code, para que el agente encuentre `.github/` y todos los proyectos.

Los nombres y disponibilidad de modelos pueden variar según la versión de VS Code y la cuenta. La guía utiliza las capacidades de agentes personalizados (`.agent.md`) e instrucciones de archivos (`.instructions.md`) de VS Code.

## Paso 1: Crear el agente en modo de solo lectura

1. En VS Code, abre la raíz del repositorio.
2. En **Explorer**, crea la carpeta `.github/agents/` si todavía no existe.
3. Dentro, crea `repo-maintainer.agent.md`.
4. Añade esta plantilla:

```markdown
---
name: Repo Maintainer
description: "Audita y propone mejoras de documentación, calidad de datos y mantenibilidad en los proyectos de este repositorio."
tools: [read, search]
user-invocable: true
---

Eres el agente mantenedor de este repositorio. Sus proyectos son independientes y usan formatos, tecnologías y niveles de madurez distintos.

## Método

1. Identifica el proyecto y la tarea solicitada.
2. Lee su README y el código que controla directamente el comportamiento.
3. Separa hechos observados, hipótesis y propuestas.
4. Resume hallazgos con rutas concretas, riesgos y una comprobación que podría refutarlos.
5. En esta configuración inicial, no edites archivos ni ejecutes comandos. Entrega un plan de cambio para aprobación.

## Contexto por proyecto

- `project-biomechanics`: aplicación R/Shiny para ingesta y normalización de CSV Garmin; análisis longitudinal y modelo de oscilador son trabajo futuro.
- `project-runner`: dashboard R/Shiny que procesa exportaciones FIT y CSV; considera la cobertura limitada del parser FIT y la privacidad de coordenadas GPS.
- `project-test`: analizador descriptivo de Baloto; la fuente web puede cambiar y los resultados históricos no permiten predecir sorteos.
- `project-python`: espacio sin implementación; las ideas documentadas todavía no son funciones disponibles.
- `rstudio-install`: scripts que instalan software y modifican el sistema; nunca los ejecutes ni instales dependencias por iniciativa propia.

## Límites

- No generalices patrones de un proyecto a los demás sin verificar el código.
- No accedas, compartas ni incluyas datos personales o archivos Garmin reales en ejemplos.
- No ejecutes instalaciones, scraping, despliegues ni operaciones destructivas.
- No cambies código o documentación hasta que la persona lo solicite explícitamente.
```

5. Guarda el archivo. La extensión `.agent.md` y los campos YAML iniciales permiten que VS Code lo muestre como agente personalizado.

## Paso 2: Añadir instrucciones selectivas

Las instrucciones de repositorio aportan contexto según los archivos en los que se trabaja. No sustituyen las reglas del agente: complementan las convenciones comunes.

1. Crea `.github/instructions/`.
2. Crea `project-boundaries.instructions.md` con este contenido:

```markdown
---
name: Project Boundaries
description: "Convenciones para tareas en los proyectos R/Shiny, Python y scripts de instalación de este repositorio."
applyTo: "project-biomechanics/**, project-runner/**, project-test/**, project-python/**, rstudio-install/**"
---

- Trata cada carpeta como un proyecto independiente, salvo que el código demuestre una integración.
- Consulta el README local y la implementación antes de documentar una función.
- Mantén explícita la diferencia entre comportamiento implementado y perspectivas.
- Para R/Shiny, prefiere los paquetes y patrones ya usados en ese proyecto.
- Protege datos de actividad y coordenadas GPS; usa ejemplos anonimizados.
- No ejecutes instaladores, scrapers o despliegues sin autorización expresa.
- Documenta unidades, fechas, valores faltantes y procedencia cuando afectes flujos de datos.
- En Baloto, presenta estadísticas como descriptivas o como pruebas de hipótesis; no como predicciones para apostar.
```

3. Guarda el archivo. El patrón `applyTo` limita estas reglas a los proyectos listados y evita cargarlas en tareas ajenas al repositorio.

## Paso 3: Comprobar que VS Code lo reconoce

1. Abre **Chat** y el selector de agente.
2. Selecciona **Repo Maintainer**. Si no aparece, confirma que abriste la raíz del repositorio, que el archivo termina exactamente en `.agent.md` y que el bloque YAML está entre líneas `---`.
3. Pídele una auditoría sin cambios, por ejemplo:

   > Revisa `project-runner`: compara su README con la carga de archivos y las vistas del código. Devuelve discrepancias, riesgos y una prueba sugerida. No edites ni ejecutes nada.

4. Comprueba que responda con rutas y observaciones concretas, que distinga lo implementado de lo pendiente y que no intente modificar archivos.
5. Prueba también una tarea de Baloto y otra de instalación para comprobar que mantiene sus límites científicos y de seguridad.

## Paso 4: Habilitar cambios revisables

Hazlo solo después de que el modo de solo lectura produzca revisiones útiles.

1. Abre `.github/agents/repo-maintainer.agent.md` y cambia `tools: [read, search]` por `tools: [read, search, edit]` para permitir ediciones sin acceso al terminal.
2. Conserva la regla de pedir autorización antes de cambiar archivos. Revisa el diff de cada tarea antes de aceptar el resultado.
3. Si más adelante se habilita `execute`, exige que el agente proponga primero el comando y explique su alcance. Permite solo verificaciones acotadas, como `git diff --check` o pruebas locales conocidas.
4. No uses este agente para ejecutar `install-rstudio*.sh`, instalar paquetes, acceder a servicios externos o reemplazar datos reales sin aprobación explícita.

Algunos controles pueden depender de la versión de VS Code, de políticas de la organización y de la configuración de herramientas. La lista `tools` reduce las capacidades declaradas, pero no reemplaza la revisión humana de cambios y comandos.

## Paso 5: Evaluar y mejorar

Prueba el agente con una lista corta de tareas reproducibles:

- detectar en un README una función mencionada que no esté conectada en el código;
- resumir los formatos de entrada de Running Dashboard sin inventar columnas;
- proponer pruebas para el scraping de Baloto sin ejecutarlo;
- explicar por qué `project-python` no tiene todavía un comando de ejecución;
- revisar un script de instalación sin ejecutarlo ni afirmar que es seguro.

Registra si el agente identifica correctamente el proyecto, cita evidencia, evita acciones no autorizadas y propone validaciones útiles. Ajusta sus instrucciones solo cuando una prueba muestre una ambigüedad o un fallo repetible. Mantén cada agente enfocado: si una tarea necesita permisos o criterios distintos, considera separar roles en vez de convertirlo en un agente universal.

## Estructura que se espera crear

```text
.github/
├── agents/
│   └── repo-maintainer.agent.md
└── instructions/
    └── project-boundaries.instructions.md
```

Estos archivos de configuración se crearán siguiendo los pasos anteriores; esta guía por sí sola no crea ni activa el agente.