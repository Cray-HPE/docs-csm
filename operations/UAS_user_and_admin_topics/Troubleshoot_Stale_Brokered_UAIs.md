# Troubleshoot Stale Brokered UAIs

When a broker UAI terminates and restarts, the SSH key used to forward SSH sessions to end-user UAIs changes (this is a known problem) and subsequent broker UAIs are unable to forward sessions to end-user UAIs. The symptom of this is that a user logging into a broker UAI will receive a password prompt from the end-user UAI and be unable to log in even if providing the correct password. To fix this, remove the stale end-user UAIs and allow the broker UAI to recreate them. The easy way to do this is to use the command specifying the uai-creation-class identifier from the broker's UAI class.

```
cray uas admin uais delete --class-id <creation-class-id>
```

For example:

```
ncn-m001-pit# cray uas admin config classes list | grep -e class_id -e comment
class_id = "74970cdc-9f94-4d51-8f20-96326212b468"
comment = "UAI broker class"
class_id = "a623a04a-8ff0-425e-94cc-4409bdd49d9c"
comment = "UAI User Class"
class_id = "bb28a35a-6cbc-4c30-84b0-6050314af76b"
comment = "Non-Brokered UAI User Class"

ncn-m001-pit# cray uas admin config classes describe 74970cdc-9f94-4d51-8f20-96326212b468 | grep uai_creation_class
uai_creation_class = "a623a04a-8ff0-425e-94cc-4409bdd49d9c"

ncn-m001-pit# cray uas admin uais delete --class-id a623a04a-8ff0-425e-94cc-4409bdd49d9c
results = [ "Successfully deleted uai-vers-6da50e7a",]
```

After that, users should be able to log into the broker UAI and be directed to an end-user UAI as before.

