# Source Code Compilation Guide #

---

## Create Projects in Flash Builder ##

**1.** Install Flash Builder 4.1 or above.

**2.** In Flash Builder, follow steps below to create 3 new Flex projects with the names

> `"MosesScoringHarnessTool"`

> `"MosesTrainingHarnessTool"`

> `"TMXtoMosesCorpusTool"`

**a** Select File -> New -> Flex Poject.

**b** In New Flex Project dialog, input project name in Project name field.

**c** Select Desktop (runs in Adobe AIR) in Application type.

**d** Select Flex 4.1 in Flex SDK version.

**e** Click Finish.

**3** Copy the source files of each project ` (<ProjectName>/src) ` to the same folder in Flash Builder.

## Compile ##

**1** In Flash Builder, select Project -> Export Release Build.

**2** In Export Release Build dialog, select Export to native installer in Export field. Then click Next.

**3** In Digital Signature step, select Export and sign an AIR application with a digital certificate. Then select your own certificate. If you don't have yet, click Create button to create one.Then click Finish.

## Readme ##

---

Moses tooling set includes 3 standalone tools:

  * TMX to Moses Corpus Tool - a GUI based tool to convert WorldServer sourced .tmx files to Moses ready corpus files.

  * Moses Training Harness Tool - a GUI based tool to integrate running, configuration, and options settings for executing a Moses MT engine training run.

  * Moses Scoring Harness Tool - a GUI based tool for to make easier and eventually automate the translation quality being produced by MT Engines.


## Minimum system requirements ##

**Moses tooling set**

**Hardware**

  * N/A

**Software**

  * OS  - Mac OS X 10.6.x (Lion) or higher

  * AIR Runtime - latest version. Please download from http://get.adobe.com/air/.

**Moses Server**

**Hardware**

  * RAM - 8G or more

**Software**

  * OS - CentOS 6.0

## Install your software ##
TMX to Moses Corpus Tool and Moses Scoring Harness Tool are standalone software and can be installed on your local desktop.

Moses Training Harness Tool works as a client to trigger training/tuning process on your Moses server.

After installing latest AIR runtime on your desktop, you can install 3 tools by simply double-clicking their installers.

## How to set up your Moses server ##

**Installation of Moses Suites**

Please follow the instructions below to install the Moses RPM packages.

  1. Install the boost and xmlrpc-c packages through YUM.
  1. Install Moses series RPM packages in the order listed below.
  * gizapp
  * srilm
  * irstlm
  * moses
  1. Copy the training script adobe-moses-train.sh to /tools/bin.
  1. Add /tools/bin to your $PATH by editing your .bash\_profile.

**Set up Web Server on Moses Server machine**

**Installation of XAMPP**

XAMPP is an easy to install Apache distribution containing MySQL, PHP and Perl. Please follow the steps at http://www.apachefriends.org/en/xampp-linux.htmlto install the latest version of XAMPP. Currently XAMPP is only available as 32 bit application. Please follow the steps below to make it compatible with 64-bit CentOS after your installation is done.

  1. Comment the following lines in `/opt/lampp/lampp.`

```
# XAMPP is currently 32 bit only
case `uname -m` in
*_64)
if /opt/lampp/bin/php -v > /dev/null 2>&1
then
:
else
$de && echo “XAMPP gibt es zur Zeit nur als 32-Bit Applikation. Bitte verwende eine 32-Bit
Kompatibilitaetsbibliothek fuer Dein System.”
$de || echo “XAMPP is currently only availably as 32 bit application. Please use a 32 bit compatibility
library for your system.”
exit
fi
;;
esac
```

  1. Install all missing 32 bit libraries.

```
#yum install glibc-*.i686
#yum install libstdc++.i686
```

**Customization of XAMPP**

  1. Modify /opt/lampp/etc/httpd.conf
  * Add corpus folder (/data/corpus) to the Apache web document root, which is by default /opt/lampp/htdocs in XMAPP, by adding following lines.

```
Alias /moses/data /data
<Directory "/data">
    Options Indexes FollowSymLinks ExecCGI Includes
    AllowOverride All
    Order allow,deny
    Allow from all
</Directory>
```
Change file uploading limit by adding following lines.

```
LimitRequestBody 536870912
```

  1. Modify /opt/lampp/etc/php.ini
  * Change file uploading limit by editing following lines.
```
upload_max_filesize = 256M
post_max_size = 512M
memory_limit = 512M
```
  1. Modify permission of /data/corpus
```
#chmod 777 /data/corpus
```

**Copy server php scripts**

Copy MosesTrainingHarnessTool/moses folder in source code to /opt/lampp/htdocs/ on the server machine.

**File structure on Moses server**

After installing Moses RPM packages, you can find the executable and scripts of GIZAPP, language models and Moses, and the training script under /tools. Besides, All corpus files should be stored in /data/corpus with correct directory hierarchy. Below is an example.

```
# /data
# ├── corpus                            all corpus files for different language pairs.
# └── ZH-EN                             all models for translating Chinese to English under this directory.

# corpus/                               
# ├── EN-FR -> FR-EN                    Symbolic link, same corpus files for bi-direction.
# └── FR-EN
#     ├── evaluation
#     │   ├── flash-test.en             corpus files from real world for evaluation.
#     │   └── flash-test.fr
#     ├── training
#     │   ├── flash.en                  lowercased and long sentence cleaned corpus files for training.
#     │   ├── flash.fr
#     │   ├── flash.lm.en               lowercased but keeping the long sentence corpus files for building lm.
#     │   ├── flash.lm.fr
#     │   ├── flash.orig.en             Normal sentence for training recaser.
#     │   └── flash.orig.fr
#     └── tuning
#         ├── flash-doc.en              selected corpus files for tuning.
#         └── flash-doc.fr

# ZH-EN/
# ├── LeoJiang-Test                                             create a new directory named as ID specified by user for every new training model.
# │   ├── adobe-moses-train-20110729-0337.cfg                   cfg and log with time stamp, there will be several time stamp log if you run tuning step
# │   ├── adobe-moses-train-20110729-0337.log                   several times.
# │   ├── build_lm.log
# │   ├── latest.cfg -> adobe-moses-train-20110729-0337.cfg     cfg and log of latest run.
# │   ├── latest.log -> adobe-moses-train-20110729-0337.log     
# │   ├── training.log
# │   └── work                                                  working directory
# └── latest -> LeoJiang-Test                                   latest is a symbolic link to directory of latest run.
```

In the example, /ZH-EN is automatically created by the training script when training a ZH-EN engine. /Latest is a sym link to the latest trained engine directory, which is named as the engine ID specified by the user in Moses Training Harness Tool.  All files of this engine are stored under /<engine ID>/work.

**Known issues**
N/A