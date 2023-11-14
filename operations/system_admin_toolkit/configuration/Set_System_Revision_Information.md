# Set System Revision Information

HPE service representatives use system revision information data to identify
systems in support cases.

## Prerequisites

- SAT authentication has been set up. See [Authenticate SAT Commands](Authenticate_SAT_Commands.md).
- S3 credentials have been generated. See [Generate SAT S3 Credentials](Generate_SAT_S3_Credentials.md).

## Procedure

1. (`ncn-m001#`) Set System Revision Information.

   Run `sat setrev` and follow the prompts to set the following site-specific values:

   - Serial number
   - System name
   - System type
   - System description
   - Product number
   - Company name
   - Site name
   - Country code
   - System install date

   **Tip**: For "System type", a system with *any* liquid-cooled components should be
   considered a liquid-cooled system. In other words, "System type" is EX-1C.

   ```bash
   sat setrev
   ```

   Example output:

   ```text
   --------------------------------------------------------------------------------
   Setting:        Serial number
   Purpose:        System identification. This will affect how snapshots are
                   identified in the HPE backend services.
   Description:    This is the top-level serial number which uniquely identifies
                   the system. It can be requested from an HPE representative.
   Valid values:   Alpha-numeric string, 4 - 20 characters.
   Type:           <class 'str'>
   Default:        None
   Current value:  None
   --------------------------------------------------------------------------------
   Please do one of the following to set the value of the above setting:
       - Input a new value
       - Press CTRL-C to exit
   ...
   ```

1. Verify System Revision Information.

   (`ncn-m001#`) Run `sat showrev` and verify the output shown in the "System Revision Information table."

   ```bash
   sat showrev
   ```

   Example table output:

   ```text
   ################################################################################
   System Revision Information
   ################################################################################
   +---------------------+---------------+
   | component           | data          |
   +---------------------+---------------+
   | Company name        | HPE           |
   | Country code        | US            |
   | Interconnect        | Sling         |
   | Product number      | R4K98A        |
   | Serial number       | 12345         |
   | Site name           | HPE           |
   | Slurm version       | slurm 20.02.5 |
   | System description  | Test System   |
   | System install date | 2021-01-29    |
   | System name         | eniac         |
   | System type         | EX-1C         |
   +---------------------+---------------+
   ################################################################################
   Product Revision Information
   ################################################################################
   +--------------+-----------------+------------------------------+------------------------------+
   | product_name | product_version | images                       | image_recipes                |
   +--------------+-----------------+------------------------------+------------------------------+
   | csm          | 0.8.14          | cray-shasta-csm-sles15sp1... | cray-shasta-csm-sles15sp1... |
   | sat          | 2.0.1           | -                            | -                            |
   | sdu          | 1.0.8           | -                            | -                            |
   | slingshot    | 0.8.0           | -                            | -                            |
   | sma          | 1.4.12          | -                            | -                            |
   +--------------+-----------------+------------------------------+------------------------------+
   ################################################################################
   Local Host Operating System
   ################################################################################
   +-----------+----------------------+
   | component | version              |
   +-----------+----------------------+
   | Kernel    | 5.3.18-24.15-default |
   | SLES      | SLES 15-SP2          |
   +-----------+----------------------+
   ```
