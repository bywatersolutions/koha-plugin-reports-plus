# Introduction

This plugin allows the use of lists inputs for reports. It is useful whenyou wish to run a report on a set of barcodes, biblionumbers, itemnumbers, etc.

# Downloading

From the [release page](https://github.com/bywatersolutions/koha-reports-plus/releases) you can download the relevant *.kpz file

# Installing

Koha's Plugin System allows for you to add additional tools and reports to Koha that are specific to your library. Plugins are installed by uploading KPZ ( Koha Plugin Zip ) packages. A KPZ file is just a zip file containing the perl files, template files, and any other files necessary to make the plugin work.

The plugin system needs to be turned on by a system administrator.

To set up the Koha plugin system you must first make some changes to your install.

* Change `<enable_plugins>0<enable_plugins>` to `<enable_plugins>1</enable_plugins>` in your koha-conf.xml file
* Confirm that the path to `<pluginsdir>` exists, is correct, and is writable by the web server
* Restart your webserver

Once set up is complete you will need to alter your UseKohaPlugins system preference.

# Using

* Create a report in the Koha reports module.
  * To utilise the list functionality syntax should in:
VALUE in (<<List parameter>>)
  * The plugin will add the necessary commas between list entries

* Run the plugin.
* Enter the report number for the you created above.
* The plugin scans the report for parameters and asks you for the type of each, you can choose:
  * List
  * Date
  * Text
* The next step will ask you for values
  * All parameters must be filled
  * You may choose results in CSV or HTML
* Voila!

