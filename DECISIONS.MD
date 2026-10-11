1. Ordering & priority: What syncs first when a connection appears, and why? What happens when the connection dies at 60% of a photo upload?

## visists would go first as we need to record who is at the farm,when and why then pictures last. Photos would be lower priority because they are relatively large and the network is unreliable which can result in long waiting period for the agronomists at head office
## we could also support resume upload so when connection is back photos can continue uploading to the server/ each photo will have a uniqueID so when retrying it avoid duplications


2. Conflict resolution: Agent A and Agent B both corrected the hectare count of the same field while offline. A wrote 12.5, B wrote 13.0. B's device clock is 3 hours behind. What does the system do, and what does each agent see afterward? Why is naive last write-wins wrong here?

## Last write-wins would not work on this specifically because timestand is not accurate, so Agent Bs count would be the last in yet recorded as first in. so i would flag the conflicts keeping both counts until reviewed (with both agents names/ID on the records incase more info is required from either of them)


3. Duplicate Prevention: The agent's upload succeeds but the connection drops before the server's confirmation arrives. The app retries. How do you prevent a duplicate visit record?

## each visit/record having a uniqueID is a great way of keeping track with whats already synced, if the connection droped when the app retries the server would use this ID to check if the record exist and return appropriate response to the app without duplication

4. Storage choice: What would you use for local persistence in Flutter for this workload, and what did you rule out? (Name specific packages.)

## Prefereed SQLlite (sqflite package) 
## Support transactions and batches
## Automatic version managment during open
## Helpers for insert/query/update/delete queries
## Indexes

## Ruled out 
## shared_preferences is for small preferences, not a transactional queue
## Hive is designed to be small and fast. NoSQL: You store data as key-value pairs. 


5. The trade-off you're least sure about: Name one decision above where you think reasonable engineers would disagree with you, and steelman their position.

## probably choosing SQLite with the sqflite package for local persistence instead of Hive as its light weight and no data and table management 
## Some engineers might prefer last-write-wins because it is simpler and avoids too many conflicts waiting to be resolved


