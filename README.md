<div align="center">

# TTT Drowning Indicator

<a href="https://steamcommunity.com/sharedfiles/filedetails/?id=481440358">
    <img src=https://img.shields.io/endpoint?url=https%3A%2F%2Fshieldsio-steam-workshop.jross.me%2F481440358%2Fsubscriptions-text height=25>
</a>

<div></div>

<img src="thumbnail.jpg" width=256>

</div>


This addon displays a small HUD which shows how long one can stay underwater. It has been written for the TTT gamemode in Garry's Mod, but it should be adaptable to other gamemodes as well.

### Steampage
https://steamcommunity.com/sharedfiles/filedetails/?id=481440358

## Working with this project

Here are the most important commands, cobbled together from the [gmod wiki](https://wiki.facepunch.com/gmod/Workshop_Addon_Creation).

### Building the addon
You need to have Garry's Mod installed. Clone this repo, `cd` into it and run following command:

```sh
~/.steam/steamapps/common/GarrysMod/bin/gmad_linux create -folder . -out "drowning_indicator.gma"
```

### Releasing an update
Build the addon as above and then run:

```sh
LD_LIBRARY_PATH=~/.steam/steam/steamapps/common/GarrysMod/bin/ ~/.steam/steam/steamapps/common/GarrysMod/bin/gmpublish_linux update -addon drowning_indicator.gma -id "481440358" -changes "General fixes and system stability improvements"
```

You might not need to set `LD_LIBRARY_PATH`, however currently [this issue](https://github.com/Facepunch/garrysmod-issues/issues/4542) still persists.


## Organizational Infos

### Maintainer

> "Maintainer? This thing is being maintained?! That's news to me!"
>
> <cite>— [@Xmoe](https://github.com/Xmoe), maintainer of this project</cite>

### License

This project is licensed under the [GPL-3.0 license](LICENSE.md).