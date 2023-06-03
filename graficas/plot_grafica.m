% Configuración de los archivos y títulos
files = {'lp_graf.txt', 'lpcc_graf.txt', 'mfcc_graf.txt'};
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
% Trazar las gráficas
for i = 1:numel(files)
    % Cargar los datos
    data = dlmread(files{i});
    X = data(:, 1);
    Y = data(:, 2);
    
    % Crear una nueva subfigura
    subplot(numel(files), 1, i);
    
    % Trazar los datos
    plot(X, Y, [markers{i} 'd'], 'MarkerSize', markerSize);
    
    % Configurar el título, etiquetas de ejes y cuadrícula
    title(titles{i}, 'FontSize', titleFontSize);
    xlabel(xLabel);
    ylabel(yLabel);
    grid(gca, gridStatus);
    
    % Ajustar los límites de los ejes para mostrar todas las muestras
    xlim([min(X)-1 max(X)+1]);
    ylim([min(Y)-1 max(Y)+1]);
end