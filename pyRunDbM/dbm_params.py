import numpy as np
import matplotlib.pyplot as plt
from scipy.optimize import minimize_scalar

from airfoil_io import Airfoil, interp_airfoil 
from utils import moving_average

def compute_similarity(airfoil1: Airfoil, airfoil2: Airfoil) -> tuple[float, float]:
    vec1 = airfoil1.get_interpolated_data()
    vec2 = airfoil2.get_interpolated_data()
    def mad_with_offset(C_offset: float) -> float:
        return np.mean(np.abs(vec1 - (vec2 - C_offset)))
    result = minimize_scalar(mad_with_offset)
    return (result.fun, result.x) if result.success else (np.inf, 0)

def plot_comparison(airfoil1: Airfoil, airfoil2: Airfoil, optimal_C: float, save_path: str | None = None):
    from utils import X_INTERP
    y1_interp = airfoil1.get_interpolated_data()
    y2_interp = airfoil2.get_interpolated_data()
    y2_adjusted = y2_interp - optimal_C
    plt.figure(figsize=(12, 8))
    plt.plot(X_INTERP, y1_interp, '-', label=f'{airfoil1.name[:30]} (Interp)', linewidth=2)
    plt.plot(X_INTERP, y2_interp, '--', label=f'{airfoil2.name[:30]} (Interp)', linewidth=.5)
    plt.plot(X_INTERP, y2_adjusted, '-', label=f'{airfoil2.name[:30]} (Adjusted by C={optimal_C:.4f})', linewidth=2)
    plt.gca().set_aspect('equal', adjustable='box')
    plt.title(f"Comparison: {airfoil1.name[:30]} vs {airfoil2.name[:30]}", fontsize=14)
    plt.xlabel("x"); plt.ylabel("y")
    plt.legend(fontsize=10, loc='upper left', bbox_to_anchor=(1.05, 1.0), borderaxespad=0.)
    plt.grid(True, linestyle='--', alpha=0.5)
    if save_path: plt.savefig(save_path, dpi=150); plt.close()
    else: plt.show()

def correct_airfoil_geometry_no_local_stiffening(airfoil_to_correct: Airfoil) -> Airfoil:
    from utils import X_INTERP
    from shapely import Polygon, LineString, make_valid

    if Polygon is None:
        print("Warning: Shapely not available. Cannot correct airfoil geometry.")
        return airfoil_to_correct

    points = list(zip(X_INTERP, airfoil_to_correct.colloc_vec))
    if tuple(points[0]) != tuple(points[-1]): points.append(points[0])

    try:
        original_polygon = Polygon(points)
        simplified_polygon = original_polygon.simplify(1e-5, preserve_topology=True)
        
        if simplified_polygon.is_valid and not LineString(simplified_polygon.exterior.coords).is_simple:
             valid_polygon = make_valid(simplified_polygon)
             if not isinstance(valid_polygon, Polygon):
                 if hasattr(valid_polygon, 'geoms'):
                     polygons = [g for g in valid_polygon.geoms if isinstance(g, Polygon)]
                     if polygons:
                         valid_polygon = max(polygons, key=lambda p: p.area)
                     else:
                         print(f"Could not extract a single polygon from make_valid for {airfoil_to_correct.name}.")
                         valid_polygon = simplified_polygon 
                 else:
                     valid_polygon = simplified_polygon
        elif not simplified_polygon.is_valid:
            valid_polygon = make_valid(simplified_polygon)
            if not isinstance(valid_polygon, Polygon):
                 if hasattr(valid_polygon, 'geoms'):
                     polygons = [g for g in valid_polygon.geoms if isinstance(g, Polygon)]
                     if polygons: valid_polygon = max(polygons, key=lambda p: p.area)
                     else: valid_polygon = simplified_polygon
                 else: valid_polygon = simplified_polygon
        else:
            valid_polygon = simplified_polygon

        boundary_coords = np.array(valid_polygon.exterior.coords)
        
        le_idx_corrected = np.argmin(boundary_coords[:, 0])
        
        x_corr_min, x_corr_max = boundary_coords[:,0].min(), boundary_coords[:,0].max()
        if x_corr_max > x_corr_min:
            x_corrected_norm = (boundary_coords[:,0] - x_corr_min) / (x_corr_max - x_corr_min)
        else:
            x_corrected_norm = boundary_coords[:,0]

        interp_result = interp_airfoil(x_corrected_norm, boundary_coords[:,1])
        if interp_result is None:
            print(f"Failed to re-interpolate corrected airfoil {airfoil_to_correct.name}. Returning original.")
            return airfoil_to_correct
            
        _, y_selig_corrected = interp_result
        
        y_selig_corrected_smooth = moving_average(y_selig_corrected, window_size=3)

        return Airfoil(airfoil_id=airfoil_to_correct.airfoil_id, name=f"{airfoil_to_correct.name}_corrected",
                       colloc_vec=y_selig_corrected_smooth, x_raw=X_INTERP, y_raw=y_selig_corrected_smooth)

    except Exception as e:
        print(f"Error correcting airfoil '{airfoil_to_correct.name}': {e}. Returning original.")
        return airfoil_to_correct

def correct_airfoil_geometry(airfoil_to_correct: Airfoil) -> Airfoil:
    from utils import X_INTERP, NUM_POINTS_INTERP
    from shapely import Polygon, LineString, MultiPoint, Point, make_valid

    if Polygon is None:
        print("Warning: Shapely library not available. Cannot correct airfoil geometry.")
        return airfoil_to_correct

    points = list(zip(X_INTERP, airfoil_to_correct.colloc_vec))
    if tuple(points[0]) != tuple(points[-1]):
        points.append(points[0])

    try:
        airfoil_shape_current = Polygon(points).simplify(1e-5, preserve_topology=True)
    except Exception as e:
        print(f"Error creating/simplifying initial polygon for {airfoil_to_correct.name}: {e}. Returning original.")
        return airfoil_to_correct

    try:
        line_boundary = LineString(airfoil_shape_current.exterior.coords)
        intersections = []
        intersection_coords_set = set()
        if not airfoil_shape_current.is_valid or not line_boundary.is_simple:
            temp_coords = list(line_boundary.coords)
            if len(temp_coords) < 4:
                pass
            else:
                all_segments = [LineString([temp_coords[k], temp_coords[k+1]]) for k in range(len(temp_coords) - 1)]
                
                num_segments = len(all_segments)
                for i in range(num_segments):
                    seg1 = all_segments[i]
                    for j in range(i + 2, num_segments):
                        seg2 = all_segments[j]
                        
                        if seg1.crosses(seg2):
                            intersection_pt_geom = seg1.intersection(seg2)
                            if not intersection_pt_geom.is_empty:
                                current_event_intersection_points = []
                                if isinstance(intersection_pt_geom, Point):
                                    current_event_intersection_points.append((intersection_pt_geom.x, intersection_pt_geom.y))
                                elif hasattr(intersection_pt_geom, 'geoms'):
                                    for geom_part in intersection_pt_geom.geoms:
                                        if isinstance(geom_part, Point):
                                            current_event_intersection_points.append((geom_part.x, geom_part.y))
                                        elif hasattr(geom_part, 'centroid'):
                                            cent = geom_part.centroid
                                            current_event_intersection_points.append((cent.x, cent.y))
                                elif hasattr(intersection_pt_geom, 'centroid'):
                                    cent = intersection_pt_geom.centroid
                                    current_event_intersection_points.append((cent.x, cent.y))
                                
                                for pt_coord in current_event_intersection_points:
                                    coord_tuple_rounded = (round(pt_coord[0], 7), round(pt_coord[1], 7))
                                    if coord_tuple_rounded not in intersection_coords_set:
                                        intersections.append(pt_coord)
                                        intersection_coords_set.add(coord_tuple_rounded)

        if not intersections:
            if not airfoil_shape_current.is_valid:
                airfoil_shape_current = make_valid(airfoil_shape_current)
                if not isinstance(airfoil_shape_current, Polygon):
                    if hasattr(airfoil_shape_current, 'geoms'):
                        polygons = [g for g in airfoil_shape_current.geoms if isinstance(g, Polygon)]
                        if polygons: airfoil_shape_current = max(polygons, key=lambda p: p.area)
                        else: return airfoil_to_correct
                    else: return airfoil_to_correct
            pass

        if intersections:
            boundary_coords_list = list(airfoil_shape_current.exterior.coords)

            for ix, iy in intersections:
                x_min_local, x_max_local = max(0, ix - 0.05), min(1, ix + 0.05)
                local_points = [(x, y) for x, y in boundary_coords_list if x_min_local <= x <= x_max_local]

                if len(local_points) < 3:
                    continue

                local_convex_hull = MultiPoint(local_points).convex_hull
                if not local_convex_hull.is_empty and isinstance(local_convex_hull, Polygon):
                    airfoil_shape_current = make_valid(airfoil_shape_current)
                    if not isinstance(airfoil_shape_current, Polygon):
                        if hasattr(airfoil_shape_current, 'geoms'):
                            polygons = [g for g in airfoil_shape_current.geoms if isinstance(g, Polygon)]
                            if polygons: airfoil_shape_current = max(polygons, key=lambda p: p.area)
                            else: continue
                        else: continue

                    airfoil_shape_current = airfoil_shape_current.union(local_convex_hull)
                    if not isinstance(airfoil_shape_current, Polygon) and hasattr(airfoil_shape_current, 'geoms'):
                        polygons = [g for g in airfoil_shape_current.geoms if isinstance(g, Polygon)]
                        if polygons: airfoil_shape_current = max(polygons, key=lambda p: p.area)
                        else: continue
                    elif not isinstance(airfoil_shape_current, Polygon):
                        continue
                else:
                    pass

        airfoil_shape_current = make_valid(airfoil_shape_current)
        if not isinstance(airfoil_shape_current, Polygon):
            if hasattr(airfoil_shape_current, 'geoms'):
                polygons = [g for g in airfoil_shape_current.geoms if isinstance(g, Polygon)]
                if polygons: airfoil_shape_current = max(polygons, key=lambda p: p.area)
                else:
                    print(f"Final shape for {airfoil_to_correct.name} is not a polygon after corrections. Returning original.")
                    return airfoil_to_correct
            else:
                print(f"Final shape for {airfoil_to_correct.name} is not a polygon. Returning original.")
                return airfoil_to_correct

        x_slices = np.linspace(0, 1, NUM_POINTS_INTERP // 2 + 1)
        upper_surface_pts, lower_surface_pts = [], []
        final_boundary = LineString(airfoil_shape_current.exterior.coords)

        for x_val in x_slices:
            vertical_line = LineString([(x_val, -1), (x_val, 1)])
            intersection = final_boundary.intersection(vertical_line)

            if intersection.is_empty:
                continue
            
            y_at_x = []
            if isinstance(intersection, Point):
                y_at_x.append(intersection.y)
            elif hasattr(intersection, 'geoms'):
                for geom_item in intersection.geoms:
                    if isinstance(geom_item, Point):
                        y_at_x.append(geom_item.y)

            if not y_at_x: continue

            y_at_x.sort(reverse=True)
            upper_surface_pts.append((x_val, y_at_x[0]))
            lower_surface_pts.append((x_val, y_at_x[-1]))
        
        if not upper_surface_pts or not lower_surface_pts:
            print(f"Failed to extract upper/lower surfaces for {airfoil_to_correct.name} after slicing. Returning original.")
            return airfoil_to_correct

        x_upper_resampled = np.array([p[0] for p in upper_surface_pts])
        y_upper_resampled = np.array([p[1] for p in upper_surface_pts])
        
        x_lower_resampled = np.array([p[0] for p in lower_surface_pts])
        y_lower_resampled = np.array([p[1] for p in lower_surface_pts])

        y_upper_smoothed = moving_average(y_upper_resampled, window_size=3)
        y_lower_smoothed = moving_average(y_lower_resampled, window_size=3)
        
        x_contour = list(x_upper_resampled[::-1])
        y_contour = list(y_upper_smoothed[::-1])

        x_contour.extend(x_lower_resampled[1:])
        y_contour.extend(y_lower_smoothed[1:])
        
        x_contour_np = np.array(x_contour)
        y_contour_np = np.array(y_contour)

        interp_result_final = interp_airfoil(x_contour_np, y_contour_np)
        if interp_result_final is None:
            print(f"Final re-interpolation failed for {airfoil_to_correct.name}. Returning original.")
            return airfoil_to_correct

        _, y_selig_final = interp_result_final

        corrected_airfoil_obj = Airfoil(
            airfoil_id=airfoil_to_correct.airfoil_id,
            name=f"{airfoil_to_correct.name}_corrected",
            colloc_vec=y_selig_final,
            x_raw=X_INTERP,
            y_raw=y_selig_final.copy()
        )
        return corrected_airfoil_obj

    except Exception as e:
        print(f"Broad error during airfoil correction for '{airfoil_to_correct.name}': {e}. Returning original.")
        import traceback
        traceback.print_exc()
        return airfoil_to_correct

def create_morphed_airfoil(weights: list[float] | np.ndarray, baseline_airfoils: list[Airfoil], 
                           correct_geometry: bool = False) -> Airfoil:
    from utils import X_INTERP
    if len(weights) != len(baseline_airfoils):
        raise ValueError("Length of weights must match the number of baseline airfoils.")

    weights_np = np.array(weights)
    if not np.isclose(np.sum(np.abs(weights_np)), 1.0) or np.any(np.abs(weights_np) > 1.0):
        sum_abs_weights = np.sum(np.abs(weights_np))
        if sum_abs_weights > 1e-6:
            weights_np = weights_np / sum_abs_weights
        else:
            weights_np = np.zeros_like(weights_np)

    if np.allclose(weights_np, 0):
        return Airfoil(airfoil_id=-1, name='Morphed_FlatLine', colloc_vec=np.zeros_like(X_INTERP),
                       x_raw=X_INTERP.copy(), y_raw=np.zeros_like(X_INTERP))

    y_morphed_sum = np.zeros_like(X_INTERP)
    for airfoil, weight in zip(baseline_airfoils, weights_np):
        y_morphed_sum += weight * airfoil.get_interpolated_data()
    
    weight_str = "_".join(f"{w:.3f}" for w in weights_np)
    morphed_name = f"Morphed_W[{weight_str[:50]}]"

    morphed_obj = Airfoil(airfoil_id=-1, name=morphed_name, colloc_vec=y_morphed_sum,
                          x_raw=X_INTERP.copy(), y_raw=y_morphed_sum.copy())
    
    if correct_geometry:
        return correct_airfoil_geometry(morphed_obj)
    return morphed_obj