Here are some previous instructions and saved files:

To come up with some patterns for how anomalies get introduced and fixed, we analyze a set of patches that have been submitted by Tartler et al. in their [EuroSys 2011 paper](http://www4.cs.fau.de/Publications/2011/tartler_11_eurosys.pdf). By using [undertaker](http://vamos.informatik.uni-erlangen.de/trac/undertaker), they detected a set of variability anomalies, and then submitted patches to fix some of the detected dead/undead code blocks. They tracked the responses of developers to these patches.

The [following](/anomaly_evol/linux-mbox.tar.gz) is the dataset of all these email exchanges. To open it, you can install the `mail` tool on Linux which is part of the `mailutils` package. After extracting the archive, use the following command:

```mail -f linux-mbox/```

You can also use mutt which has a slightly better user interface.

```mutt -f linux-mbox/```


The dataset of the detected defects on which these patches are based can be found in this [SQLite database](/anomaly_evolution/linux-mbox.tar.gz). You can browse this database visually using [SQLite Browser](https://apps.ubuntu.com/cat/applications/precise/sqlitebrowser/). The `defects` table contains the detected defects/anomalies. The `tickets` table contains the submitted patches, their resolution, and our classification of what the patch was doing (patch_type).

The following are examples of how you can query the database:

*Maximum Number of Defects Solved by Patch:*

```
select max(defectCountPerTicket) from
(select ticket, count(filename) as defectCountPerTicket from defects, ticket
where defects.ticket = ticket.id
group by ticket)
```

*Number of referential defects for which patches are submitted:*

```
SELECT count(ticket) from defects where ticket IS NOT NULL and defects.filename LIKE '%missing%'
```

*Number of tickets solving detected defects:*

```
select COUNT(*) from ticket where id IN 
(SELECT ticket from defects where ticket IS NOT NULL)
```
