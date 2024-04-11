---
title: "speciesAbundTempLM Manual"
subtitle: "v.1.0.0"
date: "Last updated: 2024-04-11"
output:
  bookdown::html_document2:
    toc: true
    toc_float: true
    theme: sandstone
    number_sections: false
    df_print: paged
    keep_md: yes
editor_options:
  chunk_output_type: console
  bibliography: citations/references_speciesAbundTempLM.bib
link-citations: true
always_allow_html: true
---

# speciesAbundTempLM Module

<!-- the following are text references used in captions for LaTeX compatibility -->
(ref:speciesAbundTempLM) *speciesAbundTempLM*



[![made-with-Markdown](figures/markdownBadge.png)](https://commonmark.org)

<!-- if knitting to pdf remember to add the pandoc_args: ["--extract-media", "."] option to yml in order to get the badge images -->

#### Authors:

Tati Micheletti <tati.micheletti@gmail.com> [aut, cre]
<!-- ideally separate authors with new lines, '\n' not working -->

## Module Overview

### Module summary

The species abundance temperature Linear Model aims at fitting a linear model to abundance and temperature,
and plotting abundance forecasts, as well as the difference between abundance in the last year of forecasts and 
first year of abundance data.

### Module inputs and parameters

The module requires only two rasters, one with abundance, and one with temperature data.

Table \@ref(tab:moduleInputs-speciesAbundTempLM) shows the full list of module inputs.

<table class="table" style="color: black; margin-left: auto; margin-right: auto;">
<caption>(\#tab:moduleInputs-speciesAbundTempLM)(\#tab:moduleInputs-speciesAbundTempLM)List of (ref:speciesAbundTempLM) input objects and their description.</caption>
 <thead>
  <tr>
   <th style="text-align:left;"> objectName </th>
   <th style="text-align:left;"> objectClass </th>
   <th style="text-align:left;"> desc </th>
   <th style="text-align:left;"> sourceURL </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> abundaRas </td>
   <td style="text-align:left;"> SpatRaster </td>
   <td style="text-align:left;"> A raster object of spatially explicit abundance data for a given year </td>
   <td style="text-align:left;"> NA </td>
  </tr>
  <tr>
   <td style="text-align:left;"> tempRas </td>
   <td style="text-align:left;"> SpatRaster </td>
   <td style="text-align:left;"> A raster object of spatially explicit temperature data for a given year </td>
   <td style="text-align:left;"> NA </td>
  </tr>
</tbody>
</table>

Here is a summary of parameters (Table \@ref(tab:moduleParams-speciesAbundTempLM))

<table class="table" style="color: black; margin-left: auto; margin-right: auto;">
<caption>(\#tab:moduleParams-speciesAbundTempLM)(\#tab:moduleParams-speciesAbundTempLM)List of (ref:speciesAbundTempLM) parameters and their description.</caption>
 <thead>
  <tr>
   <th style="text-align:left;"> paramName </th>
   <th style="text-align:left;"> paramClass </th>
   <th style="text-align:left;"> default </th>
   <th style="text-align:left;"> min </th>
   <th style="text-align:left;"> max </th>
   <th style="text-align:left;"> paramDesc </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> .plotInitialTime </td>
   <td style="text-align:left;"> numeric </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> Describes the simulation time at which the first plot event should occur. </td>
  </tr>
  <tr>
   <td style="text-align:left;"> .plotInterval </td>
   <td style="text-align:left;"> numeric </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> Describes the simulation time interval between plot events. </td>
  </tr>
</tbody>
</table>

### Events

The module starts in the first year by checking if data for abundance is available. The first year of which abundance data is not available, the module uses the data from both previous modules up to that point (i.e., 2022), and fits a linear model to it. Then the module performs forecasts for each year abundance data is not available (i.e., after 2022) and plots the results. This is done every year until the last one (2032), when the module calculates the differences between the last year’s forecasts and the first year of abundance data, and plots it.

### Module outputs

Description of the module outputs (Table \@ref(tab:moduleOutputs-speciesAbundTempLM)).

<table class="table" style="color: black; margin-left: auto; margin-right: auto;">
<caption>(\#tab:moduleOutputs-speciesAbundTempLM)(\#tab:moduleOutputs-speciesAbundTempLM)List of (ref:speciesAbundTempLM) outputs and their description.</caption>
 <thead>
  <tr>
   <th style="text-align:left;"> objectName </th>
   <th style="text-align:left;"> objectClass </th>
   <th style="text-align:left;"> desc </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> modDT </td>
   <td style="text-align:left;"> data.table </td>
   <td style="text-align:left;"> Dataset in the form of a data.table with abundance and temperature </td>
  </tr>
  <tr>
   <td style="text-align:left;"> abundTempLM </td>
   <td style="text-align:left;"> lm </td>
   <td style="text-align:left;"> A fitted model (of the `lm` class) of abundance as a function of temperature. </td>
  </tr>
  <tr>
   <td style="text-align:left;"> forecasts </td>
   <td style="text-align:left;"> SpatRaster </td>
   <td style="text-align:left;"> This raster shows the forecasts of abundance for each year of the simulation after abundance data is no longer available </td>
  </tr>
  <tr>
   <td style="text-align:left;"> forecastedDifferences </td>
   <td style="text-align:left;"> SpatRaster </td>
   <td style="text-align:left;"> This raster shows the differences between the first yearof abundance data and the last abundance forecast </td>
  </tr>
</tbody>
</table>

### Links to other modules

This module is stand-alone, but has been created to be ran with the module `speciesAbundance` 
and `temperature` as a way of demonstrating `SpaDES`.

### Getting help

Detailed module creation and functioning can be found at `https://html-preview.github.io/?url=https://github.com/tati-micheletti/EFI_webinar/blob/main/HandsOn.html`

- Please use GitHub issues (https://github.com/tati-micheletti/speciesAbundTempLM/issues/new) 
if you encounter any problems in using this module.
