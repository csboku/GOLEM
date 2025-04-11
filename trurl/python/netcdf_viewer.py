#!/usr/bin/env python3
import sys
import os
from PySide6.QtWidgets import (QApplication, QMainWindow, QFileDialog, QSplitter,
                              QVBoxLayout, QHBoxLayout, QWidget, QPushButton,
                              QLabel, QComboBox, QTextEdit, QStatusBar, QCheckBox,
                              QLineEdit, QFrame, QSlider)
from PySide6.QtCore import Qt, QTimer, Signal, Slot # Added Signal, Slot
from PySide6.QtGui import QDoubleValidator
import matplotlib
# matplotlib.use('Qt5Agg') # Removed explicit backend - let Matplotlib auto-detect
from matplotlib.backends.backend_qt5agg import FigureCanvasQTAgg as FigureCanvas
from matplotlib.figure import Figure
from matplotlib import cm
import numpy as np
import xarray as xr
# Optional: Import pandas for nicer datetime formatting in dimension dropdowns
try:
    import pandas as pd
except ImportError:
    pd = None # Handle case where pandas is not installed


class MatplotlibCanvas(FigureCanvas):
    def __init__(self, parent=None, width=5, height=4, dpi=100):
        self.fig = Figure(figsize=(width, height), dpi=dpi)
        self.axes = self.fig.add_subplot(111)
        self.colorbar = None  # Store reference to colorbar to remove it later
        super(MatplotlibCanvas, self).__init__(self.fig)

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
        self.play_timer = QTimer(self) # Added self as parent
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
        splitter = QSplitter(Qt.Orientation.Horizontal) # Use Qt.Orientation enum

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
        self.min_input.returnPressed.connect(self.update_scale) # Connect return press

        max_label = QLabel("Max:")
        self.max_input = QLineEdit()
        self.max_input.setValidator(QDoubleValidator())
        self.max_input.setEnabled(False)  # Initially disabled when auto-scale is on
        self.max_input.returnPressed.connect(self.update_scale) # Connect return press

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
        separator.setFrameShape(QFrame.Shape.HLine) # Use QFrame.Shape enum
        separator.setFrameShadow(QFrame.Shadow.Sunken) # Use QFrame.Shadow enum
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

        self.speed_slider = QSlider(Qt.Orientation.Horizontal) # Use Qt.Orientation enum
        self.speed_slider.setRange(100, 2000)  # 100ms to 2000ms
        self.speed_slider.setValue(self.play_speed)
        self.speed_slider.valueChanged.connect(self.change_speed)

        speed_layout.addWidget(speed_label)
        speed_layout.addWidget(self.speed_slider)

        left_layout.addLayout(speed_layout)

        # Add another separator
        separator2 = QFrame()
        separator2.setFrameShape(QFrame.Shape.HLine) # Use QFrame.Shape enum
        separator2.setFrameShadow(QFrame.Shadow.Sunken) # Use QFrame.Shadow enum
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

        # Set initial sizes (relative)
        # Defer setting sizes until window is shown or resized for better accuracy
        # splitter.setSizes([int(self.width() * 0.3), int(self.width() * 0.7)])

        main_layout.addWidget(splitter)
        self.setCentralWidget(main_widget)

        # Status bar
        self.statusBar = QStatusBar()
        self.setStatusBar(self.statusBar)
        self.statusBar.showMessage("Ready")

    # Override resizeEvent to adjust splitter sizes dynamically
    # def resizeEvent(self, event):
    #    super().resizeEvent(event)
    #    splitter = self.centralWidget().layout().itemAt(0).widget() # Find splitter
    #    if isinstance(splitter, QSplitter):
    #        total_width = splitter.width()
    #        # Prevent setting sizes before the widget is fully initialized
    #        if total_width > 0 and not splitter.sizes() or abs(sum(splitter.sizes()) - total_width) > 5:
    #             splitter.setSizes([int(total_width * 0.3), int(total_width * 0.7)])


    @Slot() # Decorate methods connected to signals with @Slot()
    def open_file(self):
        file_path, _ = QFileDialog.getOpenFileName(
            self, "Open NetCDF File", "", "NetCDF Files (*.nc *.nc4 *.cdf);;All Files (*)"
        )

        if file_path:
            try:
                self.statusBar.showMessage(f"Loading {os.path.basename(file_path)}...")
                QApplication.processEvents() # Allow UI to update

                # Close previous dataset if open
                if self.dataset:
                    self.dataset.close()
                    self.dataset = None

                self.dataset = xr.open_dataset(file_path)
                self.update_variable_list()
                self.update_metadata()
                # Automatically select the first variable if available
                if self.var_combo.count() > 0:
                    self.var_combo.setCurrentIndex(0)
                    # variable_selected will be triggered automatically by setCurrentIndex
                else:
                     self.clear_plot_and_selectors() # Clear if no variables found

                self.statusBar.showMessage(f"Loaded {os.path.basename(file_path)}")
            except Exception as e:
                self.statusBar.showMessage(f"Error loading file: {str(e)}")
                self.dataset = None
                self.clear_plot_and_selectors()

    def clear_plot_and_selectors(self):
        """Clears the plot area and dimension selectors."""
        self.var_combo.blockSignals(True)
        self.var_combo.clear()
        self.var_combo.blockSignals(False)
        self.clear_dimension_selectors()
        self.canvas.axes.clear()
        # FIX: Check if colorbar exists before removing
        if self.canvas.colorbar:
            try:
                self.canvas.colorbar.remove()
            except Exception as e:
                 print(f"Minor error removing old colorbar: {e}")
            self.canvas.colorbar = None
        self.canvas.draw()
        self.meta_text.clear()
        self.current_variable = None


    def update_variable_list(self):
        self.var_combo.blockSignals(True) # Block signals during update
        self.var_combo.clear()
        if self.dataset is not None:
            # Filter for variables with at least 1 dimension (can be plotted)
            plottable_vars = [
                var_name for var_name, var in self.dataset.data_vars.items()
                if var.ndim >= 1
            ]
            for var_name in plottable_vars:
                self.var_combo.addItem(var_name)
        self.var_combo.blockSignals(False) # Unblock signals

    def update_metadata(self):
        if self.dataset is not None:
            try:
                # FIX: Use .sizes instead of .dims for future xarray compatibility
                metadata = f"Dimensions (name: length):\n"
                if self.dataset.sizes:
                    for dim_name, dim_size in self.dataset.sizes.items():
                        metadata += f"  {dim_name}: {dim_size}\n"
                else:
                    metadata += "  (None)\n"

                metadata += f"\nCoordinates:\n"
                if self.dataset.coords:
                    for coord_name, coord_var in self.dataset.coords.items():
                         metadata += f"  {coord_name} ({coord_var.dtype}): {tuple(coord_var.dims)}\n"
                         if coord_var.attrs:
                             metadata += f"    Attributes:\n"
                             for attr_name, attr_val in coord_var.attrs.items():
                                 metadata += f"      {attr_name}: {attr_val}\n"
                else:
                     metadata += "  (None)\n"

                metadata += f"\nData Variables:\n"
                if self.dataset.data_vars:
                    for var_name, var in self.dataset.data_vars.items():
                        metadata += f"  {var_name} ({var.dtype}): {tuple(var.dims)}\n"
                        if var.attrs:
                            metadata += f"    Attributes:\n"
                            for attr_name, attr_val in var.attrs.items():
                                metadata += f"      {attr_name}: {attr_val}\n"
                else:
                     metadata += "  (None)\n"

                metadata += f"\nGlobal Attributes:\n"
                if self.dataset.attrs:
                     for attr_name, attr_val in self.dataset.attrs.items():
                         metadata += f"  {attr_name}: {attr_val}\n"
                else:
                     metadata += "  (None)\n"

                self.meta_text.setText(metadata)
            except Exception as e:
                 self.meta_text.setText(f"Error reading metadata: {e}")
                 print(f"Error reading metadata: {e}") # Also print to console
        else:
            self.meta_text.clear()

    def clear_dimension_selectors(self):
        # Clear existing dimension selectors more robustly
        while self.dim_layout.count():
            item = self.dim_layout.takeAt(0)
            widget = item.widget()
            if widget is not None:
                widget.deleteLater()
            else:
                # Handle nested layouts if any (though not expected here)
                layout_item = item.layout()
                if layout_item is not None:
                     # Simple clearing for now, add recursion if layouts get nested
                     while layout_item.count():
                          sub_item = layout_item.takeAt(0)
                          sub_widget = sub_item.widget()
                          if sub_widget:
                               sub_widget.deleteLater()
                     # Consider deleting the layout itself if appropriate
                     # layout_item.deleteLater() # Might cause issues if layout is managed elsewhere
        self.dim_widgets = {}

    def create_dimension_selectors(self, var_obj):
        self.clear_dimension_selectors()

        # Use .sizes here as well for consistency
        dims = list(var_obj.dims)
        sizes = var_obj.sizes # Get dimension sizes

        # Handle scalar data (0 dimensions) - shouldn't happen if filtered in update_variable_list
        if len(dims) == 0:
             label = QLabel("Scalar data (single value)")
             self.dim_layout.addWidget(label)
             self.dim_widgets['info'] = {'label': label, 'combo': None}
             return

        # For 1D data, show dimension info
        if len(dims) == 1:
            label = QLabel(f"Displaying 1D data (dim: {dims[0]}, size: {sizes[dims[0]]})")
            self.dim_layout.addWidget(label)
            self.dim_widgets['info'] = {'label': label, 'combo': None}
            return

        # For 2D data, show dimension info
        if len(dims) == 2:
            label = QLabel(f"Displaying 2D data (dims: {dims[0]}[{sizes[dims[0]]}] vs {dims[1]}[{sizes[dims[1]]}])")
            self.dim_layout.addWidget(label)
            self.dim_widgets['info'] = {'label': label, 'combo': None}
            return

        # For 3D+ data: Select last two for display, create selectors for others
        display_dims = dims[-2:]
        select_dims = dims[:-2]

        info_label = QLabel(f"Displaying: {display_dims[1]} (x) vs {display_dims[0]} (y)") # Clarify x/y
        self.dim_layout.addWidget(info_label)
        self.dim_widgets['info'] = {'label': info_label, 'combo': None}

        spacer_label = QLabel("Select indices for other dimensions:") # More descriptive
        self.dim_layout.addWidget(spacer_label)
        self.dim_widgets['spacer'] = {'label': spacer_label, 'combo': None}

        for dim_name in select_dims:
            dim_size = sizes[dim_name] # Use sizes dict

            label = QLabel(f"Select {dim_name} (size {dim_size}):")
            combo = QComboBox()

            items = [] # Build list of items first
            if dim_name in var_obj.coords:
                coord_values = var_obj.coords[dim_name].values
                # Try formatting coordinate values nicely
                try:
                    # Check if numpy datetime64 or similar
                    if np.issubdtype(coord_values.dtype, np.datetime64) or \
                       np.issubdtype(coord_values.dtype, np.timedelta64):
                         # Use pandas for robust datetime formatting if available
                         if pd:
                              items = [f"{i}: {str(pd.Timestamp(val))}" for i, val in enumerate(coord_values)]
                         else: # Fallback to numpy's string representation
                              items = [f"{i}: {val}" for i, val in enumerate(coord_values)]
                    elif np.issubdtype(coord_values.dtype, np.number):
                         items = [f"{i}: {val:.3g}" for i, val in enumerate(coord_values)] # Format numbers
                    else: # General case (strings, objects, etc.)
                         items = [f"{i}: {val}" for i, val in enumerate(coord_values)]
                except Exception as fmt_err: # Fallback if formatting fails
                    print(f"Warning: Could not format coordinates for {dim_name}: {fmt_err}")
                    items = [f"{i}" for i in range(dim_size)]
            else: # No coordinates, just show indices
                items = [f"{i}" for i in range(dim_size)]

            # Add items to combo box
            combo.addItems(items)

            self.dim_layout.addWidget(label)
            self.dim_layout.addWidget(combo)

            # Connect signal AFTER populating the combo
            combo.currentIndexChanged.connect(self.update_plot)

            self.dim_widgets[dim_name] = {'label': label, 'combo': combo}

    @Slot()
    def variable_selected(self):
        # This slot is triggered by var_combo.currentIndexChanged
        if self.dataset is None or self.var_combo.currentIndex() < 0: # Check for valid index
            # Don't clear plot here, might be intermediate state during file load
            # self.clear_plot_and_selectors()
            return

        var_name = self.var_combo.currentText()
        # Check if variable actually changed and is valid
        if var_name and var_name in self.dataset.data_vars and var_name != self.current_variable:
            self.current_variable = var_name
            var_obj = self.dataset[self.current_variable]

            # Reset scale only if auto-scale is on
            if self.auto_scale:
                self.scale_min = None
                self.scale_max = None
                self.min_input.setText("")
                self.max_input.setText("")

            self.create_dimension_selectors(var_obj)
            self.update_plot() # Plot the newly selected variable

    @Slot(str)
    def colormap_changed(self, cmap_name):
        if cmap_name != self.current_cmap:
            self.current_cmap = cmap_name
            # Only update plot if a variable is actually selected and plotted
            if self.current_variable and self.dataset and self.canvas.axes.has_data():
                self.update_plot()

    @Slot(int)
    def toggle_auto_scale(self, state):
        # Use Qt.CheckState enum directly for comparison
        is_checked = (Qt.CheckState(state) == Qt.CheckState.Checked)
        self.auto_scale = is_checked

        # Enable/disable manual controls
        manual_enabled = not self.auto_scale
        self.min_input.setEnabled(manual_enabled)
        self.max_input.setEnabled(manual_enabled)
        self.apply_scale_btn.setEnabled(manual_enabled)
        self.low_scale_btn.setEnabled(manual_enabled)
        self.high_scale_btn.setEnabled(manual_enabled)

        # If switching back to auto-scale, reset and update plot
        if self.auto_scale:
            self.scale_min = None
            self.scale_max = None
            # Clear inputs visually
            self.min_input.setText("")
            self.max_input.setText("")
            if self.current_variable: # Only update if a variable is loaded
                 self.update_plot()

    @Slot()
    def update_scale(self):
        # Called by Apply button or Enter press in min/max fields
        if self.auto_scale: # Should not happen if UI is correct, but safety check
            return

        try:
            new_min_text = self.min_input.text().strip()
            new_max_text = self.max_input.text().strip()

            new_min = float(new_min_text) if new_min_text else None
            new_max = float(new_max_text) if new_max_text else None

            # Validate min <= max if both are set
            if new_min is not None and new_max is not None and new_min > new_max:
                self.statusBar.showMessage("Error: Min scale must be less than or equal to Max scale")
                # Optionally revert inputs to previous valid state or clear them
                self.update_scale_inputs(self.scale_min, self.scale_max) # Revert
                return

            # Update internal state only if values changed
            if new_min != self.scale_min or new_max != self.scale_max:
                 self.scale_min = new_min
                 self.scale_max = new_max

                 # Update plot if a variable is loaded
                 if self.current_variable:
                     self.update_plot()
                     if self.scale_min is not None or self.scale_max is not None:
                          min_str = f"{self.scale_min:.6g}" if self.scale_min is not None else "auto"
                          max_str = f"{self.scale_max:.6g}" if self.scale_max is not None else "auto"
                          self.statusBar.showMessage(f"Manual scale applied: [{min_str}, {max_str}]")
                     else: # Both empty means auto again effectively, though auto_scale checkbox is off
                          self.statusBar.showMessage("Scale range cleared (effectively auto)")
                 else:
                      self.statusBar.showMessage("Set scale values (apply when data is loaded)")
            # else: # No change in values
            #      self.statusBar.showMessage("Scale values unchanged")


        except ValueError:
            self.statusBar.showMessage("Error: Invalid number format in scale inputs")
            # Optionally revert inputs
            self.update_scale_inputs(self.scale_min, self.scale_max) # Revert

    def update_scale_inputs(self, vmin, vmax):
        """Update the min/max QLineEdit widgets with formatted values."""
        # Block signals temporarily to prevent update_scale from re-triggering if connected to textChanged
        self.min_input.blockSignals(True)
        self.max_input.blockSignals(True)

        self.min_input.setText(f"{vmin:.6g}" if vmin is not None else "")
        self.max_input.setText(f"{vmax:.6g}" if vmax is not None else "")

        self.min_input.blockSignals(False)
        self.max_input.blockSignals(False)


    @Slot()
    def lower_scale(self):
        """Decrease both min and max scale values by 10% of the current range."""
        if self.auto_scale: return # Should be disabled anyway
        try:
            current_min_text = self.min_input.text().strip()
            current_max_text = self.max_input.text().strip()

            # Need valid numbers in both fields to calculate range
            if current_min_text and current_max_text:
                current_min = float(current_min_text)
                current_max = float(current_max_text)

                if current_min >= current_max:
                     self.statusBar.showMessage("Cannot lower scale: Min >= Max")
                     return

                value_range = current_max - current_min
                # Ensure adjustment is non-zero, handle potential floating point issues
                adjustment = max(value_range * 0.1, 1e-9) if value_range > 1e-9 else 0.1

                new_min = current_min - adjustment
                new_max = current_max - adjustment

                # Update internal state FIRST
                self.scale_min = new_min
                self.scale_max = new_max

                # Update UI fields
                self.update_scale_inputs(new_min, new_max)

                # Update plot
                if self.current_variable:
                     self.update_plot()
                     self.statusBar.showMessage(f"Scale lowered: [{new_min:.6g}, {new_max:.6g}]")
            else:
                self.statusBar.showMessage("Cannot lower scale: Both Min and Max must be set")

        except ValueError:
            self.statusBar.showMessage("Error: Invalid scale values for lowering")
            self.update_scale_inputs(self.scale_min, self.scale_max) # Revert on error

    @Slot()
    def raise_scale(self):
        """Increase both min and max scale values by 10% of the current range."""
        if self.auto_scale: return # Should be disabled anyway
        try:
            current_min_text = self.min_input.text().strip()
            current_max_text = self.max_input.text().strip()

            # Need valid numbers in both fields to calculate range
            if current_min_text and current_max_text:
                current_min = float(current_min_text)
                current_max = float(current_max_text)

                if current_min >= current_max:
                     self.statusBar.showMessage("Cannot raise scale: Min >= Max")
                     return

                value_range = current_max - current_min
                # Ensure adjustment is non-zero
                adjustment = max(value_range * 0.1, 1e-9) if value_range > 1e-9 else 0.1

                new_min = current_min + adjustment
                new_max = current_max + adjustment

                # Update internal state FIRST
                self.scale_min = new_min
                self.scale_max = new_max

                # Update UI fields
                self.update_scale_inputs(new_min, new_max)

                # Update plot
                if self.current_variable:
                     self.update_plot()
                     self.statusBar.showMessage(f"Scale raised: [{new_min:.6g}, {new_max:.6g}]")
            else:
                 self.statusBar.showMessage("Cannot raise scale: Both Min and Max must be set")

        except ValueError:
            self.statusBar.showMessage("Error: Invalid scale values for raising")
            self.update_scale_inputs(self.scale_min, self.scale_max) # Revert on error

    def find_time_dimension(self):
        """Find the most likely time dimension among the sliceable dimensions."""
        if self.dataset is None or self.current_variable is None:
            return None

        var_obj = self.dataset[self.current_variable]
        dims = list(var_obj.dims)

        # Only look for time dimension if we have > 2 dims (i.e., sliceable dims exist)
        if len(dims) <= 2:
            return None

        select_dims = dims[:-2] # Dimensions available for slicing

        # Prioritize standard names within the sliceable dimensions
        time_dim_names_prio = ['time', 'Time', 'datetime', 'date']
        time_dim_names_lower = ['t']

        for dim_name in select_dims:
            if dim_name in time_dim_names_prio:
                return dim_name
        for dim_name in select_dims:
             if dim_name.lower() in time_dim_names_lower:
                 return dim_name

        # Fallback: If a coordinate associated with a sliceable dimension is datetime-like
        for dim_name in select_dims:
            if dim_name in var_obj.coords:
                 coord_dtype = var_obj.coords[dim_name].dtype
                 if np.issubdtype(coord_dtype, np.datetime64) or \
                    np.issubdtype(coord_dtype, np.timedelta64):
                     return dim_name

        # Fallback: Use the first sliceable dimension if no better candidate found
        if select_dims:
             # print(f"Warning: Using first sliceable dimension '{select_dims[0]}' as time dimension.")
             return select_dims[0]

        return None # No suitable time dimension found among sliceable dimensions

    def get_time_combo(self):
        """Get the combo box associated with the identified time dimension."""
        # Don't cache self.time_dimension, find it each time in case variable changes
        time_dim = self.find_time_dimension()
        if time_dim and time_dim in self.dim_widgets:
            return self.dim_widgets[time_dim]['combo']
        return None

    @Slot()
    def prev_timestep(self):
        """Navigate to the previous timestep using the identified time dimension."""
        time_combo = self.get_time_combo()
        if time_combo is None:
            self.statusBar.showMessage("No suitable time dimension found for navigation")
            return

        current_idx = time_combo.currentIndex()
        if current_idx > 0:
            new_idx = current_idx - 1

            # Use blockSignals for robustness
            time_combo.blockSignals(True)
            time_combo.setCurrentIndex(new_idx)
            time_combo.blockSignals(False)

            # Manually trigger plot update
            self.update_plot()
            self.statusBar.showMessage(f"Time step: {time_combo.itemText(new_idx)}") # Show text of new index
        else:
            self.statusBar.showMessage("Already at the first time step")
            # Optionally stop playback if playing
            if self.play_timer.isActive():
                self.toggle_play(False) # Stop playback

    @Slot()
    def next_timestep(self):
        """Navigate to the next timestep. Called by button or timer."""
        time_combo = self.get_time_combo()
        if time_combo is None:
            if not self.play_timer.isActive(): # Don't show message repeatedly during playback
                 self.statusBar.showMessage("No suitable time dimension found for navigation")
            # Stop playback if active but no time dim found
            if self.play_timer.isActive():
                 self.toggle_play(False)
            return

        current_idx = time_combo.currentIndex()
        if current_idx < time_combo.count() - 1:
            new_idx = current_idx + 1

            # Use blockSignals for robustness
            time_combo.blockSignals(True)
            time_combo.setCurrentIndex(new_idx)
            time_combo.blockSignals(False)

            # Manually trigger plot update
            self.update_plot()
            self.statusBar.showMessage(f"Time step: {time_combo.itemText(new_idx)}")
        else:
            # If timer is running, loop back to the beginning
            if self.play_timer.isActive():
                 new_idx = 0
                 time_combo.blockSignals(True)
                 time_combo.setCurrentIndex(new_idx)
                 time_combo.blockSignals(False)
                 self.update_plot()
                 self.statusBar.showMessage(f"Time step: {time_combo.itemText(new_idx)} (Looped)")
            else: # Manual navigation stopped at the end
                 self.statusBar.showMessage("Reached the last time step")
                 # Stop playing button state if we're at the end
                 if self.play_btn.isChecked():
                      self.toggle_play(False) # Pass False to ensure it stops

    @Slot(bool)
    def toggle_play(self, checked):
        """Start or stop the animation playback."""
        time_combo = self.get_time_combo() # Check if time dim exists

        if checked and time_combo: # Start playing only if checked and time_dim exists
            # Start from the beginning if currently at the end (optional, handled by loop in next_timestep now)
            # if time_combo.currentIndex() == time_combo.count() - 1:
            #     time_combo.blockSignals(True)
            #     time_combo.setCurrentIndex(0)
            #     time_combo.blockSignals(False)
            #     self.update_plot() # Update plot to show first frame
            #     QApplication.processEvents() # Ensure UI updates before timer starts

            self.play_timer.start(self.play_speed)
            self.play_btn.setText("■ Stop")
            self.statusBar.showMessage(f"Playing animation... (Speed: {self.play_speed}ms)")

        else: # Stop playing (or if time_combo is None)
            self.play_timer.stop()
            self.play_btn.setText("▶ Play")
            # Crucially, uncheck the button state if stopped manually or due to error/end
            self.play_btn.setChecked(False)
            if self.statusBar.currentMessage().startswith("Playing"): # Avoid overwriting other messages
                 self.statusBar.showMessage("Animation stopped")

    @Slot(int)
    def change_speed(self, value):
        """Change the animation playback speed."""
        self.play_speed = value
        if self.play_timer.isActive():
            self.play_timer.setInterval(value) # Update interval immediately
            self.statusBar.showMessage(f"Playing animation... (Speed: {value}ms)")
        # else: # Optionally show speed even when stopped
        #     self.statusBar.showMessage(f"Animation speed set to: {value}ms")

    def get_current_slice_indices(self):
        """Get dimension indices dictionary based on current combo box selections."""
        indices = {}
        if self.current_variable and self.dataset:
            var_obj = self.dataset[self.current_variable]
            dims = list(var_obj.dims)

            if len(dims) > 2:
                select_dims = dims[:-2]
                for dim_name in select_dims:
                    if dim_name in self.dim_widgets and self.dim_widgets[dim_name]['combo']:
                        combo = self.dim_widgets[dim_name]['combo']
                        # Use currentIndex() directly - safer than parsing text
                        indices[dim_name] = combo.currentIndex()
                    else:
                         # Should not happen if UI is built correctly, but fallback
                         indices[dim_name] = 0
                         print(f"Warning: Could not find combo box for dimension '{dim_name}'. Defaulting to index 0.")
        return indices

    @Slot() # Make update_plot a slot in case it needs direct connection elsewhere
    def update_plot(self):
        """Fetches the appropriate data slice and calls plot_data."""
        if self.dataset is None or self.current_variable is None:
            # Clear plot if no data/variable selected
            self.canvas.axes.clear()
            # FIX: Check if colorbar exists before removing
            if self.canvas.colorbar:
                 try: self.canvas.colorbar.remove()
                 except Exception as e: print(f"Minor error removing colorbar: {e}")
                 self.canvas.colorbar = None
            self.canvas.draw()
            return

        try:
            var_obj = self.dataset[self.current_variable]
            indices = self.get_current_slice_indices()

            # Select data based on indices
            if indices:
                # Check if indices are valid before slicing
                valid_indices = True
                for dim, index in indices.items():
                     if not (0 <= index < var_obj.sizes[dim]):
                          self.statusBar.showMessage(f"Error: Index {index} out of bounds for dimension {dim} (size {var_obj.sizes[dim]})")
                          valid_indices = False
                          break
                if not valid_indices:
                     # Optionally clear plot or show error message on plot
                     self.canvas.axes.clear()
                     if self.canvas.colorbar: self.canvas.colorbar.remove(); self.canvas.colorbar = None
                     self.canvas.axes.text(0.5, 0.5, "Invalid slice index", ha='center', va='center', color='red')
                     self.canvas.draw()
                     return

                data_slice = var_obj.isel(**indices)
            else: # 0D, 1D or 2D data, no slicing needed from combos
                data_slice = var_obj

            # Perform plotting
            self.plot_data(data_slice)

            # Update status bar (optional, can be verbose)
            # slice_info = ", ".join([f"{k}={v}" for k,v in indices.items()])
            # self.statusBar.showMessage(f"Plotted {self.current_variable} [{slice_info}]")

        except Exception as e:
            self.statusBar.showMessage(f"Error plotting {self.current_variable}: {str(e)}")
            # Optionally clear the plot on error
            self.canvas.axes.clear()
            if self.canvas.colorbar: self.canvas.colorbar.remove(); self.canvas.colorbar = None
            self.canvas.axes.text(0.5, 0.5, f"Error plotting:\n{e}", ha='center', va='center', color='red', wrap=True)
            self.canvas.draw()
            print(f"Detailed Plotting Error: {e}", file=sys.stderr) # Print details to stderr


    def plot_data(self, data_array):
        """Plots the given xarray DataArray onto the Matplotlib canvas."""
        self.canvas.axes.clear()
        # FIX: Check if colorbar exists before removing
        if self.canvas.colorbar is not None:
            try:
                self.canvas.colorbar.remove()
            except Exception as e:
                 # This error is usually harmless if the figure is being cleared anyway
                 # print(f"Minor error removing old colorbar: {e}")
                 pass
            self.canvas.colorbar = None

        values = data_array.values # Get numpy array
        plot_title = self.current_variable # Default title

        # --- Plotting based on dimensionality ---
        if data_array.ndim == 0: # Scalar
            val_str = f"{values:.4g}" if np.issubdtype(values.dtype, np.number) else str(values)
            self.canvas.axes.text(0.5, 0.5, f"Value: {val_str}",
                                 ha='center', va='center', fontsize=12)
            plot_title += " (Scalar)"

        elif data_array.ndim == 1: # 1D data (Line plot)
            x_coords = None
            x_label = "Index"
            # Use .sizes for dimension length check
            dim_name = data_array.dims[0]
            dim_size = data_array.sizes[dim_name]

            if dim_name in data_array.coords:
                 coords = data_array.coords[dim_name]
                 # Check if coordinate length matches data length
                 if coords.size == dim_size:
                      x_coords = coords.values
                      x_label = dim_name
                      # Check if x_coords are numeric or datetime-like for plotting
                      if not (np.issubdtype(x_coords.dtype, np.number) or \
                              np.issubdtype(x_coords.dtype, np.datetime64) or \
                              np.issubdtype(x_coords.dtype, np.timedelta64)):
                           x_coords = np.arange(dim_size) # Fallback to index if coords aren't plottable
                           x_label = f"{x_label} (Index)"
                 else:
                      print(f"Warning: Coordinate '{dim_name}' length ({coords.size}) != Data length ({dim_size}). Using index.")
                      x_coords = np.arange(dim_size)
            else:
                 x_coords = np.arange(dim_size) # Default to index if no coords

            self.canvas.axes.plot(x_coords, values, marker='.', linestyle='-') # Add markers
            self.canvas.axes.set_xlabel(x_label)

            y_label = self.current_variable
            if 'units' in data_array.attrs:
                y_label += f" ({data_array.attrs['units']})"
            self.canvas.axes.set_ylabel(y_label)

            self.canvas.axes.grid(True, linestyle='--', alpha=0.6)
            plot_title += " (1D Plot)"

        elif data_array.ndim == 2: # 2D data (Heatmap)
            # Use .sizes here too
            if data_array.sizes[data_array.dims[0]] == 0 or data_array.sizes[data_array.dims[1]] == 0:
                self.canvas.axes.text(0.5, 0.5, "Empty data slice (dimension size is 0)",
                                    ha='center', va='center', fontsize=12)
                plot_title += " (Empty Slice)"
            else:
                # Handle NaN values for scaling
                valid_values = values[~np.isnan(values)]

                if len(valid_values) == 0:
                     self.canvas.axes.text(0.5, 0.5, "Data slice contains only NaN values",
                                         ha='center', va='center', fontsize=12)
                     plot_title += " (All NaN)"
                else:
                    # Determine vmin and vmax
                    vmin = None
                    vmax = None
                    if self.auto_scale:
                        vmin = np.min(valid_values)
                        vmax = np.max(valid_values)
                        # Update inputs only if auto-scaling determined new values
                        # Check if the inputs need updating to avoid redundant signals
                        current_min_text = self.min_input.text().strip()
                        current_max_text = self.max_input.text().strip()
                        try:
                             needs_update = (not current_min_text or float(current_min_text) != vmin or
                                             not current_max_text or float(current_max_text) != vmax)
                        except ValueError:
                             needs_update = True # Update if current text is invalid

                        if needs_update:
                             self.update_scale_inputs(vmin, vmax)
                    else: # Manual scale
                        vmin = self.scale_min # Use stored values (can be None)
                        vmax = self.scale_max

                    # If vmin/vmax still None (e.g. manual scale fields were empty), calculate from data
                    calc_vmin = np.min(valid_values)
                    calc_vmax = np.max(valid_values)
                    if vmin is None: vmin = calc_vmin
                    if vmax is None: vmax = calc_vmax

                    # Ensure vmin <= vmax after potentially mixing manual/auto
                    if vmin > vmax:
                         vmin, vmax = vmax, vmin # Swap them

                    # Add padding if range is zero or very small
                    if np.isclose(vmin, vmax):
                        padding = abs(vmin * 0.05) if not np.isclose(vmin, 0) else 0.1 # 5% relative padding or 0.1
                        vmin -= padding
                        vmax += padding

                    # --- Create the heatmap ---
                    im = self.canvas.axes.imshow(
                        values,
                        cmap=self.current_cmap,
                        aspect='auto',
                        origin='lower', # Common for atmospheric data (lat increases upwards)
                        interpolation='nearest', # Good default for data grids
                        vmin=vmin,
                        vmax=vmax
                    )

                    # --- Add Colorbar ---
                    self.canvas.colorbar = self.canvas.fig.colorbar(im, ax=self.canvas.axes, shrink=0.8, aspect=30) # Adjust size/aspect
                    cbar_label = self.current_variable
                    if 'units' in data_array.attrs:
                        cbar_label = f"{data_array.attrs['units']}"
                    self.canvas.colorbar.set_label(cbar_label)

                    # --- Add Coordinate Ticks/Labels ---
                    y_dim, x_dim = data_array.dims # imshow plots (y, x)
                    x_coords = None
                    y_coords = None
                    x_label = x_dim
                    y_label = y_dim

                    # Use .sizes for shape info
                    y_size = data_array.sizes[y_dim]
                    x_size = data_array.sizes[x_dim]

                    num_x_ticks = 8 # Max number of ticks
                    num_y_ticks = 8

                    extent = [0 - 0.5, x_size - 0.5, 0 - 0.5, y_size - 0.5] # Default extent for indices

                    if x_dim in data_array.coords:
                         coords = data_array.coords[x_dim]
                         if coords.size == x_size:
                              x_coords = coords.values
                              # Use coords for extent if numeric and monotonic
                              if np.issubdtype(x_coords.dtype, np.number) and len(x_coords) > 1:
                                   dx = np.diff(x_coords)
                                   if np.all(dx > 0) or np.all(dx < 0): # Check monotonicity
                                        # Adjust extent to center pixels on coordinate values
                                        dx_half = dx[0] / 2.0
                                        extent[0] = x_coords[0] - dx_half
                                        extent[1] = x_coords[-1] + dx_half

                    if y_dim in data_array.coords:
                         coords = data_array.coords[y_dim]
                         if coords.size == y_size:
                              y_coords = coords.values
                              if np.issubdtype(y_coords.dtype, np.number) and len(y_coords) > 1:
                                   dy = np.diff(y_coords)
                                   if np.all(dy > 0) or np.all(dy < 0):
                                        dy_half = dy[0] / 2.0
                                        extent[2] = y_coords[0] - dy_half
                                        extent[3] = y_coords[-1] + dy_half

                    im.set_extent(extent) # Apply extent

                    # Set labels regardless of coords
                    self.canvas.axes.set_xlabel(x_label)
                    self.canvas.axes.set_ylabel(y_label)

                    # Add ticks based on coordinates or indices
                    if x_coords is not None and x_size > 1:
                         step = max(1, x_size // num_x_ticks)
                         tick_indices = np.arange(x_size)[::step]
                         # Tick positions should be the coordinate values
                         tick_positions = x_coords[tick_indices]
                         self.canvas.axes.set_xticks(tick_positions)
                         # Format labels nicely
                         labels = [f"{x_coords[i]:.2g}" if np.issubdtype(x_coords.dtype, np.number) else str(x_coords[i]) for i in tick_indices]
                         self.canvas.axes.set_xticklabels(labels, rotation=45, ha='right') # Rotate labels
                    else: # Fallback to index ticks (positions are 0, 1, 2...)
                         step = max(1, x_size // num_x_ticks)
                         tick_positions = np.arange(x_size)[::step]
                         self.canvas.axes.set_xticks(tick_positions)
                         self.canvas.axes.set_xticklabels([str(i) for i in tick_positions])


                    if y_coords is not None and y_size > 1:
                         step = max(1, y_size // num_y_ticks)
                         tick_indices = np.arange(y_size)[::step]
                         tick_positions = y_coords[tick_indices]
                         self.canvas.axes.set_yticks(tick_positions)
                         labels = [f"{y_coords[i]:.2g}" if np.issubdtype(y_coords.dtype, np.number) else str(y_coords[i]) for i in tick_indices]
                         self.canvas.axes.set_yticklabels(labels)
                    else: # Fallback to index ticks
                         step = max(1, y_size // num_y_ticks)
                         tick_positions = np.arange(y_size)[::step]
                         self.canvas.axes.set_yticks(tick_positions)
                         self.canvas.axes.set_yticklabels([str(i) for i in tick_positions])

                    plot_title += " (2D Plot)" # Base title

        else:  # Should not happen for > 2D as we slice first, but fallback
            self.canvas.axes.text(0.5, 0.5,
                                 f"Data has {data_array.ndim} dimensions.\nCannot visualize directly.",
                                 ha='center', va='center', fontsize=12)
            plot_title = f"{self.current_variable} ({data_array.ndim}D Data)"

        # --- Final Touches ---
        # Add title including slice info if applicable
        slice_indices = self.get_current_slice_indices()
        if slice_indices:
             slice_str = ", ".join([f"{k}={v}" for k, v in slice_indices.items()])
             plot_title += f"\nSlice: [{slice_str}]"
        self.canvas.axes.set_title(plot_title, fontsize=10) # Smaller font for title

        try:
            # Adjust layout to prevent labels overlapping
            # Use constrained_layout if available and suitable, otherwise tight_layout
            if hasattr(self.canvas.fig, 'set_constrained_layout'):
                 self.canvas.fig.set_constrained_layout(True)
            else:
                 self.canvas.fig.tight_layout(rect=[0, 0.03, 1, 0.95]) # Add slight margin adjustments
        except Exception as layout_err:
             print(f"Warning: Plot layout adjustment failed: {layout_err}") # Non-critical error

        # Force redraw
        self.canvas.draw_idle() # Use draw_idle for better responsiveness

    @Slot()
    def save_plot(self):
        if self.dataset is None or self.current_variable is None or not self.canvas.axes.has_data():
            self.statusBar.showMessage("No plot to save")
            return

        # Suggest a filename based on variable and slice
        base_name = self.current_variable
        indices = self.get_current_slice_indices()
        if indices:
             slice_suffix = "_".join([f"{k}{v}" for k, v in indices.items()])
             base_name += f"_{slice_suffix}"
        base_name = base_name.replace('/','_') # Replace invalid chars
        base_name += ".png" # Default extension

        file_path, selected_filter = QFileDialog.getSaveFileName(
            self, "Save Plot", base_name,
            "PNG Files (*.png);;PDF Files (*.pdf);;JPEG Files (*.jpg *.jpeg);;SVG Files (*.svg);;All Files (*)"
        )

        if file_path:
            try:
                # Ensure directory exists if it's new
                dir_name = os.path.dirname(file_path)
                if dir_name: # Only create if path includes a directory
                     os.makedirs(dir_name, exist_ok=True)

                # Save with high DPI and tight bounding box
                self.canvas.fig.savefig(file_path, dpi=300, bbox_inches='tight')
                self.statusBar.showMessage(f"Plot saved to {os.path.basename(file_path)}")
            except Exception as e:
                self.statusBar.showMessage(f"Error saving plot: {str(e)}")
                print(f"Detailed Save Error: {e}", file=sys.stderr)


    def closeEvent(self, event):
        # Stop animation timer
        self.play_timer.stop()

        # Clean up dataset resources
        if self.dataset is not None:
            try:
                self.dataset.close()
                print("Dataset closed.") # Optional confirmation
            except Exception as e:
                 print(f"Error closing dataset: {e}") # Log error

        event.accept() # Accept the close event

if __name__ == "__main__":
    # Handle high DPI scaling - Deprecated but might still be needed on some systems
    # Check Qt docs for current best practice (e.g., environment variables QT_AUTO_SCREEN_SCALE_FACTOR=1)
    try:
        QApplication.setAttribute(Qt.AA_EnableHighDpiScaling, True)
    except AttributeError: # Handle if attribute is removed
        print("Warning: Qt.AA_EnableHighDpiScaling is deprecated/removed.")
    try:
        QApplication.setAttribute(Qt.AA_UseHighDpiPixmaps, True)
    except AttributeError:
        print("Warning: Qt.AA_UseHighDpiPixmaps is deprecated/removed.")


    app = QApplication(sys.argv)
    app.setStyle('Fusion') # Fusion style generally looks consistent

    viewer = NetCDFViewer()
    viewer.show()

    sys.exit(app.exec())
