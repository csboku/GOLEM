#!/usr/bin/env python3
import sys
import os
from PySide6.QtWidgets import (QApplication, QMainWindow, QFileDialog, QSplitter, 
                              QVBoxLayout, QHBoxLayout, QWidget, QPushButton, 
                              QLabel, QComboBox, QTextEdit, QStatusBar, QCheckBox,
                              QLineEdit, QFrame, QSlider)
from PySide6.QtCore import Qt
import matplotlib
matplotlib.use('Qt5Agg')
from matplotlib.backends.backend_qt5agg import FigureCanvasQTAgg as FigureCanvas
from matplotlib.figure import Figure
from matplotlib import cm
import numpy as np
import xarray as xr

class MatplotlibCanvas(FigureCanvas):
    def __init__(self, parent=None, width=5, height=4, dpi=100):
        self.fig = Figure(figsize=(width, height), dpi=dpi)
        self.axes = self.fig.add_subplot(111)
        self.colorbar = None  # Store reference to colorbar to remove it later
        super(MatplotlibCanvas, self).__init__(self.fig)

from PySide6.QtCore import Signal, Slot, Qt, QTimer
from PySide6.QtGui import QDoubleValidator

class NetCDFViewer(QMainWindow):
    def __init__(self):
        super().__init__()
        
        self.dataset = None
        self.current_variable = None
        self.current_cmap = 'viridis'  # Default colormap
        
        # Default scale range
        self.auto_scale = True
        self.scale_min = None
        self.scale_max = None
        
        # Animation settings
        self.time_dimension = None
        self.play_timer = QTimer()
        self.play_timer.timeout.connect(self.next_timestep)
        self.play_speed = 500  # milliseconds between frames
        
        # Available colormaps for heatmaps
        self.available_cmaps = [
            'viridis', 'plasma', 'inferno', 'magma', 'cividis',  # Perceptually uniform
            'jet', 'rainbow', 'turbo',  # Sequential
            'coolwarm', 'bwr', 'seismic',  # Diverging
            'terrain', 'ocean', 'gist_earth',  # Geographic
            'hot', 'bone', 'cool', 'copper'  # Special purpose
        ]
        
        self.init_ui()
        
    def init_ui(self):
        self.setWindowTitle("NetCDF Viewer")
        self.setGeometry(100, 100, 1200, 800)
        
        # Main widget and layout
        main_widget = QWidget()
        main_layout = QHBoxLayout(main_widget)
        
        # Create splitter for resizable panels
        splitter = QSplitter(Qt.Horizontal)
        
        # Left panel (controls and metadata)
        left_panel = QWidget()
        left_layout = QVBoxLayout(left_panel)
        
        # File selection
        file_btn = QPushButton("Open NetCDF File")
        file_btn.clicked.connect(self.open_file)
        left_layout.addWidget(file_btn)
        
        # Variable selection
        self.var_combo = QComboBox()
        self.var_combo.currentIndexChanged.connect(self.variable_selected)
        var_label = QLabel("Select Variable:")
        left_layout.addWidget(var_label)
        left_layout.addWidget(self.var_combo)
        
        # Colormap selection for 2D data
        self.cmap_combo = QComboBox()
        for cmap in self.available_cmaps:
            self.cmap_combo.addItem(cmap)
        self.cmap_combo.setCurrentText(self.current_cmap)
        self.cmap_combo.currentTextChanged.connect(self.colormap_changed)
        cmap_label = QLabel("Select Colormap:")
        left_layout.addWidget(cmap_label)
        left_layout.addWidget(self.cmap_combo)
        
        # Dimension selection (for slicing 3D+ data)
        self.dim_layout = QVBoxLayout()
        self.dim_widgets = {}
        left_layout.addLayout(self.dim_layout)
        
        # Add scale controls for 2D data
        scale_label = QLabel("Value Scale:")
        left_layout.addWidget(scale_label)
        
        # Auto-scale checkbox
        self.auto_scale_cb = QCheckBox("Auto Scale")
        self.auto_scale_cb.setChecked(True)
        self.auto_scale_cb.stateChanged.connect(self.toggle_auto_scale)
        left_layout.addWidget(self.auto_scale_cb)
        
        # Min/Max scale inputs in a horizontal layout
        scale_layout = QHBoxLayout()
        
        min_label = QLabel("Min:")
        self.min_input = QLineEdit()
        self.min_input.setValidator(QDoubleValidator())
        self.min_input.setEnabled(False)  # Initially disabled when auto-scale is on
        self.min_input.returnPressed.connect(self.update_scale)
        
        max_label = QLabel("Max:")
        self.max_input = QLineEdit()
        self.max_input.setValidator(QDoubleValidator())
        self.max_input.setEnabled(False)  # Initially disabled when auto-scale is on
        self.max_input.returnPressed.connect(self.update_scale)
        
        scale_layout.addWidget(min_label)
        scale_layout.addWidget(self.min_input)
        scale_layout.addWidget(max_label)
        scale_layout.addWidget(self.max_input)
        
        left_layout.addLayout(scale_layout)
        
        # High/Low scale buttons in horizontal layout
        scale_adj_layout = QHBoxLayout()
        
        self.low_scale_btn = QPushButton("Lower Scale")
        self.low_scale_btn.clicked.connect(self.lower_scale)
        self.low_scale_btn.setEnabled(False)  # Initially disabled when auto-scale is on
        
        self.high_scale_btn = QPushButton("Raise Scale")
        self.high_scale_btn.clicked.connect(self.raise_scale)
        self.high_scale_btn.setEnabled(False)  # Initially disabled when auto-scale is on
        
        scale_adj_layout.addWidget(self.low_scale_btn)
        scale_adj_layout.addWidget(self.high_scale_btn)
        
        left_layout.addLayout(scale_adj_layout)
        
        # Apply scale button
        self.apply_scale_btn = QPushButton("Apply Scale")
        self.apply_scale_btn.clicked.connect(self.update_scale)
        self.apply_scale_btn.setEnabled(False)  # Initially disabled when auto-scale is on
        left_layout.addWidget(self.apply_scale_btn)
        
        # Add separator
        separator = QFrame()
        separator.setFrameShape(QFrame.HLine)
        separator.setFrameShadow(QFrame.Sunken)
        left_layout.addWidget(separator)
        
        # Timestep navigation controls
        time_nav_layout = QHBoxLayout()
        
        prev_btn = QPushButton("◀ Prev")
        prev_btn.clicked.connect(self.prev_timestep)
        
        self.play_btn = QPushButton("▶ Play")
        self.play_btn.setCheckable(True)
        self.play_btn.clicked.connect(self.toggle_play)
        
        next_btn = QPushButton("Next ▶")
        next_btn.clicked.connect(self.next_timestep)
        
        time_nav_layout.addWidget(prev_btn)
        time_nav_layout.addWidget(self.play_btn)
        time_nav_layout.addWidget(next_btn)
        
        left_layout.addLayout(time_nav_layout)
        
        # Speed control slider
        speed_layout = QHBoxLayout()
        speed_label = QLabel("Animation Speed:")
        
        self.speed_slider = QSlider(Qt.Horizontal)
        self.speed_slider.setRange(100, 2000)  # 100ms to 2000ms
        self.speed_slider.setValue(self.play_speed)
        self.speed_slider.valueChanged.connect(self.change_speed)
        
        speed_layout.addWidget(speed_label)
        speed_layout.addWidget(self.speed_slider)
        
        left_layout.addLayout(speed_layout)
        
        # Add another separator
        separator2 = QFrame()
        separator2.setFrameShape(QFrame.HLine)
        separator2.setFrameShadow(QFrame.Sunken)
        left_layout.addWidget(separator2)
        
        # Save plot button
        save_btn = QPushButton("Save Plot")
        save_btn.clicked.connect(self.save_plot)
        left_layout.addWidget(save_btn)
        
        # Metadata display
        meta_label = QLabel("Metadata:")
        left_layout.addWidget(meta_label)
        self.meta_text = QTextEdit()
        self.meta_text.setReadOnly(True)
        left_layout.addWidget(self.meta_text)
        
        left_layout.addStretch(1)
        
        # Right panel (visualization)
        right_panel = QWidget()
        right_layout = QVBoxLayout(right_panel)
        
        self.canvas = MatplotlibCanvas(self)
        right_layout.addWidget(self.canvas)
        
        # Add panels to splitter
        splitter.addWidget(left_panel)
        splitter.addWidget(right_panel)
        
        # Set initial sizes
        splitter.setSizes([400, 800])
        
        main_layout.addWidget(splitter)
        self.setCentralWidget(main_widget)
        
        # Status bar
        self.statusBar = QStatusBar()
        self.setStatusBar(self.statusBar)
        self.statusBar.showMessage("Ready")
    
    def open_file(self):
        file_path, _ = QFileDialog.getOpenFileName(
            self, "Open NetCDF File", "", "NetCDF Files (*.nc *.nc4 *.cdf);;All Files (*)"
        )
        
        if file_path:
            try:
                self.statusBar.showMessage(f"Loading {os.path.basename(file_path)}...")
                self.dataset = xr.open_dataset(file_path)
                self.update_variable_list()
                self.update_metadata()
                self.statusBar.showMessage(f"Loaded {os.path.basename(file_path)}")
            except Exception as e:
                self.statusBar.showMessage(f"Error: {str(e)}")
    
    def update_variable_list(self):
        self.var_combo.clear()
        if self.dataset is not None:
            for var_name in self.dataset.data_vars:
                self.var_combo.addItem(var_name)
    
    def update_metadata(self):
        if self.dataset is not None:
            metadata = f"Dimensions:\n"
            for dim_name, dim_size in self.dataset.dims.items():
                metadata += f"  {dim_name}: {dim_size}\n"
            
            metadata += f"\nVariables:\n"
            for var_name, var in self.dataset.data_vars.items():
                metadata += f"  {var_name} ({var.dtype}): {tuple(var.dims)}\n"
                if var.attrs:
                    metadata += f"    Attributes:\n"
                    for attr_name, attr_val in var.attrs.items():
                        metadata += f"      {attr_name}: {attr_val}\n"
            
            metadata += f"\nGlobal Attributes:\n"
            for attr_name, attr_val in self.dataset.attrs.items():
                metadata += f"  {attr_name}: {attr_val}\n"
            
            self.meta_text.setText(metadata)
    
    def clear_dimension_selectors(self):
        # Clear existing dimension selectors
        for widget in self.dim_widgets.values():
            widget['label'].deleteLater()
            if widget['combo'] is not None:
                widget['combo'].deleteLater()
        self.dim_widgets = {}
    
    def create_dimension_selectors(self, var_obj):
        self.clear_dimension_selectors()
        
        # First determine what dimensions we need to select
        dims = list(var_obj.dims)
        
        # For 1D data, no selectors needed
        if len(dims) <= 1:
            return
            
        # For 2D data, show dimension info but no selectors needed
        if len(dims) == 2:
            label = QLabel(f"Displaying 2D data with dimensions: {dims[0]}, {dims[1]}")
            self.dim_layout.addWidget(label)
            self.dim_widgets['info'] = {'label': label, 'combo': None}
            return
            
        # For 3D+ data, we need to select which dimensions to display
        # We'll automatically select the last two dimensions for display
        # and provide selectors for the others
        display_dims = dims[-2:]  # Use last two dimensions for the 2D plot
        select_dims = dims[:-2]  # Create selectors for the other dimensions
        
        info_label = QLabel(f"Displaying dimensions: {display_dims[0]}, {display_dims[1]}")
        self.dim_layout.addWidget(info_label)
        self.dim_widgets['info'] = {'label': info_label, 'combo': None}
        
        # Add a spacer
        spacer_label = QLabel("")
        self.dim_layout.addWidget(spacer_label)
        self.dim_widgets['spacer'] = {'label': spacer_label, 'combo': None}
        
        # Create selectors for the remaining dimensions
        for dim_name in select_dims:
            dim_size = var_obj.sizes[dim_name]
            
            label = QLabel(f"Select {dim_name}:")
            combo = QComboBox()
            
            # If we have coordinate values, show them in the dropdown
            if dim_name in var_obj.coords:
                coord_values = var_obj.coords[dim_name].values
                for i in range(dim_size):
                    # Format the value for display
                    try:
                        # Try to format as a date/time if it looks like one
                        if hasattr(coord_values[i], 'strftime'):
                            value_str = coord_values[i].strftime('%Y-%m-%d %H:%M:%S')
                        else:
                            value_str = f"{coord_values[i]}"
                    except:
                        value_str = f"{i}"
                    
                    combo.addItem(f"{i}: {value_str}")
            else:
                # Otherwise just show indices
                for i in range(dim_size):
                    combo.addItem(f"{i}")
            
            self.dim_layout.addWidget(label)
            self.dim_layout.addWidget(combo)
            
            self.dim_widgets[dim_name] = {'label': label, 'combo': combo}
            
            # Store the current function reference so we can disconnect it later
            update_function = lambda idx, dim=dim_name: self.update_plot()
            combo.currentIndexChanged.connect(update_function)
            # Store the function reference in the widget dict
            self.dim_widgets[dim_name]['update_function'] = update_function
    
    def variable_selected(self):
        if self.dataset is None:
            return
        
        var_name = self.var_combo.currentText()
        if var_name:
            self.current_variable = var_name
            
            # Reset scale values for new variable if auto-scale is enabled
            if self.auto_scale:
                self.scale_min = None
                self.scale_max = None
                self.min_input.setText("")
                self.max_input.setText("")
            
            self.create_dimension_selectors(self.dataset[var_name])
            self.update_plot()
    
    def colormap_changed(self, cmap_name):
        self.current_cmap = cmap_name
        self.update_plot()
        
    def toggle_auto_scale(self, state):
        self.auto_scale = state == Qt.Checked
        self.min_input.setEnabled(not self.auto_scale)
        self.max_input.setEnabled(not self.auto_scale)
        self.apply_scale_btn.setEnabled(not self.auto_scale)
        self.low_scale_btn.setEnabled(not self.auto_scale)
        self.high_scale_btn.setEnabled(not self.auto_scale)
        
        # If switching back to auto-scale, update the plot
        if self.auto_scale:
            self.update_plot()
    
    def update_scale(self):
        # Read values from input fields
        try:
            if self.min_input.text():
                self.scale_min = float(self.min_input.text())
            else:
                self.scale_min = None
                
            if self.max_input.text():
                self.scale_max = float(self.max_input.text())
            else:
                self.scale_max = None
                
            # Validate min <= max
            if self.scale_min is not None and self.scale_max is not None:
                if self.scale_min > self.scale_max:
                    self.statusBar.showMessage("Error: Min value must be less than or equal to Max value")
                    return
            
            # Force plot update
            self.update_plot()
            
            # Update status message with actual values used
            if self.scale_min is not None and self.scale_max is not None:
                self.statusBar.showMessage(f"Scale updated: [{self.scale_min:.6g}, {self.scale_max:.6g}]")
            else:
                self.statusBar.showMessage("Scale updated to auto range")
        except ValueError:
            self.statusBar.showMessage("Error: Invalid scale values")
            
    def update_scale_inputs(self, vmin, vmax):
        # Update the scale input fields with current values
        # Called when loading a new variable
        if vmin is not None:
            self.min_input.setText(f"{vmin:.6g}")
        else:
            self.min_input.setText("")
            
        if vmax is not None:
            self.max_input.setText(f"{vmax:.6g}")
        else:
            self.max_input.setText("")
            
    def lower_scale(self):
        """Decrease both min and max scale values by 10%"""
        try:
            if self.min_input.text() and self.max_input.text():
                current_min = float(self.min_input.text())
                current_max = float(self.max_input.text())
                
                # Calculate range and adjustment
                value_range = current_max - current_min
                adjustment = value_range * 0.1
                
                # Apply adjustment
                new_min = current_min - adjustment
                new_max = current_max - adjustment
                
                # Update inputs
                self.min_input.setText(f"{new_min:.6g}")
                self.max_input.setText(f"{new_max:.6g}")
                
                # Store values directly to ensure they're used
                self.scale_min = new_min
                self.scale_max = new_max
                
                # Force plot update
                self.update_plot()
                self.statusBar.showMessage(f"Scale lowered: [{new_min:.6g}, {new_max:.6g}]")
        except ValueError:
            self.statusBar.showMessage("Error: Invalid scale values")
            
    def raise_scale(self):
        """Increase both min and max scale values by 10%"""
        try:
            if self.min_input.text() and self.max_input.text():
                current_min = float(self.min_input.text())
                current_max = float(self.max_input.text())
                
                # Calculate range and adjustment
                value_range = current_max - current_min
                adjustment = value_range * 0.1
                
                # Apply adjustment
                new_min = current_min + adjustment
                new_max = current_max + adjustment
                
                # Update inputs
                self.min_input.setText(f"{new_min:.6g}")
                self.max_input.setText(f"{new_max:.6g}")
                
                # Store values directly to ensure they're used
                self.scale_min = new_min
                self.scale_max = new_max
                
                # Force plot update
                self.update_plot()
                self.statusBar.showMessage(f"Scale raised: [{new_min:.6g}, {new_max:.6g}]")
        except ValueError:
            self.statusBar.showMessage("Error: Invalid scale values")
            
    def find_time_dimension(self):
        """Find the most likely time dimension in the current variable"""
        if self.dataset is None or self.current_variable is None:
            return None
            
        var_obj = self.dataset[self.current_variable]
        
        # If variable has fewer than 3 dimensions, there's no time dimension to navigate
        if len(var_obj.dims) < 3:
            return None
            
        # Look for dimension named 'time' or similar
        time_dim_names = ['time', 'TIME', 'Time', 't', 'T']
        for dim_name in var_obj.dims:
            if dim_name.lower() in [t.lower() for t in time_dim_names]:
                return dim_name
                
        # If no obvious time dimension, use the first dimension
        return var_obj.dims[0]
        
    def get_time_combo(self):
        """Get the time dimension combo box if available"""
        time_dim = self.find_time_dimension()
        if time_dim is None or time_dim not in self.dim_widgets:
            return None
            
        return self.dim_widgets[time_dim]['combo']
        
    def prev_timestep(self):
        """Navigate to the previous timestep"""
        time_combo = self.get_time_combo()
        if time_combo is None:
            self.statusBar.showMessage("No time dimension available")
            return
            
        # Get the time dimension name
        time_dim = self.find_time_dimension()
        
        current_idx = time_combo.currentIndex()
        if current_idx > 0:
            # Temporarily disconnect the signal to avoid double updates
            if time_dim in self.dim_widgets and 'update_function' in self.dim_widgets[time_dim]:
                try:
                    time_combo.currentIndexChanged.disconnect(self.dim_widgets[time_dim]['update_function'])
                except:
                    pass
                
            time_combo.setCurrentIndex(current_idx - 1)
            
            # Reconnect the signal
            if time_dim in self.dim_widgets and 'update_function' in self.dim_widgets[time_dim]:
                time_combo.currentIndexChanged.connect(self.dim_widgets[time_dim]['update_function'])
            
            # Force plot update
            self.update_plot()
            
            self.statusBar.showMessage(f"Time step: {time_combo.currentText()}")
        else:
            self.statusBar.showMessage("At first time step")
            
    def next_timestep(self):
        """Navigate to the next timestep"""
        time_combo = self.get_time_combo()
        if time_combo is None:
            self.statusBar.showMessage("No time dimension available")
            return
            
        # Get the time dimension name
        time_dim = self.find_time_dimension()
        
        current_idx = time_combo.currentIndex()
        if current_idx < time_combo.count() - 1:
            # Temporarily disconnect the signal to avoid double updates
            if time_dim in self.dim_widgets and 'update_function' in self.dim_widgets[time_dim]:
                try:
                    time_combo.currentIndexChanged.disconnect(self.dim_widgets[time_dim]['update_function'])
                except:
                    pass
                
            time_combo.setCurrentIndex(current_idx + 1)
            
            # Reconnect the signal
            if time_dim in self.dim_widgets and 'update_function' in self.dim_widgets[time_dim]:
                time_combo.currentIndexChanged.connect(self.dim_widgets[time_dim]['update_function'])
            
            # Force plot update
            self.update_plot()
            
            self.statusBar.showMessage(f"Time step: {time_combo.currentText()}")
        else:
            # Stop playing if we're at the end
            if self.play_timer.isActive():
                self.toggle_play(False)
            self.statusBar.showMessage("At last time step")
            
    def toggle_play(self, checked=None):
        """Start or stop the animation playback"""
        if checked is None:
            checked = self.play_btn.isChecked()
            
        if checked:
            time_combo = self.get_time_combo()
            if time_combo is None:
                self.statusBar.showMessage("No time dimension available")
                self.play_btn.setChecked(False)
                return
                
            # Start from the beginning if at the end
            if time_combo.currentIndex() == time_combo.count() - 1:
                time_combo.setCurrentIndex(0)
                
            self.play_timer.start(self.play_speed)
            self.play_btn.setText("■ Stop")
            self.statusBar.showMessage("Playing animation...")
        else:
            self.play_timer.stop()
            self.play_btn.setText("▶ Play")
            self.play_btn.setChecked(False)
            self.statusBar.showMessage("Animation stopped")
            
    def change_speed(self, value):
        """Change the animation playback speed"""
        self.play_speed = value
        if self.play_timer.isActive():
            self.play_timer.setInterval(value)
            self.statusBar.showMessage(f"Animation speed: {value}ms")
    
    def get_current_slice_indices(self):
        indices = {}
        if self.current_variable and self.dataset:
            var_obj = self.dataset[self.current_variable]
            dims = list(var_obj.dims)
            
            # If data has more than 2 dimensions
            if len(dims) > 2:
                # We're displaying the last two dimensions, so we need indices for all others
                select_dims = dims[:-2]  # All but the last two dimensions
                
                for dim_name in select_dims:
                    if dim_name in self.dim_widgets and self.dim_widgets[dim_name]['combo'] is not None:
                        combo = self.dim_widgets[dim_name]['combo']
                        text = combo.currentText()
                        # Extract the index from the text (format might be "0: value")
                        try:
                            if ":" in text:
                                index = int(text.split(":")[0])
                            else:
                                index = int(text)
                            indices[dim_name] = index
                        except ValueError:
                            indices[dim_name] = 0
            
        return indices
    
    def update_plot(self):
        if self.dataset is None or self.current_variable is None:
            return
        
        try:
            var_obj = self.dataset[self.current_variable]
            indices = self.get_current_slice_indices()
            
            # Apply slicing for dimensions > 2
            if indices:
                data = var_obj.isel(**indices)
            else:
                data = var_obj
            
            self.plot_data(data)
            self.statusBar.showMessage(f"Plotted {self.current_variable}")
        except Exception as e:
            self.statusBar.showMessage(f"Error plotting: {str(e)}")
    
    def plot_data(self, data):
        # Clear previous plots
        self.canvas.axes.clear()
        
        # Remove existing colorbar if it exists
        if self.canvas.colorbar is not None:
            self.canvas.colorbar.remove()
            self.canvas.colorbar = None
            
        # Get actual data values
        values = data.values
        
        # Plot based on dimensionality
        if data.ndim == 0:  # Scalar
            self.canvas.axes.text(0.5, 0.5, f"Value: {values}", 
                                 ha='center', va='center', fontsize=12)
        
        elif data.ndim == 1:  # 1D data
            x = np.arange(len(values))
            if hasattr(data, 'dims') and len(data.dims) == 1:
                x_dim = data.dims[0]
                if x_dim in data.coords:
                    x = data.coords[x_dim].values
            
            self.canvas.axes.plot(x, values, linewidth=2)
            
            # Labels
            if hasattr(data, 'dims') and len(data.dims) == 1:
                self.canvas.axes.set_xlabel(data.dims[0])
            
            # Try to add units if available
            if hasattr(data, 'attrs') and 'units' in data.attrs:
                self.canvas.axes.set_ylabel(f"{self.current_variable} ({data.attrs['units']})")
            else:
                self.canvas.axes.set_ylabel(self.current_variable)
                
            # Add grid for better readability
            self.canvas.axes.grid(True, linestyle='--', alpha=0.7)
        
        elif data.ndim == 2:  # 2D data
            # Check shape first
            if values.shape[0] == 0 or values.shape[1] == 0:
                self.canvas.axes.text(0.5, 0.5, "Empty data (one or more dimensions has size 0)",
                                    ha='center', va='center', fontsize=12)
                self.canvas.fig.tight_layout()
                self.canvas.draw()
                return
                
            # Handle NaN values and determine min/max for better color scaling
            valid_values = values[~np.isnan(values)] if np.any(np.isnan(values)) else values
            if len(valid_values) > 0:
                # Determine vmin and vmax based on auto_scale setting
                if self.auto_scale:
                    # Auto-calculate from data
                    vmin = np.min(valid_values)
                    vmax = np.max(valid_values)
                    
                    # Add padding to color range to avoid single-color plots
                    if vmin == vmax:
                        vmin = vmin - 0.1 if vmin != 0 else -0.1
                        vmax = vmax + 0.1 if vmax != 0 else 0.1
                    
                    # Update the scale input fields with auto values
                    self.update_scale_inputs(vmin, vmax)
                else:
                    # Use user-specified min/max if available
                    vmin = self.scale_min if self.scale_min is not None else np.min(valid_values)
                    vmax = self.scale_max if self.scale_max is not None else np.max(valid_values)
                    
                    # Add padding to color range to avoid single-color plots if only one value is set
                    if vmin == vmax:
                        vmin = vmin - 0.1 if vmin != 0 else -0.1
                        vmax = vmax + 0.1 if vmax != 0 else 0.1
                
                # Create heatmap with improved parameters
                im = self.canvas.axes.imshow(
                    values, 
                    cmap=self.current_cmap,
                    aspect='auto', 
                    origin='lower',
                    interpolation='nearest',
                    vmin=vmin,
                    vmax=vmax
                )
                
                # Add colorbar with more ticks
                self.canvas.colorbar = self.canvas.fig.colorbar(im, ax=self.canvas.axes)
                if hasattr(data, 'attrs') and 'units' in data.attrs:
                    self.canvas.colorbar.set_label(f"{data.attrs['units']}")
                
                # Add coordinate ticks if available
                if hasattr(data, 'dims') and len(data.dims) == 2:
                    # Make sure we get the dimensions in the right order
                    y_dim, x_dim = data.dims
                    
                    # If coordinates are available, use them for ticks
                    if x_dim in data.coords and y_dim in data.coords:
                        x_coords = data.coords[x_dim].values
                        y_coords = data.coords[y_dim].values
                        
                        # Determine a reasonable number of ticks based on data size
                        x_step = max(1, len(x_coords) // min(10, len(x_coords)))
                        y_step = max(1, len(y_coords) // min(10, len(y_coords)))
                        
                        # Set tick positions and labels
                        if len(x_coords) > 0:
                            x_ticks = np.arange(0, len(x_coords), x_step)
                            if len(x_ticks) > 0:
                                self.canvas.axes.set_xticks(x_ticks)
                                self.canvas.axes.set_xticklabels([f"{x_coords[i]:.2g}" for i in x_ticks])
                        
                        if len(y_coords) > 0:
                            y_ticks = np.arange(0, len(y_coords), y_step)
                            if len(y_ticks) > 0:
                                self.canvas.axes.set_yticks(y_ticks)
                                self.canvas.axes.set_yticklabels([f"{y_coords[i]:.2g}" for i in y_ticks])
                    
                    # Set axis labels
                    self.canvas.axes.set_xlabel(x_dim)
                    self.canvas.axes.set_ylabel(y_dim)
                
                # Add title with variable name and units if available
                var_name = self.current_variable
                if hasattr(data, 'attrs') and 'units' in data.attrs:
                    var_units = data.attrs['units']
                    self.canvas.axes.set_title(f"{var_name} ({var_units})")
                else:
                    self.canvas.axes.set_title(var_name)
            else:
                # Handle empty/all-NaN arrays
                self.canvas.axes.text(0.5, 0.5, "No valid data to display (all NaN)",
                                      ha='center', va='center', fontsize=12)
        
        else:  # Higher dimensions
            self.canvas.axes.text(0.5, 0.5, 
                                 "Data has more than 2 dimensions.\nUse dimension selectors to visualize slices.", 
                                 ha='center', va='center', fontsize=12)
        
        # Make sure the layout is tight and all labels are visible
        self.canvas.fig.tight_layout()
        
        # Force a complete redraw of the canvas
        self.canvas.fig.canvas.draw_idle()
        self.canvas.draw()
        self.canvas.flush_events()
    
    def save_plot(self):
        if self.dataset is None or self.current_variable is None:
            self.statusBar.showMessage("No plot to save")
            return
        
        file_path, _ = QFileDialog.getSaveFileName(
            self, "Save Plot", "", "PNG Files (*.png);;PDF Files (*.pdf);;All Files (*)"
        )
        
        if file_path:
            try:
                self.canvas.fig.savefig(file_path, dpi=300, bbox_inches='tight')
                self.statusBar.showMessage(f"Plot saved to {file_path}")
            except Exception as e:
                self.statusBar.showMessage(f"Error saving plot: {str(e)}")
    
    def closeEvent(self, event):
        # Stop any ongoing animation
        if self.play_timer.isActive():
            self.play_timer.stop()
            
        # Clean up resources
        if self.dataset is not None:
            self.dataset.close()
            
        event.accept()

if __name__ == "__main__":
    app = QApplication(sys.argv)
    app.setStyle('Fusion')  # Consistent style across platforms
    viewer = NetCDFViewer()
    viewer.show()
    sys.exit(app.exec())