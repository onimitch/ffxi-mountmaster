# Mount Master

An ashita v4 addon that allows mount and dismount from one command. Set a favorite mount or let it choose randomly.

Supports both English and Japanese clients.

## How to install:
1. Download the latest Release from the [Releases page](https://github.com/onimitch/ffxi-mountmaster/releases)
2. Extract the **_mountmaster_** folder to your **_Ashita4/addons_** folder

## How to have Ashita load it automatically:
1. Go to your Ashita v4 folder
2. Open the file **_Ashita4/scripts/default.txt_**
3. Add `/addon load mountmaster` to the list of addons to load under "Load Plugins and Addons"

## Commands

`/mount` - Mount or dismount your favorite mount, or random if one is not set.

`/mount set NAME` - Set your favorite mount. Replace NAME with the name of the mount.

`/mount set` - Clear your favorite mount (mount will be chosen randomly).

`/mount random` - Mount or dismount, a mount is always chosen at random.

## BGM Commands

`/mount bgm mute` - Silent mount music.

`/mount bgm SONGID` - Change mount music. *Tip: Google "FFXI Song IDs".*

`/mount bgm` - Set mount music back to the default.