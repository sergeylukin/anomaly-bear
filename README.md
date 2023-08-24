# IMPORTANT UPDATE (24 August, 9PM)

Despite having reviewed the assignment specifications, I focused on the
"bot_name" and "Geo_Ip" values for my solution instead of the specified
"bot_name" and "user_geo." Nonetheless, I have chosen to keep the solution
unchanged, as it fulfills the other requirements outlined in the assignment
specifications.

# Hit Rate Anomalies Detection Visualization

Project demo: https://b100.dep.la/

Data plotting solution (with project summary):

https://observablehq.com/d/50e6251afbd66975

# Getting started

In order to fetch raw data, run `PASSWORD=<Elastic Search Pass> bash ./scripts/fetch.sh`

In order to prepare (wrangle) data for plotting, run `bash ./scripts/wrangle.sh`

Upload wrangled JSON from `./tmp/charts/` to observablehq.

Run the plot inside observablehq.
