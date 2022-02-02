# Move a liquid-cooled blade within a System
This top level procedure outlines common scenarios for moving blades around withing a HPE Cray EX system.

Blade movement scenarios:
* [Scenario 1: Swap locations of two blades](#swap-locations-of-two-blades)
* [Scenario 2: Move blade into a populated slot](#move-blade-into-a-populated-slot)
* [Scenario 3: Move blade into an unpopulated slot](#move-blade-into-an-unpopulated-slot)

## Prerequisites
-   Knowledge of whether DVS is operating over the Node Management Network (NMN) or the High Speed Network (HSN).

-   The Slingshot fabric must be configured with the desired topology for desired state of the blades in the system.

-   The System Layout Service (SLS) must have the desired HSN configuration.

-   Check the status of the high-speed network (HSN) and record link status before the procedure.

-   The blades must have the coolant drained and filled during the swap to minimize cross-contamination of cooling systems.
    - Review procedures in *HPE Cray EX Coolant Service Procedures H-6199*
    - Review the *HPE Cray EX Hand Pump User Guide H-6200*

<a name="swap-locations-of-two-blades"></a>

## Scenario 1: Swap locations of two blades
This scenario will swap the locations of _blade A_ in _location A_ with _blade B_ in _location B_.

1. Follow the [Removing a Liquid-cooled blade from a System](Removing_a_Liquid-cooled_blade_from_a_System.md) procedure to remove _blade A_ from _location A_.

2. Follow the [Removing a Liquid-cooled blade from a System](Removing_a_Liquid-cooled_blade_from_a_System.md) procedure to remove _blade B_ from _location B_.

3. Follow the [Adding a Liquid-cooled blade to a System](Adding_a_Liquid-cooled_blade_to_a_System.md) procedure to add _blade A_ in _location B_.

4. Follow the [Adding a Liquid-cooled blade to a System](Adding_a_Liquid-cooled_blade_to_a_System.md) procedure to add _blade B_ in _location A_.

<a name="move-blade-into-a-populated-slot"></a>

## Scenario 2: Move blade into a populated slot
This scenario will move _blade A_ in _location A_ into the _location B_ of _blade B_, but not repopulate _location A_ with a blade.

1. Follow the [Removing a Liquid-cooled blade from a System](Removing_a_Liquid-cooled_blade_from_a_System.md) procedure to remove _blade A_ from _location A_.

2. Follow the [Removing a Liquid-cooled blade from a System](Removing_a_Liquid-cooled_blade_from_a_System.md) procedure to remove _blade B_ from _location B_.

3. Follow the [Adding a Liquid-cooled blade to a System](Adding_a_Liquid-cooled_blade_to_a_System.md) procedure to add _blade A_ in _location B_.

<a name="move-blade-into-an-unpopulated-slot"></a>

## Scenario 3: Move blade into an unpopulated slot
This scenario will move _blade A_ in _location A_ to the unpopulated slot of _location B_.

1. Follow the [Removing a Liquid-cooled blade from a System](Removing_a_Liquid-cooled_blade_from_a_System.md) procedure to remove _blade A_ from _location A_.

3. Follow the [Adding a Liquid-cooled blade to a System](Adding_a_Liquid-cooled_blade_to_a_System.md) procedure to add _blade A_ in _location B_.
