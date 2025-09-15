
# Documentación del Proyecto


## 1. Introducción
El presente proyecto tiene como objetivo profundizar en la comprensión del **proceso de arranque de un Sistema Operativo** mediante el desarrollo de un programa escrito en **lenguaje ensamblador para x86**.  

El código Morse, también conocido como alfabeto Morse, es un sistema de representación de caracteres que utiliza secuencias de puntos "**·**" y rayas "**_**" para codificar letras, números y símbolos. Fue desarrollado en el siglo XIX por **Samuel Morse** y **Alfred Vail** como parte del telégrafo eléctrico, convirtiéndose en uno de los primeros sistemas de comunicación digital. Su simplicidad y eficacia lo han mantenido vigente incluso en la actualidad, siendo empleado en telecomunicaciones, aviación y situaciones de emergencia.  

En este contexto, la tarea consiste en **programar un booteo desde una memoria USB** utilizando el estándar **EFI (Extensible Firmware Interface)**, que cargue automáticamente un único programa denominado `Morse`. Este programa debe ser capaz de:  

1. **Recibir cadenas de caracteres ASCII** (Desde la A a la Z y 0 a 9 unicamente) desde la entrada del usuario.  
2. **Convertirlas a su representación en código Morse**, empleando tablas de correspondencia.  
3. **Generar sonidos a través del PC Speaker**, distinguiendo entre un sonido corto (punto) y un sonido largo (raya).  
4. **Repetir el proceso indefinidamente**, solicitando al usuario ingresar nuevas cadenas tras finalizar la transmisión.  

El propósito principal de este trabajo no solo es desarrollar un codificador funcional de Morse, sino también que el estudiante adquiera experiencia en aspectos fundamentales de bajo nivel, tales como:  

- La construcción de un sector de arranque capaz de inicializar un programa en ensamblador.  
- La interacción directa con el hardware del sistema (teclado, salida de texto, pcspeaker).  
- El diseño modular de rutinas en ensamblador que gestionen entrada, conversión y salida.  
- La disciplina de trabajar en un ambiente restringido, sin librerías de alto nivel, fortaleciendo el entendimiento de cómo opera un computador desde sus bases más primitivas.  

En resumen, este proyecto permite integrar **conocimientos teóricos y prácticos** sobre sistemas operativos, programación en ensamblador y control de hardware, mediante la implementación de un **codificador de Morse booteable desde USB**, constituyéndose como una experiencia clave en la formación del ingeniero en computación.

## 2. Ambiente de Desarrollo
El proyecto fue implementado utilizando las siguientes herramientas:
- **Lenguaje de Programación**: Ensamblador para x86  
- **Mecanismo de Booteo**: EFI  
- **Editor/IDE**: Visual Studio Code  
- **Sistema Operativo de Desarrollo**: Linux Ubuntu  
- **Compilador/Assembler**: NASM (Netwide Assembler)  
- **Control de Versiones**: Git + GitHub  
- **Medio de prueba**:: QEMU
- **Medio de Ejecución**: USB 32GB Kingstone
- **Otros**: Makefile



## 3. Estructuras de Datos Usadas y Funciones
El programa `morser.asm` fue desarrollado íntegramente en **Ensamblador x86_64** para correr de forma independiente (sin sistema operativo), utilizando las interfaces de entrada/salida provistas por **UEFI**.  

### 3.1 Estructuras de Datos
- **Buffers de entrada y salida**
  - `input_buffer`: Almacena los caracteres ASCII ingresados por el usuario.
  - `output_buffer`: Almacena la traducción de la cadena en formato Morse.
  - `character_buffer`: Utilizado para imprimir caracteres individuales en pantalla conforme son digitados.
  - `key_buffer`: Buffer temporal para la lectura de teclas desde la interfaz de entrada UEFI.

- **Tablas de conversión**
  - `LETTERS`: Tabla que apunta a las representaciones Morse de las letras **A–Z**.
  - `NUMBERS`: Tabla que apunta a las representaciones Morse de los números **0–9**.
  - `A, B, C, ... Z`: Definiciones de cada letra en formato Morse, usando `.` para punto y `_` para raya.
  - `ZERO ... NINE`: Definiciones de cada número en formato Morse.
  - `UNKNOWN`: Representación para caracteres que no son soportados para traducir (`?`).

- **Mensajes del programa**
  - `welcome_msg`: Mensaje inicial mostrado al usuario.
  - `prompt_msg`: Solicitud de texto a traducir.
  - `morse_msg`: Encabezado al mostrar el texto traducido.
  - `goodbye_msg`: Mensaje de despedida.
  - `delete_arrow`, `new_line`: Utilizados para gestionar la edición y formato de salida.

### 3.2 Funciones y Rutinas Principales
- **Rutinas de control**
  - `_start`: Punto de entrada del programa. Inicializa la pila, limpia la pantalla, muestra mensajes iniciales y gestiona el flujo principal.
  - `clear_input_buffer`: Limpia el buffer de entrada para permitir nuevas traducciones.
  - `add_space`: Añade separadores (` / `) entre palabras en el resultado Morse.

- **Rutinas de Entrada**
  - Lectura de teclas mediante `ReadKeyStroke` de UEFI, almacenando los caracteres en `input_buffer`.
  - Conversión automática de minúsculas a mayúsculas (aplicando la máscara `UPPER_MASK`).
  - Manejo de teclas especiales:
    - `ENTER`: Procesa el texto completo.
    - `BACKSPACE`: Permite borrar el último carácter ingresado.

- **Rutinas de Conversión**
  - Itera sobre `input_buffer` y busca la representación correspondiente en `LETTERS` o `NUMBERS`.
  - Si no encuentra coincidencia, usa el símbolo definido en `UNKNOWN`.

- **Rutinas de Salida**
  - Uso de `OutputString` de UEFI para imprimir cadenas Unicode.
  - Presentación en pantalla del mensaje en Morse junto con los separadores entre letras y palabras.

---

## 4. Instrucciones para Ejecutar el Programa
### 4.1 Compilación y Ejecución
El proyecto incluye un **Makefile** que automatiza la compilación del programa. Desde el directorio raíz, ejecutar:

 1. Pasos para ejecutar en QEMU

```bash
make all 
make execute
```
Cuando la ventana de QEMU esté abierta, seleccionela con el mouse y empiece a escribir
```bash
`Bienvenido  al  Convertidor  a  Morse  Sin  Sistema  Operativo!`
`Ingrese  el  Texto  a  Traducir:` SOS 
`Morsificado:` ... --- ...
```
2. Pasos para ejecutar en computador mediante USB
```bash
; Determinar cual es el USB:
lsblk
; En la lista se debe encontrar el elemento sd<x> que corresponda con la memoria USB deseada, en este caso la USB seria sdb.
make all TARGET=usb DISK_IMAGE=/dev/sdb
; Con esto la memoria USB quedaria preparada para bootear, en caso de fallar, basta con ejecutar el comando nuevamente.
```
Despúes, conecte la USB con el programa dentro al computador con el cual desee utilizar y al encenderlo, configure la BIOS del computador para que utilice la USB como dispositivo de arranque. Cuando lo tenga podrá escribir por ejemplo:
```bash
`Bienvenido  al  Convertidor  a  Morse  Sin  Sistema  Operativo!`
`Ingrese  el  Texto  a  Traducir:` SOS 
`Morsificado:` ... --- ...
```
3. Limpiar archivos generados
```bash
make clean
; Con este comando normalmente basta para limpiar todo lo generado y demsmontar el loopdevice, pero se recomienda verificar este ultimo con el comando.
losetup -a
; Si aparece un loopdevice todavia ocupando el programa, solo requiere hacer.
sudo losetup -d /dev/loop<n>
make clean
; <n> corresponde al número de loopdevice que se desea liberar.
```
### 4.2 Comportamiento del Programa:
El programa esta a la espera de que el usuario precione enter para convertir el buffer de entrada a Morse, en el momento que el buffer esté lleno, el usuario no podrá seguir ingresando ningún caracter.
El programa en el momento de imprimir lo ingresado por el usuario, no eliminará la información de lo último que ingreso, siendo que puede seguir escribiendo sobre la misma. Ejemplo:
```bash
`Bienvenido  al  Convertidor  a  Morse  Sin  Sistema  Operativo!`
`Ingrese  el  Texto  a  Traducir:` SO
`Morsificado:` ... ---
`Ingrese  el  Texto  a  Traducir:` S
`Morsificado:` ... --- ...
```
Además la instrucción de borrado es representada como un caracter desconocido **�** o una flecha apuntando hacía atras curveada **↩**, dependiendo de si se esta emulando en QEMU o ejecutando en un computador convencional, las eliminaciones de caracteres solo pueden hacerse hasta que el buffer de entrada quede vacio. Ejemplo de comportamiento:
```bash
`Bienvenido  al  Convertidor  a  Morse  Sin  Sistema  Operativo!`
`Ingrese  el  Texto  a  Traducir:` SOSS
`Morsificado:` ... --- ... ...
`Ingrese  el  Texto  a  Traducir:` ↩
`Morsificado:` ... --- ...
`Ingrese  el  Texto  a  Traducir:` ↩↩↩
`Ingrese  el  Texto  a  Traducir:`
```
## 5. Actividades Realizadas por Estudiante
|Fecha                |Actividad Realizada                         |Tiempo  Invertido                         |
|----------------|-------------------------------|-----------------------------|
|04/09/2025|`Lectura de las instrucciones de la tarea`            |10 mins            |
|04/09/2025          |`Instalación de QEMU y NASM`            |15 mins          |
|05/09/2025          |`Escritura y ejecución de un programa HelloWorld en QEMU con formato EFI`|10 h|
|08/09/2025          |`Desarrollo de un programa de entrada salida funcional en QEMU`|11 h 8 mins|
|12/09/2025          |`Desarrollo del componente de conversión funcional en QEMU`|3 h 20 mins|
|13/09/2025          |`Proceso de pruebas y reparaciones para funcionar en el booteo de una computadora`|8 h|
|14/09/2025          |`Correcciones finales para funcionalidad en el booteo de un computador`|2 h|
|15/09/2025          |`Escritura de la documentación.`|1 h 30 mins|

**Todal de Horas:** 36h 13 mins
## 6. Autoevaluación
- **Estado Final del Programa:** El programa logra ejecutarse en el booteo de una computadora y traduce caracteres ASCII (A,B,C,..Z - 0,1,2,...,9), pero no hace uso del pcspeak
- **Problemas Encontrados:** Fue una avalancha de problemas poder determinar que instrucciones estaban mal implementadas y como hacer uso de algunos componentes de NASM puesto que la información en linea es demasiado escasa o nula para algunas de las cosas que se buscaban realizar,
- **Limitaciones Adicionales:** El tiempo necesario para esta tarea fue demasiado grande, siendo que este seria el tiempo que uno invierte normalmente en proyectos de otros cursos.
- **Reporte de Git:**
```bash
git log
commit 4e61c2cda40e81ae59155d6666a17f375856434c (HEAD -> main, origin/main, origin/HEAD)
Author: IonDola <idolanescu@estudiantec.cr>
Date:   Sun Sep 14 23:33:01 2025 -0600

    ESTA VIVOOOOOO

commit bb08c0260ef75adb042dbc52cb4e7d95f1bf88a6
Author: IonDola <idolanescu@estudiantec.cr>
Date:   Sun Sep 14 14:46:59 2025 -0600

    Functional translations, fixing bugs

commit ae42f514d097d8d92c7f8c8e0f20e3683b638ce2
Author: IonDola <idolanescu@estudiantec.cr>
Date:   Sun Sep 14 11:31:35 2025 -0600

    Modificación de todo el codigo para trabajar en utf16

commit 78fcb9d1dc3777862f235fae1dd406ddc01e08e7
Author: IonDola <idolanescu@estudiantec.cr>
Date:   Sat Sep 13 19:37:02 2025 -0600

    Try number 3 on efi

commit f16f842f848adcf2b743a4c44e2548d7b37fdf73
Author: IonDola <idolanescu@estudiantec.cr>
Date:   Sat Sep 13 19:23:40 2025 -0600

    Modification to print correctly the characters

commit c052cd8baba008932cbde051b2d15c78b9a73cb9
Author: IonDola <idolanescu@estudiantec.cr>
Date:   Sat Sep 13 18:52:42 2025 -0600

    Traductor funcional, empezando prueba para USB

commit b7f3f6a73073d8bb0a2636de21c76319e4e9ae29
Author: IonDola <idolanescu@estudiantec.cr>
Date:   Tue Sep 9 11:08:51 2025 -0600

    Mi compu habla jaónes y yo estoy calvo

commit 72a5d31c45814d10460d503119d6746f9eaf4313
Author: IonDola <idolanescu@estudiantec.cr>
Date:   Tue Sep 9 07:33:21 2025 -0600

    Control point

commit b0188b20a31b3c1a9fcdf01cfa549d6d14fb1fe8
Author: IonDola <idolanescu@estudiantec.cr>
Date:   Mon Sep 8 16:02:27 2025 -0600

    Bootload for HelloWorld based on BrianOtto repository instructions

commit e2b2bb367fc795287cec4bd347d200ecea563bc8
Author: IonDola <idolanescu@estudiantec.cr>
Date:   Sat Sep 6 17:00:03 2025 -0600

    Longpain to make an img

commit 72c3b23f4e9f6cb898ba46b502783e90a7dfa032
Author: IonDola <idolanescu@estudiantec.cr>
Date:   Fri Sep 5 22:04:11 2025 -0600

    Basic structure of the project

commit f37fda2d3fb7529098a8534925faddb4b174297b
Author: IonDola <110049048+IonDola@users.noreply.github.com>
Date:   Thu Sep 4 16:40:07 2025 -0600

    Initial commit
(END)
```
 - **Autoevaluacion Segun Rubrica:**
	 - *<ins>Sector de Arranque</ins>:* 30/30
	 - *<ins>Morse</ins>:* 40/50
	 - *<ins>Documentacion</ins>:* 20/20
## 7. Lecciones Aprendidas
El desarrollo de esta tarea permitió:

-   Comprender el proceso de arranque de un sistema desde USB con EFI.
    
-   Profundizar en la programación en lenguaje ensamblador x86.
    
-   Entender los datos que otorga EFI a los programas de arranque (ConIn, ConOut, entre otros).
   
## 8. Bibliografia
-   _Download QEMU (Linux)_. (s. f.). QEMU Project. Recuperado de [https://www.qemu.org/download/#linux](https://www.qemu.org/download/#linux) [qemu.org](https://www.qemu.org/download?utm_source=chatgpt.com)
    
-   Writing an x86 “Hello World” boot loader with assembly. (s. f.). Medium. Recuperado de [https://medium.com/@g33konaut/writing-an-x86-hello-world-boot-loader-with-assembly-3e4c5bdd96cf](https://medium.com/@g33konaut/writing-an-x86-hello-world-boot-loader-with-assembly-3e4c5bdd96cf)
    
-   Frosnerd. (s. f.). Writing my own boot loader. DEV Community. Recuperado de [https://dev.to/frosnerd/writing-my-own-boot-loader-3mld](https://dev.to/frosnerd/writing-my-own-boot-loader-3mld)
    
-   How to write “Hello World” EFI application in NASM. (s. f.). Stack Overflow. Recuperado de [https://stackoverflow.com/questions/72947069/how-to-write-hello-world-efi-application-in-nasm](https://stackoverflow.com/questions/72947069/how-to-write-hello-world-efi-application-in-nasm)
    
-   u.mair. (s. f.). Writing a boot sector in assembly and running it with QEMU. Medium. Recuperado de [https://medium.com/@u.mair/writing-a-boot-sector-in-assembly-and-running-it-with-qemu-8f3d36d654e9](https://medium.com/@u.mair/writing-a-boot-sector-in-assembly-and-running-it-with-qemu-8f3d36d654e9)
    
-   POSIX-UEFI: Creating an EFI executable. (s. f.). OSDev Wiki. Recuperado de [https://wiki.osdev.org/POSIX-UEFI#Creating_an_EFI_executable](https://wiki.osdev.org/POSIX-UEFI#Creating_an_EFI_executable) [wiki.osdev.org](https://wiki.osdev.org/POSIX-UEFI?utm_source=chatgpt.com)
    
-   _Building a simple bootloader in NASM x86_. (s. f.). DEV Community. Recuperado de [https://dev.to/olivestem/building-a-simple-bootloader-in-nasm-x86-6nj](https://dev.to/olivestem/building-a-simple-bootloader-in-nasm-x86-6nj)
    
-   _Deprecated PC speaker option in QEMU_. (s. f.). Superuser. Recuperado de [https://superuser.com/questions/1755141/deprecated-pc-speaker-option-in-qemu](https://superuser.com/questions/1755141/deprecated-pc-speaker-option-in-qemu)
    
-   _QEMU system manual_. (s. f.). QEMU Project. Recuperado de [https://www.qemu.org/docs/master/system/qemu-manpage.html](https://www.qemu.org/docs/master/system/qemu-manpage.html)
    
-   NASM documentation: Sections on NASM doc 2.1.11. (s. f.). Recuperado de [https://leopard-adc.pepas.com/documentation/DeveloperTools/nasm/nasmdoc2.html#section-2.1.11](https://leopard-adc.pepas.com/documentation/DeveloperTools/nasm/nasmdoc2.html#section-2.1.11)
    
-   Unicode specification / explanation (Java / general). (s. f.). Universidad de Wisconsin-Madison / Tom W. Recuperado de [https://www.ssec.wisc.edu/~tomw/java/unicode.html](https://www.ssec.wisc.edu/~tomw/java/unicode.html)