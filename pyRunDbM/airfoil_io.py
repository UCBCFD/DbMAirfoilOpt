import os
import pickle
import numpy as np
import matplotlib.pyplot as plt
from scipy.interpolate import PchipInterpolator

class Airfoil:
    def __init__(self, airfoil_id: int, name: str, colloc_vec: np.ndarray, x_raw: np.ndarray, y_raw: np.ndarray):
        self.airfoil_id = airfoil_id
        self.name = name
        self.colloc_vec = colloc_vec
        self.x_raw = x_raw
        self.y_raw = y_raw

    def __str__(self) -> str:
        return f"Airfoil(ID={self.airfoil_id}, Name='{self.name}', Raw Data Points={len(self.x_raw)})"

    def get_raw_coordinates(self) -> tuple[np.ndarray, np.ndarray]:
        return self.x_raw, self.y_raw

    def get_interpolated_data(self) -> np.ndarray:
        return self.colloc_vec

    def plot(self, save_path: str | None = None) -> None:
        from utils import X_INTERP
        plt.figure(figsize=(10, 6))
        plt.plot(self.x_raw, self.y_raw, 'o', label='Raw Data', alpha=0.7, markersize=4)
        plt.plot(X_INTERP, self.colloc_vec, '-', label='Interpolated Data', linewidth=2)
        plt.gca().set_aspect('equal', adjustable='box')
        plt.title(f"Airfoil: {self.name}", fontsize=14)
        plt.xlabel("x", fontsize=12)
        plt.ylabel("y", fontsize=12)
        plt.legend(fontsize=10)
        plt.grid(True, linestyle='--', alpha=0.5)

        if save_path:
            plt.savefig(save_path, dpi=150, bbox_inches='tight')
            plt.close()
            print(f"Plot saved to {save_path}")
        else:
            plt.show()

def read_airfoil_file(file_path: str) -> tuple[str, np.ndarray, np.ndarray]:
    with open(file_path, 'r') as f:
        lines = f.readlines()
        name = lines[0].strip()
        coords_list = []
        is_goe451 = name.startswith("GOE 451")

        for line_content in lines[1:]:
            line_content = line_content.strip()
            if line_content.startswith("#") or not line_content:
                continue
            coords_list.append(list(map(float, line_content.split())))
        
        coords_np = np.array(coords_list)
        x_original, y_original = coords_np[:, 0], coords_np[:, 1]

        if is_goe451: # DB has error for this specific airfoil
            y_original[x_original == 0.0249500] = 0.0192620 

        x_min, x_max = x_original.min(), x_original.max()
        if x_max > x_min:
            x_original = (x_original - x_min) / (x_max - x_min)

    leading_edge_indices = np.where(np.isclose(x_original, 0, atol=1e-8))[0]

    if len(leading_edge_indices) == 0:
        for i in range(1, len(x_original)):
            if x_original[i-1] > 0 and x_original[i] < 0:
                y_le = np.interp(0, [x_original[i-1], x_original[i]], [y_original[i-1], y_original[i]])
                x_original = np.insert(x_original, i, 0)
                y_original = np.insert(y_original, i, y_le)
                break
    elif len(leading_edge_indices) == 2:
        upper_le_idx, lower_le_idx = leading_edge_indices
        y_avg_le = (y_original[upper_le_idx] + y_original[lower_le_idx]) / 2.0
        
        x_original[upper_le_idx] = 1e-6 
        x_original[lower_le_idx] = 1e-6
        
        insert_idx = min(upper_le_idx, lower_le_idx) + 1
        x_original = np.insert(x_original, insert_idx, 0)
        y_original = np.insert(y_original, insert_idx, y_avg_le)
        
    return name, x_original, y_original

def interp_airfoil(x_coords: np.ndarray, y_coords: np.ndarray) -> tuple[np.ndarray, np.ndarray] | None:
    from utils import X_INTERP, NUM_POINTS_INTERP
    
    idx_le = np.argmin(x_coords)
    x_upper_raw, y_upper_raw = x_coords[:idx_le+1], y_coords[:idx_le+1]
    x_lower_raw, y_lower_raw = x_coords[idx_le:], y_coords[idx_le:]

    if len(x_lower_raw) < 2 or len(x_upper_raw) < 2:
        return None

    unique_indices_upper = np.unique(x_upper_raw, return_index=True)[1]
    x_upper, y_upper = x_upper_raw[unique_indices_upper], y_upper_raw[unique_indices_upper]
    
    unique_indices_lower = np.unique(x_lower_raw, return_index=True)[1]
    x_lower, y_lower = x_lower_raw[unique_indices_lower], y_lower_raw[unique_indices_lower]
    
    if len(x_upper) < 2 or len(x_lower) < 2:
        return None

    try:
        f_upper = PchipInterpolator(x_upper, y_upper)
        f_lower = PchipInterpolator(x_lower, y_lower)
    except ValueError as e:
        print(f"PchipInterpolator failed: {e}. Check if x-coordinates are sorted and unique for upper/lower surfaces.")
        return None

    y_interp_upper = f_upper(X_INTERP[:NUM_POINTS_INTERP // 2 + 1])
    y_interp_lower = f_lower(X_INTERP[NUM_POINTS_INTERP // 2:])
    
    y_interp_combined = np.concatenate((y_interp_upper, y_interp_lower[1:]))
    return X_INTERP, y_interp_combined

def load_airfoil_database_from_files(data_folder: str, x_interp_coords: np.ndarray, num_interp_pts: int):
    airfoils_db: list[Airfoil] = []
    pickle_file_path = os.path.join(data_folder, 'airfoil_pydb.pkl')

    if os.path.exists(pickle_file_path):
        with open(pickle_file_path, 'rb') as f:
            airfoils_db = pickle.load(f)
    else:
        affile_list_raw = []
        if os.path.isdir(data_folder):
            affile_list_raw = os.listdir(data_folder)
            incompatible_files = {'30p-30n.dat', 'naca1.dat'} 
            affile_list_filtered = [f for f in affile_list_raw if f not in incompatible_files and f.endswith('.dat')]

            for idx, filename in enumerate(sorted(affile_list_filtered)):
                file_full_path = os.path.join(data_folder, filename)
                af_name, x_o, y_o = read_airfoil_file(file_full_path)
                
                interp_result = interp_airfoil(x_o, y_o) 
                if interp_result is None:
                    print(f"Skipping airfoil {af_name} due to interpolation issues or insufficient coordinate data.")
                    continue
                
                _, y_interp = interp_result
                airfoil_obj = Airfoil(airfoil_id=idx, name=af_name, colloc_vec=y_interp, x_raw=x_o, y_raw=y_o)
                airfoils_db.append(airfoil_obj)
                
        if airfoils_db and not os.path.exists(pickle_file_path):
            with open(pickle_file_path, 'wb') as f:
                pickle.dump(airfoils_db, f)
    
    print(f"Processed {len(airfoils_db)} airfoils in the database.")
    return airfoils_db