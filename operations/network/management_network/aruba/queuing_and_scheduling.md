# Queuing and Scheduling 

When defining end-to-end behavior via CoS or DSCP, different priorities of traffic must be placed in different queues so the network device can service them appropriately. Separate queues allow delay- or jitter-sensitive traffic to be serviced before bulk or less time-critical traffic. 

Queue policies configure which queues the different priorities of traffic will use. Queues are numbered in priority order, with zero being the lowest priority. The larger the queue number, the higher the priority of that queue. 

Schedule policies configure the order of the queues from which packets are removed (de-queued) for transmitting. The schedule discipline is the algorithm the scheduler employs each round it must select the next packet for transmission. The supported scheduling disciplines are: 

* **Strict priority (SP):** This is the simplest of scheduling disciplines. For each round, the scheduler will choose the highest- priority queue when removing packets for transmission. While this does provide prioritization of traffic, when spikes of high priority traffic occur it will prevent lower priority traffic from being transmitted (queue starvation). 
* **Weighted fair queuing (WFQ):** Weighted fair queuing can limit queue starvation by providing a fairer distribution of available bandwidth across the priorities. Lower priority queues will have some service even when packets are present in higher priority queues, depending on the weights assigned to each queue; the larger the weight, the greater the potential amount of service. WFQ accommodates variable traffic and services each packet as fairly as possible. 

## Configuration Commands 

Create a profile: 

```bash
switch(config)# qos queue-profile NAME
switch(config)# qos schedule-profile NAME
```

Apply a profile:

```bash
switch(config)# apply qos queue-profile NAME schedule-profile NAME 
```

Configure a profile: 

```bash
switch(config-queue)# map queue <0-7> local-priority <0-7>
switch(config-schedule)# strict queue <0-7>
switch(config-schedule)# wfq queue <0-7> weight <0-253>
```

Show commands to validate functionality:  

```bash
switch# show interface IFACE queues
switch# show qos queue-profile [QUEUE-NAME]
switch# show qos schedule-profile [SCHED-NAME]
```

## Expected Results 

1. Administrators can configure a new queue profile and a schedule profile 
1. Administrators can apply queue profile and schedule profile
1. The output of the `show` commands is correct
1. The traffic pattern matches the scheduler configuration 

## Example Output 

```bash
switch(config)# qos queue-profile VOICE-Q-PROFILE
switch(config-queue)# map queue 0 local-priority 0
switch(config-queue)# map queue 1 local-priority 1
switch(config-queue)# map queue 2 local-priority 2
switch(config-queue)# map queue 3 local-priority 3
switch(config-queue)# map queue 4 local-priority 4
switch(config-queue)# map queue 5 local-priority 6
switch(config-queue)# map queue 6 local-priority 7
switch(config-queue)# map queue 7 local-priority 5
switch(config-queue)# exit
switch(config)# qos schedule-profile VOICE-SCHED-PROFILE
switch(config-schedule)# wfq queue 0 weight 3
switch(config-schedule)# wfq queue 1 weight 6
switch(config-schedule)# wfq queue 2 weight 12
switch(config-schedule)# wfq queue 3 weight 25
switch(config-schedule)# wfq queue 4 weight 50
switch(config-schedule)# wfq queue 5 weight 100
switch(config-schedule)# wfq queue 6 weight 200
switch(config-schedule)# strict queue 7
switch(config-schedule)# exit
```

[Back to Index](../index.md)