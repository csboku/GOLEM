# Tropospheric Ozone Chemistry in MOZART-MOSAIC

This document outlines the fundamental chemical processes that govern the formation and destruction of tropospheric ozone (O₃) as described in the `mozart_mosaic_4bin_aq.eqn` chemical mechanism.

## Introduction

Tropospheric ozone is a major secondary air pollutant, meaning it is not directly emitted into the atmosphere. Instead, it is formed through a series of complex photochemical reactions involving sunlight and precursor gases. Understanding this chemistry is crucial for predicting and controlling air quality.

The key "ingredients" for ozone formation are:
*   **Nitrogen Oxides (NOx = NO + NO₂)**
*   **Volatile Organic Compounds (VOCs)**
*   **Carbon Monoxide (CO)**
*   **Sunlight (hv)**

## The Ozone Formation Cycle

Ozone is continuously produced and destroyed in the atmosphere. Net ozone accumulation occurs when the rate of production exceeds the rate of destruction. The process is a cycle, catalyzed by NOx and fueled by the oxidation of VOCs and CO.

### Step 1: The Spark - Photolysis of NO₂

The entire cycle is initiated by sunlight. The photolysis (breakdown by light) of nitrogen dioxide (NO₂) is the only significant source of the atomic oxygen (O) needed to form ozone in the troposphere.

```fortran
{J005} NO2 + hv = O + NO
```

### Step 2: Ozone Creation

The highly reactive atomic oxygen produced in Step 1 rapidly combines with molecular oxygen (O₂) to form ozone (O₃).

```fortran
{T001} O + M{ = O2} = O3
```
*Where `M` represents a third body molecule (like N₂ or O₂) that stabilizes the reaction.*

### The Null Cycle (Without VOCs)

If only NOx were present, these two reactions would be balanced by a third reaction, creating a "null cycle" with no net ozone production. Nitric oxide (NO) reacts with O₃, converting it back to NO₂.

```fortran
{T019} O3 + NO = NO2{ + O2}
```

### Step 3: The Engine - The Critical Role of VOCs and CO

This is the crucial part of the cycle that leads to **net ozone production**. The oxidation of VOCs and CO provides a pathway to convert NO back to NO₂ *without* consuming an ozone molecule. This is driven by the hydroxyl radical (OH), the atmosphere's primary cleaning agent.

#### 3a. Initiation: The OH Attack

The process starts when OH attacks a VOC or CO molecule. This creates peroxy radicals (`HO₂` from CO, and organic peroxy radicals `RO₂` from VOCs).

*   **CO Oxidation:**
    ```fortran
    {T043} CO + OH = HO2{ + CO2}
    ```
*   **VOC Oxidation:** The mechanism is similar for all VOCs. The OH radical attacks the VOC, creating a specific organic peroxy radical (RO₂).
    *   **Alkanes (e.g., Ethane, `C2H6`):**
        ```fortran
        {T051} C2H6 + OH = C2H5O2{ + H2O}
        ```
    *   **Alkenes (e.g., Isoprene, `ISOP`):**
        ```fortran
        {T094} ISOP + OH = ISOPO2
        ```
    *   **Aromatics (e.g., Toluene):**
        ```fortran
        {T137} OH + TOLUENE = ... + 0.65 TOLO2 + ...
        ```

#### 3b. Propagation: Peroxy Radicals Convert NO to NO₂

These peroxy radicals (`HO₂` and `RO₂`) are the key. They rapidly oxidize NO to NO₂, regenerating the NO₂ needed for Step 1 and allowing more ozone to be formed. This step is what breaks the "null cycle."

*   **Conversion by HO₂:**
    ```fortran
    {T018} NO + HO2 = NO2 + OH
    ```
*   **Conversion by RO₂ (e.g., from Ethane):**
    ```fortran
    {T052} C2H5O2 + NO = CH3CHO + HO2 + NO2 + nume
    ```

By converting NO to NO₂ without consuming ozone, this pathway allows O₃ to accumulate. The OH radical is also regenerated in the process, allowing it to continue oxidizing more VOCs in a **catalytic chain reaction**. The breakdown of a single large VOC can lead to the formation of multiple radical species, resulting in the creation of multiple ozone molecules.

## Ozone Destruction (Sinks)

Ozone is not permanent and can be destroyed by several pathways:

1.  **Photolysis:** Sunlight can also break down ozone, especially creating the `O1D_CB4` excited state of oxygen, which is a primary source of the OH radical when water is present.
    ```fortran
    {J002} O3 + hv = O1D_CB4{ + O2}
    {T004} O1D_CB4 + H2O = OH + OH
    ```
    And a less energetic pathway:
    ```fortran
    {J003} O3 + hv = O{ + O2}
    ```

2.  **Reaction with Radicals:** Ozone reacts with the key radicals in its own formation cycle, OH and HO₂. These reactions become significant sinks for ozone in low-NOx environments.
    ```fortran
    {T009} OH + O3 = HO2{ + O2}
    {T010} HO2 + O3 = OH{ + O2 + O2}
    ```

## Summary of Key Species

| Species | Name                  | Role in Ozone Chemistry                                       |
| :------ | :-------------------- | :------------------------------------------------------------ |
| **O₃**  | Ozone                 | The final product. Also a source of OH radicals.              |
| **NO₂** | Nitrogen Dioxide      | **Primary Precursor**. Photolyzed by sunlight to start the cycle. |
| **NO**  | Nitric Oxide          | Converted to NO₂ to drive ozone production. Can also destroy ozone. |
| **VOCs**| Volatile Organic Cmpd | **Fuel**. Oxidized to form peroxy radicals (RO₂), which drive the NO to NO₂ conversion. |
| **CO**  | Carbon Monoxide       | **Fuel**. Oxidized to form the hydroperoxy radical (HO₂).      |
| **OH**  | Hydroxyl Radical      | **Initiator**. The "detergent" that starts VOC/CO oxidation.  |
| **HO₂** | Hydroperoxy Radical   | **Propagator**. Oxidizes NO to NO₂, producing ozone.           |
| **RO₂** | Organic Peroxy Radical| **Propagator**. Oxidizes NO to NO₂, producing ozone.           |

## Conclusion

Tropospheric ozone production is a complex photochemical process where NOx acts as a catalyst, and VOCs and CO act as the fuel. The oxidation of VOCs is particularly critical as it generates the peroxy radicals that power the conversion of NO to NO₂, breaking the null cycle and leading to the net accumulation of ozone pollution. The balance between these formation and destruction pathways, which is highly dependent on the relative concentrations of NOx and VOCs, determines the final ozone concentration.