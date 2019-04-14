# sentinel
Self Educating Nanny That Intelligently Encodes Learnings

## Build

First create a file in the root of this repository called `Envfile` and populate it with the password to use to protect the live stream, e.g.

```
SENTINEL_PASSWORD=password
```

## Deploy

### Updating VOD server password
The vod server in `server/hls-server.js` sits behind a password protected reverse proxy,
and currently all vod assets served over the network include the current password when
that vod asset was created.

After updating the vod password, and restarting the `vod-chop.sh` process, use the example commands
in `roll_vod_key.sh` to update all files from the old password to the new password.
