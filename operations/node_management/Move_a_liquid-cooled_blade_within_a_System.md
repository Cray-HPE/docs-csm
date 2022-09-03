# Move a liquid-cooled blade within a System

This top level procedure outlines common scenarios for moving blades around within an HPE Cray EX system.

Blade movement scenarios:

* [Scenario 1: Swap locations of two blades](#scenario-1-swap-locations-of-two-blades)
* [Scenario 2: Move blade into a populated slot](#scenario-2-move-blade-into-a-populated-slot)
* [Scenario 3: Move blade into an unpopulated slot](#scenario-3-move-blade-into-an-unpopulated-slot)

## Prerequisites

* Knowledge of whether DVS is operating over the Node Management Network (NMN) or the High Speed Network (HSN).
* The Slingshot fabric must be configured with the desired topology for desired state of the blades in the system.
* The System Layout Service (SLS) must have the desired HSN configuration.
* Check the status of the high-speed network (HSN) and record link status before the procedure.
* The blades must have the coolant drained and filled during the swap to minimize cross-contamination of cooling systems.
  * Review procedures in *HPE Cray EX Coolant Service Procedures H-6199*
  * Review the *HPE Cray EX Hand Pump User Guide H-6200*

## Scenario 1: Swap locations of two blades

This scenario will swap the locations of *blade A* in *location A* with *blade B* in *location B*.

1. Follow the [Removing a Liquid-cooled blade from a System](Removing_a_Liquid-cooled_blade_from_a_System.md) procedure to remove *blade A* from *location A*.
1. Follow the [Removing a Liquid-cooled blade from a System](Removing_a_Liquid-cooled_blade_from_a_System.md) procedure to remove *blade B* from *location B*.
1. Follow the [Adding a Liquid-cooled blade to a System](Adding_a_Liquid-cooled_blade_to_a_System.md) procedure to add *blade A* in *location B*.
1. Follow the [Adding a Liquid-cooled blade to a System](Adding_a_Liquid-cooled_blade_to_a_System.md) procedure to add *blade B* in *location A*.

## Scenario 2: Move blade into a populated slot

This scenario will move *blade A* in *location A* into the *location B* of *blade B*, but not repopulate *location A* with a blade.

1. Follow the [Removing a Liquid-cooled blade from a System](Removing_a_Liquid-cooled_blade_from_a_System.md) procedure to remove *blade A* from *location A*.
1. Follow the [Removing a Liquid-cooled blade from a System](Removing_a_Liquid-cooled_blade_from_a_System.md) procedure to remove *blade B* from *location B*.
1. Follow the [Adding a Liquid-cooled blade to a System](Adding_a_Liquid-cooled_blade_to_a_System.md) procedure to add *blade A* in *location B*.

## Scenario 3: Move blade into an unpopulated slot

This scenario will move *blade A* in *location A* to the unpopulated slot of *location B*.

1. Follow the [Removing a Liquid-cooled blade from a System](Removing_a_Liquid-cooled_blade_from_a_System.md) procedure to remove *blade A* from *location A*.
1. Follow the [Adding a Liquid-cooled blade to a System](Adding_a_Liquid-cooled_blade_to_a_System.md) procedure to add *blade A* in *location B*.
