# MAK: Compilación modular con Makefiles

## Introducción

En el laboratorio anterior se compiló un programa modular paso a paso. Esa experiencia permite ver con claridad el costo de repetir comandos, compilar cada `.c`, enlazar los `.o`, limpiar archivos temporales y recordar qué módulos deben reconstruirse después de cada cambio.

Este laboratorio introduce `make` como herramienta para automatizar ese flujo. Las reglas y los comandos de compilación se escriben en un archivo llamado `Makefile`. Este archivo no reemplaza el conocimiento de compilación modular, sino que permite aplicar ese conocimiento para automatizar el proceso.

### Prerrequisitos

- Tener disponible el entorno Linux del laboratorio y haber clonado este repositorio
- Tener disponibles `gcc`, GNU Make, `diff`, Bash, Vim y las herramientas habituales de terminal
- Haber completado el laboratorio anterior sobre compilación modular manual
- Entender el flujo `.c -> .o -> ejecutable`
- Entender la diferencia entre `stdout` y `stderr`
- Saber editar archivos con Vim y ejecutar una suite de test cases

### Objetivo general

- Automatizar la compilación y verificación de programas modulares en C mediante Makefiles

### Objetivos específicos

- Leer un Makefile existente e identificar reglas, prerrequisitos y recetas
- Usar variables como `CC`, `CFLAGS`, `CPPFLAGS`, `TARGET`, `OBJS` y `DEPS`
- Construir ejecutables a partir de múltiples archivos objeto
- Utilizar una regla patrón para compartir la receta de compilación entre distintos archivos fuente
- Usar variables automáticas como `$@`, `$<` y `$^`
- Completar variables, una regla patrón y las recetas de enlace y limpieza de un Makefile entregado
- Utilizar los targets `all`, `clean` y `test`
- Reconocer el uso de `.PHONY` para los targets que representan acciones y no archivos
- Evitar recompilaciones innecesarias
- Utilizar dependencias automáticas para que los cambios en cabeceras recompilen lo necesario
- Validar el ejecutable final con una suite de pruebas

### Estructura inicial

```text
workspace/
├── code/
│   ├── case001/     Compilación modular sin seguimiento de cabeceras
│   ├── case002/     Ejemplo con dependencias automáticas de cabeceras
│   └── case003/     Programa modular con Makefile para completar
├── tests/
│   ├── test001.in
│   ├── test001.expected
│   ├── ...
│   ├── test004.in
│   └── test004.expected
└── scripts/
    ├── tests-run.sh
    └── check.sh
```

Los programas C están completos y funcionan correctamente; no es necesario modificarlos. Los dos primeros casos incluyen Makefiles completos para ejecutar y analizar. En `case003` se entrega un Makefile para completar algunas variables, la regla patrón de compilación y las recetas de enlace y limpieza; luego se utilizan los cuatro test cases entregados para verificar el programa.

`tests-run.sh` ejecuta las pruebas y compara sus salidas. `check.sh` permite revisar qué actividades se han completado y cuáles permanecen pendientes.

## Contexto

La Alianza Rebelde está reorganizando su sistema de despacho de evacuaciones. Las bases envían solicitudes para trasladar a su personal y el equipo de coordinación debe comprobar si las naves disponibles tienen capacidad suficiente para realizar cada evacuación.

Para esta gestión, un programa recibe solicitudes de evacuación. Cada solicitud indica una base, la cantidad de personas a evacuar, la cantidad de naves disponibles, la capacidad de cada nave y una prioridad numérica. El sistema calcula si la capacidad alcanza y clasifica la prioridad como `NORMAL`, `ALTA` o `CRITICA`.

La entrada comienza con la cantidad de solicitudes. Cada línea siguiente contiene los cinco datos de una solicitud, en el orden indicado y separados por espacios. La capacidad total corresponde a la cantidad de naves multiplicada por la capacidad de cada una. Se informa `OK` cuando alcanza para todas las personas y `ALERTA` cuando es insuficiente.

La prioridad es `NORMAL` para valores menores que 60, `ALTA` desde 60 hasta 89 y `CRITICA` desde 90. En el campo `capacidad` del informe se muestran primero los cupos disponibles y luego la cantidad de personas que requieren evacuación.

## Actividad

### 1. Compilar y enlazar con un Makefile básico

#### 1.1. Preparar y ejecutar

Desde la raíz del repositorio, entrar a `workspace/code/case001` y revisar los archivos entregados:

- `main.c` llama a la función `sumar` con los valores 5 y 7, e imprime el resultado
- `suma.c` implementa la función `sumar`
- `suma.h` declara la función para que pueda utilizarse desde `main.c`
- `Makefile` contiene las reglas para compilar los dos archivos fuente por separado y enlazar sus objetos

Los valores están definidos en el código; el programa no solicita datos al usuario. Para compilar, ejecutar:

```bash
make
```

Observar los comandos que aparecen en la terminal. Primero se generan `main.o` y `suma.o` mediante dos compilaciones separadas. Luego se enlazan ambos objetos para generar el ejecutable `suma`.

Ejecutar el programa desde el directorio actual. La salida debe ser:

```text
Suma: 12
```

#### 1.2. Leer las reglas y las variables

Abrir el Makefile con las herramientas conocidas. Una regla tiene la siguiente estructura:

```text
<TARGET>: <DEPENDENCIAS>
	<RECETA>
```

El target es el archivo que se quiere generar o la acción que se quiere realizar. Sus dependencias, también llamadas prerrequisitos, indican qué archivos o targets necesita. La receta contiene los comandos asociados a la regla; cada línea comienza con una tabulación.

Identificar las variables del archivo:

- `CC` contiene el nombre del compilador
- `CPPFLAGS` contiene opciones del preprocesador; en este ejemplo está vacía
- `CFLAGS` contiene las opciones de compilación de C
- `TARGET` contiene el nombre del ejecutable
- `OBJS` contiene los nombres de los dos archivos objeto

La forma `$(NOMBRE)` se reemplaza por el valor de la variable indicada. Por ejemplo, `$(TARGET)` se reemplaza por `suma`.

Revisar las tres reglas que generan archivos:

- `main.o: main.c` indica explícitamente cómo generar `main.o` a partir de `main.c`
- `%.o: %.c` permite generar los demás objetos a partir del archivo fuente con el mismo nombre base; en este caso se utiliza para `suma.o`
- `$(TARGET)` depende de `$(OBJS)`; su receta enlaza los dos objetos

El símbolo `%` representa el nombre base compartido por el objeto y su archivo fuente. Esta **regla patrón** permite generar `suma.o` desde `suma.c`, sin escribir una regla específica para ese archivo.

La regla patrón también podría generar `main.o`. Su regla explícita se conserva para comparar ambas formas: al existir una receta específica para `main.o`, `make` utiliza esa receta. Si se retirara esa regla completa, la regla patrón permitiría compilarlo de la misma manera.

En las recetas se utilizan además variables automáticas, cuyo valor corresponde a la regla que se está ejecutando:

- `$@` representa el target; por ejemplo, `main.o` en su regla de compilación
- `$<` representa la primera dependencia; en esa misma regla corresponde a `main.c`
- `$^` representa todas las dependencias, sin repetir nombres; en la regla de enlace reúne `main.o` y `suma.o`

Las recetas de los objetos usan `-c` para compilar sin enlazar. La receta del ejecutable reúne los objetos y no utiliza esa opción. Relacionar estos comandos con la compilación modular realizada en CMO.

Al ejecutar `make` sin indicar un target, se utiliza la primera regla, `all`, que depende del ejecutable. Para indicar otro target se usa la forma `make <TARGET>`. La declaración `.PHONY: all clean` indica que esos dos targets representan acciones y no archivos.

#### 1.3. Observar las dependencias y la limpieza

Ejecutar nuevamente `make`. Como los archivos no cambiaron, no debería repetirse la compilación ni el enlace.

El comando `touch` actualiza la fecha de modificación de un archivo existente sin cambiar su contenido. Utilizarlo para simular una edición:

```bash
touch suma.c
```

Volver a ejecutar `make`. Debe recompilarse solamente `suma.c` y luego volver a enlazarse el ejecutable. `main.o` se conserva porque sus dependencias no cambiaron.

En este ejemplo, el Makefile solo considera los archivos `.c` como dependencias de los objetos. Aunque los fuentes incluyen `suma.h`, un cambio en esa cabecera no provoca una recompilación automática.

Para eliminar los archivos generados, ejecutar:

```bash
make clean
```

Comprobar que se eliminaron el ejecutable y los dos objetos, pero se conservaron los archivos fuente, la cabecera y el Makefile. Volver a compilar y ejecutar el programa.

### 2. Incorporar dependencias automáticas de cabeceras

#### 2.1. Preparar y ejecutar

Desde `workspace`, entrar a `code/case002` y listar su contenido. Deberían aparecer los archivos fuente, cabeceras y un `Makefile`.

El programa utiliza el nombre `hoth-relay`, definido en el código, para calcular dos valores de ejemplo: `checksum`, obtenido a partir de los caracteres del nombre, y `strength`, calculado a partir del anterior. No solicita datos al usuario.

Ejecutar:

```bash
make
```

Esto debe generar el ejecutable `relay_example`. Ejecutarlo desde el directorio actual.

La salida esperada tiene esta forma:

```text
Relay hoth-relay: checksum=51 strength=119
```

Ejecutar `make` una segunda vez.

Ahora `make` debería indicar que no hay nada que reconstruir, porque los archivos fuente no cambiaron desde la última compilación.

Comparar este proceso con la compilación manual del laboratorio anterior e identificar qué tareas permite automatizar `make`.

#### 2.2. Leer el Makefile

Abrir el Makefile y compararlo con el del primer caso. Este ejemplo mantiene la regla patrón e incorpora la generación automática de dependencias de las cabeceras, para que sus cambios también provoquen la recompilación de los archivos fuente que las utilizan.

Identificar los elementos que se agregaron para registrar esas dependencias:

- `DEPFLAGS`: flags para generar dependencias automáticas
- `DEPS`: archivos `.d` generados para dependencias de cabeceras
- `-include $(DEPS)`: inclusión de dependencias automáticas

En este Makefile, `DEPFLAGS` está definido así:

```makefile
DEPFLAGS = -MMD -MP
```

Estos flags no cambian el ejecutable generado. Su objetivo es pedirle a `gcc` que, además de compilar cada `.c` a `.o`, genere un archivo `.d` con las dependencias detectadas durante la compilación.

Por ejemplo, al compilar `main.c`, se genera `main.o` y también `main.d`. Ese archivo `.d` contiene una regla auxiliar que le indica a `make` que `main.o` depende de `main.c` y de las cabeceras incluidas por ese archivo. Así, si cambia una cabecera como `decoder.h`, `make` puede saber qué objetos debe recompilar.

En particular:

- `-MMD`: genera un archivo `.d` con las dependencias del archivo fuente, considerando las cabeceras del proyecto
- `-MP`: agrega reglas auxiliares para evitar que una referencia antigua en un `.d` detenga a `make` si una cabecera deja de utilizarse y se elimina

La expresión `$(OBJS:.o=.d)` obtiene la lista de archivos `.d` reemplazando la terminación `.o` de cada nombre en `OBJS`. La línea `-include $(DEPS)` le dice a `make` que lea esos archivos `.d` si existen. El guion inicial evita que `make` falle la primera vez, cuando todavía no se han generado.

La receta de compilación mantiene las variables automáticas revisadas en el primer caso y agrega `$(DEPFLAGS)`:

```makefile
$(CC) $(CPPFLAGS) $(CFLAGS) $(DEPFLAGS) -c -o $@ $<
```

Compararla con la receta de `case001` e identificar cómo se generan ahora los archivos `.d` junto con los objetos. Revisar también que `clean` incorpora `$(DEPS)` para eliminar esos archivos durante la limpieza.

#### 2.3. Observar recompilación incremental

Eliminar los archivos generados mediante el target `clean` y volver a compilar el programa. Luego utilizar `touch`, como en el primer caso, para actualizar la fecha de `decoder.c` sin modificar su contenido.

Volver a ejecutar `make` y observar qué objeto se recompila y cómo se vuelve a enlazar el ejecutable. Luego repetir el procedimiento con la cabecera `decoder.h` y comparar qué objetos se actualizan en cada caso.

La recompilación de archivos que dependen de esa cabecera ocurre porque el Makefile usa `-MMD -MP` y luego incluye los archivos `.d`. Sin dependencias automáticas, `make` solo conocería las dependencias escritas explícitamente en el Makefile.

Relacionar lo observado con las dependencias registradas: explicar por qué un cambio en un `.h` puede requerir recompilar varios `.o` y qué ventaja tiene generar esa información con `-MMD -MP` en lugar de escribirla manualmente.

#### 2.4. Cambiar flags de compilación

Hay una situación importante: `make` decide si debe recompilar comparando fechas entre targets y prerrequisitos. Si se cambia solo una variable del Makefile, por ejemplo una flag de compilación, los archivos `.c` y `.h` no cambian de fecha. Por eso puede ocurrir que `make` diga que no hay nada que hacer, aunque conceptualmente sí se quiera reconstruir el programa con flags distintas.

Para observarlo, editar el Makefile y agregar `-DRELAY_OFFSET=100` al valor de `CFLAGS`, conservando las opciones existentes. La opción `-D` define una macro desde el comando de compilación. En este ejemplo, cambia de 17 a 100 la constante que se agrega al calcular `strength`.

Luego ejecutar `make` y volver a ejecutar `relay_example`.

Es probable que `make` indique que no hay nada que hacer, porque los objetos existentes siguen siendo más nuevos que sus fuentes. En ese caso, la salida del programa seguirá usando el valor anterior.

Ahora eliminar los archivos generados mediante el target `clean`, volver a compilar y ejecutar nuevamente el programa.

Después de reconstruir, la salida debería reflejar la nueva flag y mostrar:

```text
Relay hoth-relay: checksum=51 strength=202
```

Este comportamiento es una fuente común de errores: si se cambian flags de compilación, conviene ejecutar `make clean` antes de volver a construir, salvo que el Makefile haya sido diseñado explícitamente para hacer que los objetos dependan también de la configuración de compilación.

Antes de continuar, retirar la definición agregada a `CFLAGS` para restaurar su valor original. Repetir la limpieza, la compilación y la ejecución para comprobar que la salida vuelva a mostrar `strength=119`.

Volver al directorio `workspace` antes de continuar con el siguiente caso.

### 3. Completar un Makefile y ejecutar las pruebas

#### 3.1. Revisar el Makefile incompleto

Desde `workspace`, entrar a `code/case003` y revisar los archivos, incluyendo el Makefile.

Este Makefile contiene una estructura inicial, pero faltan los valores de algunas variables, la regla patrón de compilación y las recetas de enlace y limpieza. Debe completarse antes de utilizarlo para compilar y ejecutar las pruebas.

Los comentarios marcados con `TODO` señalan las partes por completar. En las variables, agregar el valor correspondiente; en las reglas, reemplazar los comentarios por el encabezado o la receta que se solicita.

Usar como referencia el Makefile de `case002`. Antes de editar, revisar los archivos fuente de `case003` e identificar qué objetos necesita el programa. Conservar las partes que ya están completas, como los targets `all` y `test`, la inclusión de dependencias y la declaración `.PHONY`.

#### 3.2. Completar variables y reglas

Completar primero las variables marcadas con `TODO`, reemplazando cada comentario por el valor correspondiente:

- `CC`: utilizar `gcc` como compilador
- `CFLAGS`: utilizar las mismas opciones de compilación del Makefile de `case002`
- `DEPFLAGS`: indicar las opciones que permiten generar las dependencias automáticas de cabeceras, como en `case002`
- `OBJS`: incluir los archivos objeto correspondientes a todos los archivos `.c` de este caso

Mantener los valores entregados para `TARGET` y `DEPS`. La variable `CPPFLAGS` permanece vacía, ya que este caso no requiere opciones adicionales del preprocesador.

Completar la receta de la regla que construye `$(TARGET)` a partir de `$(OBJS)`. Esa receta debe invocar al compilador para enlazar todos los objetos y producir el ejecutable final.

Luego escribir la regla patrón completa en el lugar indicado por el comentario. Incluir tanto el encabezado, que relaciona cada archivo objeto con el archivo fuente del mismo nombre base, como su receta. La receta debe compilar sin enlazar y generar las dependencias de cabeceras, utilizando las variables de flags y las variables automáticas revisadas en los ejemplos anteriores.

Completar también la receta de `clean`, usando las variables del Makefile para eliminar el ejecutable, los archivos objeto y los archivos de dependencias. La limpieza debe conservar los archivos fuente, las cabeceras, el Makefile y los archivos de pruebas.

Una vez completado el Makefile, utilizar `make` para compilar los archivos fuente y enlazar sus objetos. Comprobar que se genere el ejecutable `rebel_link`. Si aparece un error, leer el mensaje, revisar las variables y las reglas del Makefile y corregir lo necesario antes de repetir la compilación.

Con el ejecutable disponible y desde `code/case003`, ejecutar `rebel_link` usando `../../tests/test001.in` como entrada mediante la redirección `<`. Guardar la salida en `../../tests/test001.out` y compararla con `../../tests/test001.expected` mediante `diff`.

Si hay diferencias, revisar los archivos utilizados, el comando de ejecución y el Makefile antes de repetir la prueba.

#### 3.3. Ejecutar la suite de pruebas

Agregar permiso de ejecución para el propietario a `../../scripts/tests-run.sh`. El Makefile de `case003` ya contiene un target `test`, pero solo podrá ejecutar la suite si se construye correctamente el ejecutable.

Ejecutar ese target mediante `make`, utilizando la forma revisada en los ejemplos anteriores. Este target invoca el script de pruebas de la carpeta `scripts` sobre los cuatro casos de `tests`.

La suite debe informar cuatro `PASS`. Si aparece `FAIL`, comparar la salida con el archivo `.expected` y revisar el Makefile. Si aparece `ERRO`, revisar el archivo `.err` del caso, si existe, y comprobar que estén disponibles el ejecutable y el archivo `.expected`. Los programas C y los resultados esperados están entregados y no requieren correcciones.

Actualizar la fecha de `priority.h` mediante `touch` y volver a ejecutar el target `test`. Como depende del ejecutable, debe recompilar los objetos necesarios y volver a enlazar antes de ejecutar la suite.

#### 3.4. Verificar la limpieza y volver a compilar

Revisar la receta de `clean` y ejecutar ese target. Comprobar que elimina el ejecutable, los objetos y los archivos `.d`, pero conserva los archivos fuente, las cabeceras y el Makefile. Volver a ejecutar el target `test`: debe reconstruir el programa antes de ejecutar las cuatro pruebas.

Luego volver al directorio `workspace` para realizar la verificación final.

### 4. Verificación final

Desde `workspace`, agregar permiso de ejecución para el propietario a `scripts/check.sh`.

Ejecutar `scripts/check.sh`.

## Anexo: Tabulaciones al editar Makefiles con Vim

Un detalle importante de los Makefiles es que las recetas deben comenzar con una tabulación real. No basta con que visualmente parezca indentado. Si una línea de receta empieza con espacios, `make` no la reconoce como receta y normalmente falla con un mensaje como:

```text
Makefile:12: *** missing separator.  Stop.
```

Esto ocurre porque la sintaxis histórica de `make` usa la tabulación inicial para distinguir una receta de una variable o de una regla. Por ejemplo, en esta regla la segunda línea debe comenzar con un tab:

```makefile
$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^
```

En muchos editores se configuran los tabs para convertirse automáticamente en espacios. Esa configuración es útil en varios lenguajes, pero puede causar problemas en Makefiles. Al editar con `vim`, revisar primero la configuración del archivo:

```vim
:set expandtab?
:set tabstop?
```

En `vim`, los comandos que comienzan con `:` se escriben en modo normal. Es decir, si se está escribiendo texto, primero presionar `Esc`, luego escribir el comando y finalmente presionar `Enter`.

El comando `:set` permite consultar o modificar opciones del editor. Cuando una opción termina con `?`, Vim no la modifica, solo muestra su valor actual. Por eso:

- `:set expandtab?`: pregunta si está activa la opción `expandtab`
- `:set tabstop?`: pregunta cuántas columnas ocupa visualmente una tabulación

Por omisión, una tabulación suele mostrarse como 8 columnas. Si se quiere verla con otro ancho, por ejemplo 4 columnas, se puede usar:

```vim
:setlocal tabstop=4
```

Esto cambia cómo se ve la tabulación en Vim, no cambia la regla de Makefile: la receta sigue necesitando una tabulación real al inicio de la línea.

Si aparece `expandtab`, Vim está convirtiendo las tabulaciones en espacios. Para este archivo, desactivar esa conversión:

```vim
:setlocal noexpandtab
```

`setlocal` modifica una opción solo para el archivo o buffer actual. En este caso es preferible a `set`, porque no se busca cambiar la configuración global de Vim para todos los archivos, sino solo evitar que este Makefile convierta tabs en espacios.

Para ver claramente la diferencia entre tabs y espacios, activar la visualización de caracteres invisibles:

```vim
:set list
:set listchars=tab:>-,trail:.
```

La primera línea, `:set list`, le pide a Vim que muestre caracteres que normalmente son invisibles, como tabulaciones y espacios al final de una línea.

La segunda línea, `:set listchars=tab:>-,trail:.`, define cómo se deben dibujar esos caracteres invisibles:

- `tab:>-`: muestra cada tabulación usando `>` al inicio y `-` para completar el ancho visual del tab
- `trail:.`: muestra cada espacio sobrante al final de una línea usando `.`

Con esa configuración, una tabulación al inicio de una receta se verá como `>` seguido de los guiones necesarios para completar su ancho visual. Los espacios finales se verán como puntos, lo que ayuda a detectar espacios innecesarios al final de una línea.

Al escribir una receta en modo inserción, presionar `Tab` después de haber ejecutado `:setlocal noexpandtab`. Si Vim sigue insertando espacios por alguna configuración externa, se puede insertar una tabulación literal con:

```text
Ctrl-v Tab
```

Para corregir una receta con espacios al inicio, una forma simple es borrar la indentación de esa línea y volver a insertar una tabulación real. Luego usar `:set list` para confirmar que la línea empieza con una tabulación y no con espacios.
