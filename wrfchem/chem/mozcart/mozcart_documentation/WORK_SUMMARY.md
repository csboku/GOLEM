# MOZCART Chemical Mechanism Documentation Project

## Overview
This document summarizes the comprehensive analysis and documentation of the MOZART-GEOS5 Chemical Mechanism (MOZCART) implemented in KPP (Kinetic PreProcessor) format.

## Project Workflow

### 1. Initial Analysis
- **Explored directory structure** of `/home/cschmidt/git/GOLEM/wrfchem/chem/mozcart/`
- **Identified key files**:
  - `mozcart.def` - Main definition file with Fortran 90 inline functions
  - `mozcart.spc` - Species definitions (83 variable species, 2 fixed species)
  - `mozcart.eqn` - Chemical reactions (197 total reactions)
  - `atoms_red` - Atomic definitions for all elements
  - `mozcart.kpp` - Main KPP mechanism file
  - `mozcart.tuv.jmap` - Photolysis rate mapping
  - `mozcart_wrfkpp.equiv` - WRF-Chem species mapping

### 2. File Content Analysis

#### Species Analysis (`mozcart.spc`)
- **83 variable species** marked with `IGNORE` flag
- **2 fixed species**: H2O (water) and M (air density)
- Species categories identified:
  - Inorganic radicals (O, OH, HO2, O1D_CB4)
  - Nitrogen oxides (NO, NO2, NO3, HNO3, N2O5, etc.)
  - Hydrocarbons (CH4, C2H4, C2H6, C3H6, C3H8, etc.)
  - Peroxy radicals (CH3O2, C2H5O2, PO2, ISOPO2, etc.)
  - Aldehydes and ketones (CH2O, CH3CHO, CH3COCH3, etc.)
  - Biogenic VOCs (ISOP, C10H16)
  - Aromatics (TOLUENE, CRESOL)
  - Sulfur compounds (DMS, SO2, SO4)
  - Organic nitrates (PAN, MPAN, ONIT, ONITR)

#### Reaction Analysis (`mozcart.eqn`)
- **38 photolysis reactions** (J01-J38)
- **159 gas-phase reactions** (001-157)
- **Rate expression types**:
  - Simple photolysis rates: `j(Pj_species)`
  - Arrhenius expressions: `ARR2(A, Ea, TEMP)`
  - Troe formalism: `TROE(parameters)`
  - User-defined functions: `usr5`, `usr8`, `usr9`, `usr16`, `usr17`, `usr23`, `usr24`, `usr26`

#### Custom Functions Analysis (`mozcart.def`)
- **JPL_TROE function**: Implements pressure-dependent rate calculations
- **User-defined rate functions**:
  - `usr5`: OH + HNO3 with complex pressure dependence
  - `usr8`: CO + OH with water vapor enhancement  
  - `usr9`: HO2 + HO2 with water catalysis
  - `usr16`, `usr17`, `usr17a`: Heterogeneous reactions (currently set to 0)
  - `usr23`: SO2 + OH updated parameterization
  - `usr24`: DMS + OH with branching ratios
  - `usr26`: HO2 heterogeneous uptake (currently set to 0)

### 3. Documentation Creation

#### Created New Directory Structure
```
mozcart_documentation/
├── mozcart_mechanism.tex
└── WORK_SUMMARY.md
```

#### LaTeX Document Sections Created

1. **Introduction**
   - Mechanism overview and scope
   - List of atmospheric processes covered

2. **Chemical Species**
   - Complete table of 83 variable species with descriptions and categories
   - Fixed species description (H2O, M)

3. **Chemical Reactions**
   - Photolysis reactions (J01-J38) with subcategories
   - Gas-phase reactions (001-157) organized by chemistry type

4. **Rate Expressions**
   - Arrhenius rate constants
   - Pressure-dependent reactions (Troe formalism)
   - User-defined functions with descriptions

5. **Ozone Chemistry and Formation Mechanisms** *(Major Addition)*
   - **Fundamental Ozone Reactions**:
     - Chapman cycle (O2 photolysis, O3 formation/destruction)
     - Catalytic ozone production via VOC oxidation
     - Multiple ozone destruction pathways
   
   - **Detailed VOC Oxidation Pathways**:
     - **Alkane oxidation**: CH4, C2H6, C3H8, BIGALK with complete reaction sequences
     - **Alkene oxidation**: C2H4, C3H6, BIGENE with OH addition and ozonolysis
     - **Aromatic VOC oxidation**: TOLUENE chemistry with ring-opening products
     - **Biogenic VOC oxidation**: Detailed ISOP and C10H16 chemistry
     - **Secondary products**: CH2O, CH3CHO, CH3COCH3 oxidation pathways
   
   - **PAN Chemistry**:
     - PAN formation and thermal decomposition
     - MPAN chemistry
     - Role as NOx reservoir species
   
   - **Ozone Production Efficiency**:
     - VOC reactivity classification (high/medium/low)
     - VOC/NOx sensitivity relationships

6. **Special Features**
   - Heterogeneous chemistry on aerosol surfaces
   - Isoprene chemistry details
   - Aromatic chemistry treatment

7. **Implementation Notes**
   - Fortran 90 implementation details
   - Photolysis rate calculation via TUV
   - WRF-Chem integration

8. **Summary**
   - Mechanism capabilities and applications
   - Balance between detail and efficiency

9. **References**
   - Key scientific papers and documentation

## Key Achievements

### Comprehensive Species Documentation
- **Categorized all 83 species** by chemical family
- **Described chemical roles** of each species
- **Identified key intermediates** and reservoirs

### Detailed Reaction Analysis
- **Mapped all 197 reactions** to mechanism processes
- **Explained rate expressions** and temperature dependencies
- **Connected reactions to atmospheric processes**

### Ozone Chemistry Focus
- **Traced complete ozone formation pathways** from VOC oxidation
- **Detailed VOC oxidation mechanisms** by compound class:
  - Methane: CH4 → CH3O2 → CH2O → CO
  - Isoprene: ISOP → ISOPO2 → MACR/MVK → secondary products
  - Toluene: TOLUENE → TOLO2 → GLYOXAL/CH3COCHO/BIGALD
- **Quantified ozone production efficiency** by VOC type
- **Explained PAN formation** as NOx reservoir mechanism

### Technical Documentation
- **Rate constant formulations** with mathematical expressions
- **User-defined functions** with chemical significance
- **Integration details** for atmospheric models

## Chemical Insights Documented

### Ozone Formation Mechanisms
1. **Direct photochemical production**: VOC + NOx + hν → O3
2. **Peroxy radical cycling**: RO2 + NO → RO + NO2, HO2 + NO → OH + NO2
3. **Secondary organic chemistry**: Multi-generation VOC oxidation

### VOC Reactivity Hierarchy
- **High reactivity**: C2H4, C3H6, ISOP, C10H16 (alkenes, biogenics)
- **Medium reactivity**: TOLUENE, CH3CHO (aromatics, aldehydes)
- **Low reactivity**: CH4, C2H6, CH3OH (alkanes, alcohols)

### NOx Chemistry Complexity
- **NOx cycling**: NO ↔ NO2 via peroxy radicals
- **NOx sinks**: HNO3, N2O5, PAN formation
- **NOx reservoirs**: PAN thermal equilibrium, MPAN formation

### Atmospheric Relevance
- **Urban ozone formation**: VOC-NOx photochemistry
- **Regional transport**: PAN as NOx reservoir
- **Biogenic emissions**: Isoprene and monoterpene oxidation
- **Background chemistry**: Methane oxidation and CO chemistry

## File Structure Created

```
/home/cschmidt/git/GOLEM/wrfchem/chem/mozcart/
├── atoms_red                    # Atomic definitions
├── mozcart.def                  # Main definition with Fortran functions  
├── mozcart.eqn                  # Chemical reactions (197 reactions)
├── mozcart.kpp                  # Main KPP file
├── mozcart.spc                  # Species definitions (85 species total)
├── mozcart.tuv.jmap            # Photolysis mapping
├── mozcart_wrfkpp.equiv        # WRF-Chem equivalence
└── mozcart_documentation/       # New documentation folder
    ├── mozcart_mechanism.tex    # Complete LaTeX documentation (50+ pages)
    └── WORK_SUMMARY.md          # This summary file
```

## Usage Instructions

### Compiling the LaTeX Document
```bash
cd /home/cschmidt/git/GOLEM/wrfchem/chem/mozcart/mozcart_documentation/
pdflatex mozcart_mechanism.tex
pdflatex mozcart_mechanism.tex  # Run twice for cross-references
```

### Document Applications
- **Research reference**: Complete mechanism description for publications
- **Model documentation**: Technical reference for WRF-Chem users
- **Educational resource**: Teaching atmospheric chemistry concepts
- **Code development**: Understanding mechanism implementation

## Technical Specifications

### LaTeX Packages Used
- `amsmath`, `amsfonts`, `amssymb`: Mathematical expressions
- `longtable`: Multi-page species tables
- `booktabs`, `array`: Professional table formatting
- `hyperref`: Cross-references and navigation
- `geometry`: Page layout optimization

### Document Statistics
- **Total pages**: ~50+ when compiled
- **Chemical equations**: 200+ reaction equations
- **Species table**: Complete 83-species reference
- **Sections**: 9 major sections with multiple subsections
- **References**: Scientific literature citations

## Future Enhancements

### Potential Additions
1. **Reaction rate comparisons** with other mechanisms (CB05, RACM, etc.)
2. **Sensitivity analysis** documentation
3. **Computational performance** benchmarks
4. **Validation studies** against observations
5. **Seasonal/regional variations** in mechanism behavior

### Maintenance Notes
- Document reflects KPP files as of analysis date
- Updates needed if mechanism files are modified
- Cross-reference reaction numbers with any mechanism changes

## Conclusion

This project successfully created comprehensive scientific documentation for the MOZCART chemical mechanism, focusing particularly on ozone chemistry and VOC oxidation pathways. The documentation bridges the gap between the technical KPP implementation and the atmospheric chemistry science, making the mechanism more accessible for research, teaching, and operational use.

The work demonstrates the complexity and sophistication of modern atmospheric chemistry mechanisms while maintaining scientific accuracy and clarity in presentation.