# UAI Images

There are three kinds of UAI images used by UAS:

* A pre-packaged Broker UAI image provided with the UAS
* A pre-packaged basic End-User UAI Image provided with the UAS
* Custom End-User UAI images created on site, usually based on compute node contents

UAS provides two stock UAI images when installed. The first is a standard End-User UAI Image that has the necessary software installed in it to support a basic Linux distribution login experience.
This image is provided for the purpose of [sanity testing the UAS installation](UAS_and_UAI_Health_Checks.md) and as a simple starting point for administrative experimentation with UAS and UAIs.

The second image is a Broker UAI image. Broker UAIs are a special type of UAIs used in the ["broker based" operation model](Broker_Mode_UAI_Management.md).
Broker UAIs present a single SSH endpoint that responds to each SSH connection by locating or creating a suitable End-User UAI and redirecting the SSH session to that End-User UAI.

A site may provide any number of [Custom End-User UAI Images](Customize_End-User_UAI_Images.md) as needed to support various use cases and workflows.

[Top: User Access Service (UAS)](index.md)

[Next Topic: Listing Registered UAI Images](List_Registered_UAI_Images.md)
