# Evolution of Variability Anomalies

## Overview

*Variability anomalies* occur due to inconsistent configuration constraints in a system. We detect variability anomalies in the form of dead and undead code files and code blocks. This project focused on the evolution of such variability anomalies in the Linux kernel, specifically how they get introduced and how they get fixed. This repository contains the scripts used to do this and is based on our [MSR '13](https://dl.dropboxusercontent.com/s/ifffnko4yw84pvl/NADI_MSR_2013.pdf) paper titled "Linux Variability Anomalies: What Causes Them and How Do They Get Fixed?."

## Scripts overview

The main entry point is in `EvolutionScripts/complete-analysis.py`. The  comments at the top of the script indicates the assumptions and previous scripts that need to be run.

The herodotos analysis is in the Herodotos folder, with a separate ReadMe file to explain things there.

## Team

* [Sarah Nadi](http://www.sarahnadi.org), University of Alberta (was at University of Waterloo at the time of this project)
* [Christian Dietrich](https://www4.cs.fau.de/~stettberger/), Friedrich-Alexander-Universität Erlangen-Nürnberg
* [Reinhard Tartler](https://www.deshawresearch.com/people_compsci_tartler.html), DE Shaw Research (was at Friedrich-Alexander-Universität Erlangen-Nürnberg at the time of this project)
* [Daniel Lohmann](https://www4.cs.fau.de/~lohmann/), Friedrich-Alexander-Universität Erlangen-Nürnberg
* [Richard C. Holt](), University of Waterloo (currently retired)

### Disclaimer

This repository may be a bit of a mess right now. After more than 4 years from this project, I'm finally pulling everything together into this repository (basically sifting through our private repository and sharing relevant things). This is **long** overdue and I tried to organize things as much as I remember. Unfortunately, there are likely missing steps and undocumented assumptions that I cannot fully remember. I've improved in this regards over time and learned my lessons to organized and share things as soon as possible. This is a lesson for every grad student out there :-)