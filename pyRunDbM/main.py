import sys
import os
import numpy as np
import pickle

try:
    from dbm_params import create_morphed_airfoil
    from airfoil_io import Airfoil, load_airfoil_database_from_files
    from utils import NUM_POINTS_INTERP, X_INTERP, DATA_FOLDER
except ImportError as e:
    print(f"Python Error: Error importing Python modules: {e}", file=sys.stderr)
    print("Python Error: Ensure run_python_dbm.py can find your Python code (airfoil_io, parameterization, etc.).", file=sys.stderr)
    sys.exit(2)

def load_python_12_baselines(expected_baseline_names):
    try:
        full_airfoil_db = load_airfoil_database_from_files(DATA_FOLDER, X_INTERP, NUM_POINTS_INTERP)
        if not full_airfoil_db:
            print("Python Error: Full airfoil database could not be loaded.", file=sys.stderr)
            return []

        selected_baselines_dict = {}
        for af_obj in full_airfoil_db:
            if af_obj.name in expected_baseline_names:
                selected_baselines_dict[af_obj.name] = af_obj
        
        ordered_baselines = []
        for name in expected_baseline_names:
            if name in selected_baselines_dict:
                ordered_baselines.append(selected_baselines_dict[name])
            else:
                print(f"Python Error: Baseline airfoil '{name}' not found in the database.", file=sys.stderr)
                return []

        if len(ordered_baselines) == len(expected_baseline_names):
            return ordered_baselines
        else:
            print(f"Python Error: Did not find all {len(expected_baseline_names)} expected baselines. Found {len(ordered_baselines)}.", file=sys.stderr)
            return []

    except Exception as e:
        print(f"Python Error during baseline loading: {e}", file=sys.stderr)
        return []


if __name__ == "__main__":
    if len(sys.argv) != 13:
        print(f"Python Error: Expected 13 arguments (script + 12 weights), got {len(sys.argv)}", file=sys.stderr)
        sys.exit(1)

    try:
        weights = np.array([float(arg) for arg in sys.argv[1:13]])
    except ValueError:
        print("Python Error: Could not convert all weights to float.", file=sys.stderr)
        sys.exit(1)
    
    dbm_baseline_names_python = [
        "AH 81-K-144 W-F KLAPPE", "AH 93-W-480B", "CHEN AIRFOIL",
        "E195  (11.82%)", "EPPLER 664 (EXTENDED) AIRFOIL", "EPPLER 864 STRUT AIRFOIL",
        "FX 79-W-660A", "GOE 531 AIRFOIL", "Griffith 30% Suction Airfoil",
        "RONCZ R1145MS MAIN ELEMENT", "S9104", "SARATOV AIRFOIL"
    ]

    if not python_baselines or len(python_baselines) != 12:
        print("Python Error: Failed to load the 12 baselines correctly.", file=sys.stderr)
        sys.exit(1)

    try:
        morphed_airfoil_obj = create_morphed_airfoil(weights, python_baselines, correct_geometry=True)
        # morphed_airfoil_obj.plot('geometry.png')
        
        output_coords = np.vstack((X_INTERP, morphed_airfoil_obj.get_interpolated_data())).T
        np.savetxt("airfoil_coords.dat", output_coords, fmt="%.8f")
        
    except Exception as e:
        print(f"Python Error during morphing or saving: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc(file=sys.stderr)
        sys.exit(1)
        
    sys.exit(0)
