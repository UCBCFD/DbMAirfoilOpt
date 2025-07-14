import numpy as np

NUM_POINTS_INTERP: int = 201
X_INTERP_HALF_DESC: np.ndarray = np.linspace(1, 0, NUM_POINTS_INTERP // 2 + 1)
X_INTERP_HALF_ASC: np.ndarray = np.linspace(0, 1, NUM_POINTS_INTERP // 2 + 1)[1:]
X_INTERP: np.ndarray = np.concatenate((X_INTERP_HALF_DESC, X_INTERP_HALF_ASC))
DATA_FOLDER: str = '../../airfoilDB'

def moving_average(y_values: np.ndarray, window_size: int = 5) -> np.ndarray:
    if window_size < 1: return y_values
    return np.convolve(y_values, np.ones(window_size)/window_size, mode='same')