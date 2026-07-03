# Remote Names

`RemoteNames.lua` centralizes remote names so the server and client do not drift apart.

Server creates remotes under:

```text
ReplicatedStorage/BuildABugRemotes
```

Client waits for the same names before initializing UI/controllers.
