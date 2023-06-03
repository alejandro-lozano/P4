PAV - P4: reconocimiento y verificación del locutor
===================================================

Obtenga su copia del repositorio de la práctica accediendo a [Práctica 4](https://github.com/albino-pav/P4)
y pulsando sobre el botón `Fork` situado en la esquina superior derecha. A continuación, siga las
instrucciones de la [Práctica 2](https://github.com/albino-pav/P2) para crear una rama con el apellido de
los integrantes del grupo de prácticas, dar de alta al resto de integrantes como colaboradores del proyecto
y crear la copias locales del repositorio.

También debe descomprimir, en el directorio `PAV/P4`, el fichero [db_8mu.tgz](https://atenea.upc.edu/mod/resource/view.php?id=3654387?forcedownload=1)
con la base de datos oral que se utilizará en la parte experimental de la práctica.

Como entrega deberá realizar un *pull request* con el contenido de su copia del repositorio. Recuerde
que los ficheros entregados deberán estar en condiciones de ser ejecutados con sólo ejecutar:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.sh
  make release
  run_spkid mfcc train test classerr verify verifyerr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Recuerde que, además de los trabajos indicados en esta parte básica, también deberá realizar un proyecto
de ampliación, del cual deberá subir una memoria explicativa a Atenea y los ficheros correspondientes al
repositorio de la práctica.

A modo de memoria de la parte básica, complete, en este mismo documento y usando el formato *markdown*, los
ejercicios indicados.

## Ejercicios.

### SPTK, Sox y los scripts de extracción de características.

- Analice el script `wav2lp.sh` y explique la misión de los distintos comandos involucrados en el *pipeline*
  principal (`sox`, `$X2X`, `$FRAME`, `$WINDOW` y `$LPC`). Explique el significado de cada una de las 
  opciones empleadas y de sus valores.
>En el script 'wav2lp.sh' encontramos el siguiente pipeline principal:
>
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.sh
# Main command for feature extraction
sox $inputfile -t raw -e signed -b 16 - | $X2X +sf | $FRAME -l 240 -p 80 | $WINDOW -l 240 -L 240 |
   $LPC -l 240 -m $lpc_order > $base.lp || exit 1
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
>* `sox`:Se trata de una herramienta de línea de comandos multiplataforma, compatible con Windows, Linux, MacOS X, y más. Su función principal es la conversión de diversos formatos de archivos de audio a otros formatos. Además, ofrece la capacidad de aplicar varios efectos a estos archivos de sonido. También permite reproducir y grabar archivos de audio en la mayoría de las plataformas. 
>En el código proporcionado, se ha utilizado sox para convertir un archivo de entrada en formato raw a un formato de enteros con signo (signed-integer) de 16 bits por muestra. Esto se ha logrado mediante el uso de las opciones '-t', '-e' y '-b'. 
>	* `-t`: Formato del fichero de entrada de audio. En nuestro programa es raw.
>	* `-e`: Tipo de codificación aplicada al fichero de entrada. En nuestro programa es signed-integer.
>	* `-b`: Indica el sample size, o sea, el número de bits por muestra utilizado en la codifiación. En nustro programa es 16 bits.
>* `$X2X`: Permite convertir datos de una entrada a otro tipo de datos. En nuestro programa usamos short float (sf).
>* `$FRAME`: Divide la secuencia de datos de un archivo en diferentes tramas, convierte la señal a tramas de 'l' muestras con desplazamientos de 'p' muestras. En nuestro programa divide en segmentos de 240 muestras con un desplazamiento entre las tramas de 80 muestras.
>* `$WINDOW`: Enventana una trama de datos multiplicando los elementos de la señal de entrada, que tiene una duración de l, por los elementos de una ventana específica w, obteniendo así una trama enventanada de duración L. En este caso particular, hemos utilizado una longitud de ventana igual a la duración de la trama (l=L=240 muestras) y se ha seleccionado la ventana Blackman, que va por defecto (w=0).
>* `$LPC`: Calcula los coeficientes de predicción lineal (LPC) de orden m de las l muestras de la señal de entrada usando el método de Levinson-Durbin. En nuestro programa l=240 muestras y con la opción -m se pone el número usado de coeficientes.

- Explique el procedimiento seguido para obtener un fichero de formato *fmatrix* a partir de los ficheros de
  salida de SPTK (líneas 45 a 51 del script `wav2lp.sh`).
> En estas líneas del script tenemos la siguiente parte:
>
>Primero tenemos las líneas de código ya explicadas en el apartado anterior:
>
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.sh
# Main command for feature extraction
sox $inputfile -t raw -e signed -b 16 - | $X2X +sf | $FRAME -l 240 -p 80 | $WINDOW -l 240 -L 240 |
   $LPC -l 240 -m $lpc_order > $base.lp || exit 1
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
>
>Después tenemos las líneas de código que calculan el número de filas y de columnas de la matriz:
>
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.sh
# Our array files need a header with the number of cols and rows:
ncol=$((lpc_order+1)) # lpc p =>  (gain a1 a2 ... ap) 
nrow=`$X2X +fa < $base.lp | wc -l | perl -ne 'print $_/'$ncol', "\n";'`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
>
>El parámetro "ncol" especifica el número de columnas que tendrá la matriz. En este caso, el número de columnas debe ser igual al orden del LPC (Linear Predictive Coding) más uno. Esto se debe a que el primer elemento de cada columna en la matriz representa la ganancia del sistema (potencia del error).
>
>Por otro lado, el parámetro "nrow" se utiliza para convertir el contenido del archivo temporal "$base.lp" (que contiene los coeficientes) de formato float (indicado por "+f") a formato ASCII (indicado por "+a"). Luego, se utiliza el comando "wc -l" para contar el número de líneas del archivo ASCII, lo que nos dará el número de filas de la matriz en el archivo resultante "fmatrix". Finalmente, se utiliza el comando "perl -ne" para imprimir la matriz resultante, asegurando que haya un salto de línea entre filas y columnas.


 * ¿Por qué es más conveniente el formato *fmatrix* que el SPTK?
>El formato fmatrix presenta una ventaja significativa ya que es mucho más cómodo para guardar los datos, ya que al trabajar con coeficientes de tramas permite un acceso más eficiente. Al adoptar una estructura matricial, los índices i,j de la matriz se corresponden directamente con los coeficientes i de la trama j, lo que resulta en un acceso sencillo a los diferentes coficientes de un audio en concreto (situándonos en la posición de la matriz que nos interese).
>
>Si no se usa este formato matricial, los valores de los coeficientes aparecerían apelotonados, provocando que no fuera fácil trabajar con ellos.

- Escriba el *pipeline* principal usado para calcular los coeficientes cepstrales de predicción lineal
  (LPCC) en su fichero <code>scripts/wav2lpcc.sh</code>:
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.sh
# Main command for feature extration
sox $inputfile -t raw -e signed -b 16 - | $X2X +sf | $FRAME -l 240 -p 80 | $WINDOW -l 240 -L 240 |
	$LPC -l 240 -m $lpc_order | $LPCC -m $lpc_order -M $lpcc_order > $base.lpcc
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- Escriba el *pipeline* principal usado para calcular los coeficientes cepstrales en escala Mel (MFCC) en su
  fichero <code>scripts/wav2mfcc.sh</code>:
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.sh
# Main command for feature extration
sox $inputfile -t raw -e signed -b 16 - | $X2X +sf | $FRAME -l 240 -p 80 | $WINDOW -l 240 -L 240 |
	$MFCC -l 240 -m $mfcc_order -n $filterbank_order -s $sampling_freq  > $base.mfcc
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

### Extracción de características.

- Inserte una imagen mostrando la dependencia entre los coeficientes 2 y 3 de las tres parametrizaciones
  para todas las señales de un locutor.
>
>![image (37)](https://github.com/alejandro-lozano/P4/assets/127206937/5e508439-a42e-4481-a5d2-a7797b783da6)
>
>![image (38)](https://github.com/alejandro-lozano/P4/assets/127206937/3aeddfca-b8cf-46a0-aad7-d7be1aeaca05)
>
>![image (39)](https://github.com/alejandro-lozano/P4/assets/127206937/e4abed77-4a8d-463f-be22-d55174120475)


  
  + Indique **todas** las órdenes necesarias para obtener las gráficas a partir de las señales 
    parametrizadas.
  + ¿Cuál de ellas le parece que contiene más información?

- Usando el programa <code>pearson</code>, obtenga los coeficientes de correlación normalizada entre los
  parámetros 2 y 3 para un locutor, y rellene la tabla siguiente con los valores obtenidos.

  |                        | LP   | LPCC | MFCC |
  |------------------------|:----:|:----:|:----:|
  | &rho;<sub>x</sub>[2,3] |      |      |      |
  
  + Compare los resultados de <code>pearson</code> con los obtenidos gráficamente.
  
- Según la teoría, ¿qué parámetros considera adecuados para el cálculo de los coeficientes LPCC y MFCC?

### Entrenamiento y visualización de los GMM.

Complete el código necesario para entrenar modelos GMM.

- Inserte una gráfica que muestre la función de densidad de probabilidad modelada por el GMM de un locutor
  para sus dos primeros coeficientes de MFCC.

- Inserte una gráfica que permita comparar los modelos y poblaciones de dos locutores distintos (la gŕafica
  de la página 20 del enunciado puede servirle de referencia del resultado deseado). Analice la capacidad
  del modelado GMM para diferenciar las señales de uno y otro.

### Reconocimiento del locutor.

Complete el código necesario para realizar reconociminto del locutor y optimice sus parámetros.

- Inserte una tabla con la tasa de error obtenida en el reconocimiento de los locutores de la base de datos
  SPEECON usando su mejor sistema de reconocimiento para los parámetros LP, LPCC y MFCC.

### Verificación del locutor.

Complete el código necesario para realizar verificación del locutor y optimice sus parámetros.

- Inserte una tabla con el *score* obtenido con su mejor sistema de verificación del locutor en la tarea
  de verificación de SPEECON. La tabla debe incluir el umbral óptimo, el número de falsas alarmas y de
  pérdidas, y el score obtenido usando la parametrización que mejor resultado le hubiera dado en la tarea
  de reconocimiento.
 
### Test final

- Adjunte, en el repositorio de la práctica, los ficheros `class_test.log` y `verif_test.log` 
  correspondientes a la evaluación *ciega* final.

### Trabajo de ampliación.

- Recuerde enviar a Atenea un fichero en formato zip o tgz con la memoria (en formato PDF) con el trabajo 
  realizado como ampliación, así como los ficheros `class_ampl.log` y/o `verif_ampl.log`, obtenidos como 
  resultado del mismo.
