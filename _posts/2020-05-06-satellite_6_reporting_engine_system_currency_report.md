---
title:  "Red Hat Satellite 6 reporting engine - System currency report"
tags: [satellite]
---

This post describe how generate the "System currency" report in Red Hat Satellite 6.
System currency report is a report already existing in Satellite 5, below there its description from Satellite 5 [documentation](https://access.redhat.com/documentation/en-us/red_hat_satellite/5.6/html/getting_started_guide/sect-getting_started_guide-systems_management-managing_systems_with_satellite)

> System Currency report which lists registered systems ordered by score. The score is determined by the totals of the errata relevant to the systems. A specific weighted score per category per errata adds to the total score where the default weight awards critical security errata with the heaviest weight and enhancement errata with the lowest. The report can be used to prioritize maintenance actions on the systems registered to the Satellite.

In Red Hat Satellite 6.5 has been introduced a new feature named ["Reporting engine"](https://www.redhat.com/en/blog/getting-started-satellite-65-reporting-engine), allows to Satellite users to create reports that can be exported in different formats.

Below there is an example of the output of the Satellite 6 system currency reports:

Organization  | Host   | Critical  | Important   | Moderate   | Low   | Bugfix  | Enhancement  | Score  
--|---|---|---|---|---|---|---|--
ACME | dhcp-server-01 | 6  | 102  | 103  | 28  | 794  | 144  | 4492
ACME | dhcp-server-02 | 6  | 102  | 104  | 28  | 790  | 143  | 4491
ACME | database-01 |  7 | 84  | 52   | 5  | 296  | 41  | 2637
ACME |  application-01 | 3  | 55  | 16  | 3  | 114  | 19  | 1363
ACME | satellite6 | 0  | 0  | 0  | 0  | 0  | 0  |  0

In the box below there is the code to generate this report, the code can be also downloaded [here](https://github.com/giovannisciortino/community-templates/blob/31d197fe4154a526e281a8424ee5ccb438bc80af/report_templates/host_-_system_currency.erb):

{% highlight YAML ruby %}
<%#
name: Host - System currency
snippet: false
template_inputs:
- name: Hosts filter
  required: false
  input_type: user
  description: Limit the report only on hosts found by this search query. Keep empty
    for report on all available hosts.
  advanced: false
  value_type: search
  resource_type: Host
- name: Errata filter
  required: false
  input_type: user
  description: Limit the report only on errata found by this search query. Keep empty
    for report on all available errata.
  advanced: false
model: ReportTemplate
require:
- plugin: katello
￼ version: 3.9.0
-%>
<%  # multiplier for critical security errata -%>
<%- sc_crit = 32 -%>
<%  # multiplier for important security errata -%>
<%- sc_imp = 16 -%>
<%  # multiplier for moderate important security errata -%>
<%- sc_mod = 8 -%>
<%  # multiplier for low important security errata -%>
<%- sc_low = 4 -%>
<%  # multiplier for bugfix errrata -%>
<%- sc_bug = 2 -%>
<%  # multiplier for ehnancement errata -%>
<%- sc_enh = 1 -%>
<%- report_entries = [] -%>
<%- load_hosts(search: input('Hosts filter'), includes: [:applicable_errata]).each_record do |host| -%>
<%-   critical = 0 -%>
<%-   important = 0 -%>
<%-   moderate = 0 -%>
<%-   low = 0 -%>
<%-   bugfix = 0 -%>
<%-   enhancement = 0 -%>
<%-   host_applicable_errata_filtered(host, input('Errata filter')).each do |erratum| -%>
<%-   critical+=1 if erratum.errata_type == 'security' and erratum.severity == 'Critical' -%>
<%-   important+=1 if erratum.errata_type == 'security' and erratum.severity == 'Important' -%>
<%-   moderate+=1 if erratum.errata_type == 'security' and erratum.severity == 'Moderate' -%>
<%-   low+=1 if erratum.errata_type == 'security' and erratum.severity == 'Low' -%>
<%-   bugfix+=1 if erratum.errata_type == 'bugfix' -%>
<%-   enhancement+=1 if erratum.errata_type == 'enhancement' -%>
<%-   end -%>
<%-   score = critical*sc_crit + important*sc_imp + moderate*sc_mod + low*sc_low + bugfix*sc_bug + enhancement*sc_enh -%>
<%-   report_entries << {
          'Organization': host.organization,    
          'Host ID': host.id,
          'Host': host.name,
          'Critical': critical,
          'Important': important,
          'Moderate': moderate,
          'Low': low,
          'Bugfix': bugfix,
          'Enhancement': enhancement,
          'Score': score,
      } -%>
<%- end -%>
<%# Decomment the following line only if Foreman Jail support sort_by method for Array -%>
<%# report_entries = report_entries.sort_by { |k| k['Score'] }.reverse  -%>
<%- report_entries.each do |entry| -%>
<%-     report_row(
          entry
        ) -%>
<%- end -%>
<%= report_render -%>
{% endhighlight %}

Two input variable named "Hosts filter" and "Errata filter" must be added to this report from Satellite Web UI in order to correct receive the input from the users.
