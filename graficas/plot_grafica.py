import matplotlib.pyplot as plt

def plot_coefficients(file_path, marker_color, title):
    X, Y = [], []
    for line in open(file_path, 'r'):
        values = [float(s) for s in line.split()]
        X.append(values[0])
        Y.append(values[1])
    
    plt.figure()
    plt.plot(X, Y, marker_color+'d', markersize=1.5)
    plt.title(title, fontsize=15)
    plt.grid()
    plt.xlabel('Coeficiente 2')
    plt.ylabel('Coeficiente 3')
    plt.show()

plot_coefficients('lp_graf.txt', 'r', 'Linear Prediction Coefficients')
plot_coefficients('lpcc_graf.txt', 'b', 'Linear Prediction Cepstrum Coefficients')
plot_coefficients('mfcc_graf.txt', 'g', 'Mel Frequency Cepstrum Coefficients')
