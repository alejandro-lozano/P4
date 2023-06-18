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
>* Completamos las funciones `compute` de los distintos métodos (en el script run_spkid):
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.sh
compute_lp() {
    db=$1
    shift
    for filename in $(sort $*); do
        mkdir -p `dirname $w/$FEAT/$filename.$FEAT`
        EXEC="wav2lp 8 $db/$filename.wav $w/$FEAT/$filename.$FEAT"
        echo $EXEC && $EXEC || exit 1
    done
}

compute_lpcc(){
    db=$1
    shift
    for filename in $(sort $*); do
        mkdir -p `dirname $w/$FEAT/$filename.$FEAT`
        EXEC="wav2lpcc 15 14 $db/$filename.wav $w/$FEAT/$filename.$FEAT"
        echo $EXEC && $EXEC || exit 1
    done
}

compute_mfcc(){
    db=$1
    shift
    for filename in $(sort $*); do
        mkdir -p `dirname $w/$FEAT/$filename.$FEAT`
        EXEC="wav2mfcc 18 30 8 $db/$filename.wav $w/$FEAT/$filename.$FEAT"
        echo $EXEC && $EXEC || exit 1
    done
}
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
>* Hacemos run_spkid para cada una de las tres parametrizaciones en la ventana de comandos (para el locutor en '/BLOCK01/SES017/'):
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.sh
run_spkid lp
run_spkid lpcc
run_spkid mfcc
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
>* Otra vez en la ventana de comandos, generamos los archivos .txt para cada parametrización:
>
>		* Parametrización LP
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.sh
fmatrix_show work/lp/BLOCK01/SES017/*.lp | egrep '^\[' | cut -f4,5 > ./graficas/lp_graf.txt
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
>		* Parametrización LPCC
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.sh
fmatrix_show work/lpcc/BLOCK01/SES017/*.lpcc | egrep '^\[' | cut -f4,5 > ./graficas/lpcc_graf.txt
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
>		* Parametrización MFCC
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.sh
fmatrix_show work/mfcc/BLOCK01/SES017/*.mfcc | egrep '^\[' | cut -f4,5 > ./graficas/mfcc_graf.txt
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
>* Finalmente, en MATLAB ejecutamos el siguiente código para conseguir las gráficas de cada parametrización:
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.sh
% Configuración de los archivos y títulos
files = {'lp_graf.txt', 'lpcc_graf.txt', 'mfcc_graf.txt'};
titles = {'Linear Prediction Coefficients', 'Linear Prediction Cepstrum Coefficients', 'Mel Frequency Cepstrum Coefficients'};
% Configuración del estilo de los marcadores
markers = {'r', 'g', 'b'};
% Configuración de las etiquetas de los ejes
xLabel = 'Coeficiente 2';
yLabel = 'Coeficiente 3';
% Configuración del tamaño del marcador
markerSize = 1.5;
% Configuración del tamaño de la fuente del título
titleFontSize = 15;
% Configuración de la cuadrícula
gridStatus = true;
% Trazar las gráficas en ventanas separadas
for i = 1:numel(files)
    % Cargar los datos
    data = dlmread(files{i});
    X = data(:, 1);
    Y = data(:, 2);
    
    % Crear una nueva ventana de gráfica
    figure;
    
    % Trazar los datos
    plot(X, Y, [markers{i} 'd'], 'MarkerSize', markerSize);
    
    % Configurar el título, etiquetas de ejes y cuadrícula
    title(titles{i}, 'FontSize', titleFontSize);
    xlabel(xLabel);
    ylabel(yLabel);
    grid(gca, gridStatus);
    
    % Ajustar los límites de los ejes para mostrar todas las muestras
    xlim([min(X) max(X)]);
    ylim([min(Y) max(Y)]);
end
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  + ¿Cuál de ellas le parece que contiene más información?
>Si examinamos detenidamente, podemos notar una diferencia significativa entre los coeficientes del LPCC y MFCC en comparación con el LPC. Los coeficientes del LPC exhiben una mayor coherencia y están más alineados, formando una zona con muchas muestras. Esto sugiere una correlación más fuerte y una menor dispersión, lo que se traduce en una menor entropía y, por lo tanto, mayor cantida de información.

>Por otro lado, tanto el LPCC como el MFCC muestran coeficientes dispersos y distribuidos de manera menos zonificada en el espacio. La dispersión de los coeficientes implica una correlación más débil y una mayor variabilidad, lo que se refleja en una mayor entropía y, por tanto, una mayor cantidad de infromación. Específicamente, los coeficientes del MFCC tienen un rango mucho más amplio, abarcando valores de 20 a 25, mientras que los valores del LPC se encuentran más comprimidos entre -1 y 1.

>En conclusión, el LPC es el que aporta menos información debido a su alta correlación y baja entropía, mientras que los coeficientes del MFCC son los que presentan una correlación más débil y una mayor entropía, lo que indica una mayor cantidad de información capturada en ellos.
>
- Usando el programa <code>pearson</code>, obtenga los coeficientes de correlación normalizada entre los
  parámetros 2 y 3 para un locutor, y rellene la tabla siguiente con los valores obtenidos.
> Mediante el programa `pearson` conseguimos los coeficientes de correlación normalizada a partir de los siguienes comandos:
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.sh
pearson -N work/lp/BLOCK01/SES017/*.lp >lp_pearson.txt
pearson -N work/lpcc/BLOCK01/SES017/*.lpcc >lpcc_pearson.txt
pearson -N work/mfcc/BLOCK01/SES017/*.mfcc >mfcc_pearson.txt
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  |                        | LP   | LPCC | MFCC |
  |------------------------|:----:|:----:|:----:|
  | &rho;<sub>x</sub>[2,3] |  -0.874552    |   0.181986   |  -0.177738    |
  
  + Compare los resultados de <code>pearson</code> con los obtenidos gráficamente.
>Los coeficientes de LP presentan la mayor correlación, seguidos por LPCC y MFCC. Al analizar los valores normalizados utilizando el coeficiente de correlación de Pearson, esta afirmación se confirma. Se observa que el coeficiente de correlación normalizada para LP es el más lejano a 0, casi alcanzando -1. En el LPCC y el MFCC, aunque presentan valores muy similares, se verifica que la correlación es menor para el MFCC ya que el valor es más cercano a cero.
>
- Según la teoría, ¿qué parámetros considera adecuados para el cálculo de los coeficientes LPCC y MFCC?
>De acuerdo con la teoría que hemos estudiado en clase, se recomienda que el orden del LPCC se encuentre cerca de 13. Esto implica que se debe considerar un valor cercano a esta cantidad para obtener resultados adecuados en el cálculo de los coeficientes LPCC.

>En el caso de los MFCC, se ha estudiado que el número de filtros Mel utilizados suele estar en el rango de 24 a 40. Estos filtros permiten capturar diferentes regiones de frecuencia y extraer características relevantes para el análisis. Además, se suele utilizar un número de coeficientes de MFCC de 13, lo que proporciona una representación compacta y significativa de la señal.

### Entrenamiento y visualización de los GMM.

Complete el código necesario para entrenar modelos GMM.

- Inserte una gráfica que muestre la función de densidad de probabilidad modelada por el GMM de un locutor
  para sus dos primeros coeficientes de MFCC.
  
  plot_gmm_feat work/gmm/mfcc/SES008.gmm
  ![image](https://github.com/alejandro-lozano/P4/assets/127206937/e1826839-ba3e-4532-bb6b-67362b69acf6)


gmm_train -d work/lp -e lp -g SES008.gmm -m 10 -N 100000 -T  0.0001 -i 2 lists/class/SES008.train
python3 scripts/plot_gmm_feat.py SES008.gmm
<img width="279" alt="image" src="https://github.com/alejandro-lozano/P4/assets/125287859/52635f99-7b18-499d-b2ab-678e47f7364a">

plot_gmm_feat work/gmm/mfcc/SES008.gmm work/mfcc/BLOCK00/SES008/SA008S* &
<img width="277" alt="image" src="https://github.com/alejandro-lozano/P4/assets/125287859/7abffc02-d919-461d-b68d-77d6be015fab">

plot_gmm_feat work/gmm/mfcc/SES008.gmm work/mfcc/BLOCK01/SES015/SA015S* &
<img width="277" alt="image" src="https://github.com/alejandro-lozano/P4/assets/125287859/39649c80-22ce-4459-aa4e-07c1659dca42">

 plot_gmm_feat work/gmm/mfcc/SES015.gmm work/mfcc/BLOCK01/SES015/SA015S* &
 <img width="272" alt="image" src="https://github.com/alejandro-lozano/P4/assets/125287859/2f1bd181-3366-4779-98be-9c7c6bb14163">

- Inserte una gráfica que permita comparar los modelos y poblaciones de dos locutores distintos (la gŕafica
  de la página 20 del enunciado puede servirle de referencia del resultado deseado). Analice la capacidad
  del modelado GMM para diferenciar las señales de uno y otro.

  

### Reconocimiento del locutor.

Complete el código necesario para realizar reconociminto del locutor y optimice sus parámetros.

- Inserte una tabla con la tasa de error obtenida en el reconocimiento de los locutores de la base de datos
  SPEECON usando su mejor sistema de reconocimiento para los parámetros LP, LPCC y MFCC.
>

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
