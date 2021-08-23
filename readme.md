# DockStat

DockStat is a Bash script to show output of running Docker containers and related resources:

![](./DockStat.png?1.1.0)

This is mainly good for small, developer Docker setups.  It was originally created to monitor from two to eight containers that were continually being brought up and down and being pruned.  Otherwise, for example, if Docker is used a lot with many disperate containers thus has lots images cached, DockStat lists ALL your images.  Displaying dozens or more images will likely break the display functionally.  KISS, 'kay?!


DockStat uses [Simple Curses](https://github.com/metal3d/bashsimplecurses/) library to render the output in Bash.

## Using

To use DockStat:
1. Ensure you have Docker installed
1. Clone this repo
1. `cd` into this repo
1. Run `./DockStat.sh`

This should run on any OS, but has only been tested on Ubuntu.

## Stats Shown

DockStat will list:
* Host load average
* Host total processes
* Host total Docker processes
* Per container table showing:
    * Name
    * Docker IP
    * Ports mapped
    * Up time with process count
* Docker networks
* Docker volumes
* Docker images
