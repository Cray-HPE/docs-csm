# Setting UAI Timeouts

The procedures and specific values used for setting UAI timeouts are explained in the [UAI Classes](UAI_Classes.md) section. Please refer to that section.

On systems where UAIs are used as part of normal user activities, the number of UAIs can grow large. Stale UAIs (i.e. UAIs that sit idle for long periods of time) can prevent creation of fresh UAIs for users who are actually active on the system.
To address this without constant administrative monitoring, UAS permits the administrator to place both `hard` and `soft` timeouts on UAI Classes, which then constrain the amount of time a UAI can exist before it will terminate and need to be recreated.
UAI timeouts are particularly useful in the [Brokered UAI Management](Broker_Mode_UAI_Management.md) mode because automatic creation of UAIs makes the coming and going of UAIs seamless, and also tends to cause the creation of many UAIs.
UAI timeouts are also useful in the [Legacy UAI Management](Legacy_Mode_User-Driven_UAI_Management.md) mode, however, since, in that mode, it is common for users to create a UAI for a task and forget to remove it when the task is done.
This can be compounded by the user forgetting that a UAI already exists and making another.

The choice of what kind of timeouts and the duration of the timeouts is likely to be very site specific, however some general guidelines apply, especially when it comes to choosing what kinds of timeouts to use.

If a Class of UAI has users who tend to remain logged in and actively using their UAIs for long periods of time, it can make sense to set a `soft` timeout without setting a `hard` timeout on that UAI Class.
In this case, a reasonably aggressive (30 minutes, for example) `soft` timeout can keep idle UAIs to a minimum while not impeding users who need to remain logged into their UAIs for days or weeks.

**NOTE:** Consider moving users with workflows like the above onto UANs instead of UAIs if the site provides UANs due to the [inherent impermanence](End_User_UAIs.md) of End-User UAIs.

If a UAI Class is intended to provide UAIs for occasional launching or checking the status of workload management jobs and not for extended login sessions,
it may make sense to set a fairly aggressive `hard` timeout (10 minutes, for example) and a very aggressive (30 seconds, for example) `soft` timeout.
This will make sure that users do not overstay their welcome in this class of UAI, and will generally cause the UAI to terminate as soon as the user logs out.

If a UAI Class creates more general purpose UAIs that are neither especially disruptive when they time out nor intended for especially short term work, a somewhat generous (24 hours, for example) `hard` timeout
combined with a fairly aggressive (30 minutes, for example) `soft` timeout will keep idle UAIs of that class under control while permitting longer term users to stay logged in without giving them unlimited login durations.

If `hard` timeouts are used, a `warning` should usually be added to the timeout specification in the UAI Class. This will give users a chance to finish up any in-progress work and log out prior to termination of the UAI as a result of the `hard` timeout.

[Top: User Access Service (UAS)](index.md)

[Next Topic: Broker UAI Resiliency and Load Balancing](Setting_Up_Multi-Replica_Brokers.md)
